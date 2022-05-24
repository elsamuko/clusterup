import 'dart:convert';
import 'dart:core';
import 'package:clusterup/cluster_child.dart';
import 'package:clusterup/ssh_connection.dart';
import 'package:clusterup/ssh_key.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'remote_action.dart';
import 'remote_action_runner.dart';

typedef OnActionCallback = void Function(RemoteActionPair action);

class Cluster {
  // persisted
  int id;
  String name;
  String user;
  String host;
  int port;
  List<ClusterChild> children;
  Set<RemoteAction> actions;
  bool enabled;

  // runtime only
  bool running = false;
  bool up = false; // true, if valid and reachable
  List<RemoteActionPair> results = [];
  RemoteActionStatus lastStatus = RemoteActionStatus.Unknown;
  OnActionCallback onActionStarted;
  OnActionCallback onActionFinished;
  Function onRunningFinished;
  Function persist;

  Cluster(
      {@required this.id,
      this.name = "",
      this.user = "",
      this.host = "",
      this.port = 22,
      this.enabled = true,
      this.actions,
      this.children}) {
    actions ??= Set<RemoteAction>();
    children ??= [];
    onActionStarted = (RemoteActionPair action) {};
    onActionFinished = (RemoteActionPair action) {};
    onRunningFinished = () {};
    persist = () {};
  }

  RemoteAction lastAction() {
    if (results.isEmpty) return RemoteAction.none();
    return results.last.action;
  }

  void addChild({String user, String host, int port}) {
    children.add(ClusterChild(this, user: user, host: host, port: port));
  }

  @override
  bool operator ==(dynamic other) {
    if (this.id != other.id) return false;
    if (this.name != other.name) return false;
    if (this.user != other.user) return false;
    if (this.host != other.host) return false;
    if (this.port != other.port) return false;
    if (!listEquals(this.children, other.children)) return false;
    if (!setEquals(this.actions, other.actions)) return false;
    return true;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      user.hashCode ^
      host.hashCode ^
      port.hashCode ^
      children.hashCode ^
      actions.hashCode;

  String toString() {
    return "$id : $name";
  }

  String userHostPort() {
    return "$user@$host:$port";
  }

  SSHCredentials creds() {
    return SSHCredentials(user, host, port);
  }

  Map<String, dynamic> toMap() {
    List<String> actionNames = [];

    actions.forEach((RemoteAction action) {
      actionNames.add(action.name);
    });

    String json = jsonEncode(actionNames);

    return {
      'id': id,
      'name': name,
      'user': user,
      'host': host,
      'port': port,
      'enabled': enabled ? 1 : 0,
      'actions': json,
    };
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> m = toMap();
    m["actions"] = actions.toList();
    m["children"] = children;
    return m;
  }

  // blob is real json or encoded json
  static Set<RemoteAction> actionsFromBlob(blob) {
    Set<RemoteAction> actions = Set<RemoteAction>();
    if (blob != null) {
      // if its json, decode first
      if (blob.runtimeType == "".runtimeType) {
        List<String> names = jsonDecode(blob).cast<String>();
        actions = RemoteAction.getActionsFor(names);
      } else {
        blob.cast<String>().forEach((String name) {
          RemoteAction action = RemoteAction.getActionFor(name);
          if (action != null) {
            actions.add(action);
          }
        });
      }
    }
    return actions;
  }

  static List<ClusterChild> childrenFromData(Cluster parent, List<dynamic> data) {
    List<ClusterChild> children = [];
    if (data != null) {
      data.forEach((dynamic one) {
        ClusterChild child = ClusterChild.fromMap(parent, one);
        if (child != null) {
          children.add(child);
        }
      });
    }
    return children;
  }

  static Cluster fromMap(Map<String, dynamic> data) {
    Cluster cluster = Cluster(
      id: data['id'] ?? 0,
      name: data['name'] ?? "",
      user: data['user'] ?? "",
      host: data['host'] ?? "",
      port: data['port'] ?? 22,
      enabled: (data['enabled'] ?? 1) == 1,
      actions: actionsFromBlob(data['actions']),
    );

    cluster.children = childrenFromData(cluster, data['children']);

    return cluster;
  }

  bool lastWasSuccess() {
    return lastStatus == RemoteActionStatus.Success;
  }

  bool hasEnabledChildren() {
    return children.any((ClusterChild child) => child.enabled);
  }

  Future<void> run(SSHKey key) async {
    running = true;
    lastStatus = RemoteActionStatus.Unknown;

    if (hasEnabledChildren()) {
      await _runChildren(key);
    } else {
      await _runSolo(key);
    }

    onRunningFinished();
    running = false;
  }

  Future<void> _runSolo(SSHKey key) async {
    // check if host is up
    results = [RemoteActionPair(RemoteAction.getHostUpAction())];
    this.onActionStarted(results.first);

    RemoteActionRunner runner = RemoteActionRunner(this.creds(), results.first.action, key);
    results.first.results.add(await runner.run());
    up = results.first.results.first.success();
    lastStatus = results.first.results.first.status;

    this.onActionFinished(results.first);

    // run actions
    if (up) {
      for (RemoteAction action in actions) {
        results.add(RemoteActionPair(action));
        this.onActionStarted(results.last);

        RemoteActionRunner runner = RemoteActionRunner(this.creds(), action, key);
        results.last.results.add(await runner.run());

        this.onActionFinished(results.last);

        if (results.last.results.first.status.index > lastStatus.index) {
          lastStatus = results.last.results.first.status;
        }
      }
    }
  }

  Future<void> _runChildren(SSHKey key) async {
    // check if host is up
    results = [RemoteActionPair(RemoteAction.getHostUpAction())];
    this.onActionStarted(results.first);

    for (ClusterChild child in children) {
      if (child.enabled) {
        RemoteActionRunner runner = RemoteActionRunner(child.creds(), results.first.action, key);
        results.first.results.add(await runner.run());
        child.up = results.first.results.last.success();
        if (results.first.results.last.status.index > lastStatus.index) {
          lastStatus = results.first.results.last.status;
        }
      }
    }

    this.onActionFinished(results.first);

    // run actions
    for (RemoteAction action in actions) {
      results.add(RemoteActionPair(action));
      this.onActionStarted(results.last);

      for (ClusterChild child in children) {
        if (child.enabled && child.up) {
          RemoteActionRunner runner = RemoteActionRunner(child.creds(), action, key);
          results.last.results.add(await runner.run());
        }
      }

      this.onActionFinished(results.last);

      for (RemoteActionResult result in results.last.results) {
        if (result.status.index > lastStatus.index) {
          lastStatus = result.status;
        }
      }
    }
  }

  Color statusColor() {
    switch (lastStatus) {
      case RemoteActionStatus.Unknown:
        return Colors.white;
      case RemoteActionStatus.Success:
        return Colors.green[300];
      case RemoteActionStatus.Warning:
        return Colors.orange[300];
      case RemoteActionStatus.Error:
        return Colors.red[300];
    }
    return Colors.white;
  }
}

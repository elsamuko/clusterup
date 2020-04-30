import 'dart:convert';
import 'dart:core';
import 'package:clusterup/ssh_key.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'remote_action.dart';
import 'remote_action_runner.dart';

typedef OnActionCallback = void Function(RemoteAction action);

class Cluster {
  int id;
  String name = "";
  String user = "";
  String host = "";
  int port = 22;
  bool running = false;
  RemoteActionStatus lastStatus = RemoteActionStatus.Unknown;
  Color lastStatusAsColor = Colors.white;
  Set<RemoteAction> actions;
  OnActionCallback onActionStarted;
  OnActionCallback onActionFinished;

  Cluster({this.id, this.name, this.user, this.host, this.port, this.actions}) {
    actions ??= Set<RemoteAction>();
    onActionStarted = (RemoteAction action) {};
    onActionFinished = (RemoteAction action) {};
  }

  @override
  bool operator ==(dynamic other) {
    if (this.id != other.id) return false;
    if (this.name != other.name) return false;
    if (this.user != other.user) return false;
    if (this.host != other.host) return false;
    if (!setEquals(this.actions, other.actions)) return false;
    return true;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ user.hashCode ^ host.hashCode ^ actions.hashCode;

  String toString() {
    return "$id : $name";
  }

  String userHostPort() {
    return "$user@$host:$port";
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
      'actions': json,
    };
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> m = toMap();
    m["actions"] = actions.toList();
    return m;
  }

  static Cluster fromMap(Map<String, dynamic> data) {
    Set<RemoteAction> actions = Set<RemoteAction>();

    var blob = data['actions'];

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

    return Cluster(
      id: data['id'] ?? 0,
      name: data['name'] ?? "",
      user: data['user'] ?? "",
      host: data['host'] ?? "",
      port: data['port'] ?? 22,
      actions: actions,
    );
  }

  bool lastWasSuccess() {
    return lastStatus == RemoteActionStatus.Success;
  }

  Future<void> run(SSHKey key) async {
    lastStatus = RemoteActionStatus.Unknown;
    for (RemoteAction action in actions) {
      this.onActionStarted(action);

      RemoteActionRunner runner = RemoteActionRunner(this, action, key);
      RemoteActionRunnerResult result = await runner.run();

      this.onActionFinished(action);

      if (result.remoteActionStatus.index > lastStatus.index) {
        lastStatus = result.remoteActionStatus;
      }
    }

    switch (lastStatus) {
      case RemoteActionStatus.Unknown:
        lastStatusAsColor = Colors.white;
        break;
      case RemoteActionStatus.Success:
        lastStatusAsColor = Colors.green[300];
        break;
      case RemoteActionStatus.Warning:
        lastStatusAsColor = Colors.orange[300];
        break;
      case RemoteActionStatus.Error:
        lastStatusAsColor = Colors.red[300];
        break;
    }
  }
}

import 'dart:convert';
import 'dart:core';
import 'package:clusterup/ssh_key.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'remote_action.dart';
import 'remote_action_runner.dart';

class Cluster {
  int id;
  String name = "";
  String user = "";
  String host = "";
  int port = 22;
  bool running = false;
  RemoteActionStatus lastStatus = RemoteActionStatus.Unknown;
  Color lastStatusAsColor = Colors.white;
  Set<RemoteAction> actions = Set<RemoteAction>();

  Cluster({this.id, this.name, this.user, this.host, this.port, String actionsJson}) {
    if (actionsJson != null) {
      List<String> actionNames = jsonDecode(actionsJson).cast<String>();

      actionNames.forEach((String name) {
        actions.add(RemoteAction.getActionFor(name));
      });
    }
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

  bool lastWasSuccess() {
    return lastStatus == RemoteActionStatus.Success;
  }

  Future<void> run(SSHKey key) async {
    lastStatus = RemoteActionStatus.Unknown;
    for (RemoteAction action in actions) {
      RemoteActionRunner runner = RemoteActionRunner(this, action, key);
      RemoteActionRunnerResult result = await runner.run();
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

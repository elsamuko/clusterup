import 'dart:convert';
import 'dart:core';
import 'package:clusterup/ssh_key.dart';
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
  Set<RemoteAction> actions = Set<RemoteAction>();
  Color lastStatusAsColor = Colors.white;

  Cluster(
      {this.id,
      this.name,
      this.user,
      this.host,
      this.port,
      String actionsJson}) {
    if (actionsJson != null) {
      List<String> actionNames = jsonDecode(actionsJson).cast<String>();

      actionNames.forEach((String name) {
        actions.add(RemoteAction.getActionFor(name));
      });
    }
  }

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

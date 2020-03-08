import 'dart:convert';
import 'dart:core';
import 'remote_action.dart';

class Cluster {
  int id;
  String name = "";
  String user = "";
  String host = "";
  int port = 22;
  Set<RemoteAction> actions = Set<RemoteAction>();

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
}

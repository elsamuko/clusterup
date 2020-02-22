import 'dart:core';

class Cluster {
  int id;
  String name = "";
  String user = "";
  String host = "";
  int port = 22;

  Cluster(this.id, [this.name, this.user, this.host, this.port]);

  String toString() {
    return "$id : $name";
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'user': user,
      'host': host,
      'port': port,
    };
  }
}

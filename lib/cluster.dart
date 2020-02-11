import 'dart:core';

class Cluster {
  String name = "";
  String user = "";
  String host = "";
  int port = 22;

  Cluster(this.name);

  String toString() {
    return "${name} : ${user}@${host}:${port}";
  }

  static List<Cluster> generateClusters() {
    //! \todo read from save
    return [Cluster("Raspberry"), Cluster("Raspberry2")];
  }
}

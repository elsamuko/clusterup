import 'dart:core';

class Cluster {
  String name;
  String user;
  String domain;
  int port;

  Cluster(this.name);

  String toString() {
    return name;
  }

  static List<Cluster> generateClusters() {
    //! \todo read from save
    return [Cluster("Raspberry"), Cluster("Raspberry2")];
  }
}

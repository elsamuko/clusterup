import 'dart:convert';

import 'package:clusterup/remote_action.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clusterup/cluster.dart';

void main() {
  test('IO', () {
    Cluster cluster = Cluster(
      id: 0,
      name: "name",
      user: "user",
      host: "host",
      port: 22,
      actions: Set.of([RemoteAction.getActionFor("df")!]),
    );

    // parse toMap back to cluster
    Map<String, dynamic> m = cluster.toMap();
    Cluster cluster2 = Cluster.fromMap(m);
    expect(cluster, cluster2);

    // parse toJSON back to cluster
    String json = jsonEncode(cluster);
    Map<String, dynamic> m2 = jsonDecode(json);
    Cluster cluster3 = Cluster.fromMap(m2);
    expect(cluster, cluster3);
  });
}

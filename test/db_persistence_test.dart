import 'package:clusterup/cluster.dart';
import 'package:clusterup/cluster_child.dart';
import 'package:clusterup/db_persistence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  databaseFactory = databaseFactoryFfi;

  test('DBPersistence', () async {
    await DBPersistence.deleteDB();

    var db = await DBPersistence.create();

    List<Cluster> read = await db.readClusters();
    expect(read.isEmpty, true);

    Cluster input = Cluster(id: 1);
    input.children.add(ClusterChild(input, user: "user2"));
    db.addCluster(input);

    read = await db.readClusters();

    expect(read.last.id, 1);
    expect(read.last.children.last.user, "user2");
    expect(read.last.children.length, 1);
    expect(read.last, input);
    expect(read.last.children.first, input.children.first);
  });
}

import 'package:clusterup/cluster.dart';
import 'package:clusterup/cluster_child.dart';
import 'package:clusterup/db_persistence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// dart run build_runner build
@GenerateNiceMocks([MockSpec<Cluster>(), MockSpec<ClusterChild>()])
import 'db_upgrade_test.mocks.dart';

void main() {
  databaseFactory = databaseFactoryFfi;

  test('DBPersistence', () async {
    await DBPersistence.deleteDB();

    var db = await DBPersistence.create(1);

    List<Cluster> read = await db.readClusters();
    expect(read.isEmpty, true);

    // v1 cluster and child
    MockCluster input = MockCluster();
    when(input.toMap()).thenReturn({
      'id': 1,
      'name': "",
      'user': "user",
      'host': "",
      'port': 22,
      'enabled': 1,
      'actions': "[]",
    });
    MockClusterChild child = MockClusterChild();
    when(child.toMap()).thenReturn({
      'parent': 1,
      'id': 0,
      'user': "user2",
      'host': "",
      'port': 22,
      'enabled': 1,
    });

    when(input.children).thenReturn([child]);
    db.addCluster(input);

    read = await db.readClusters();

    expect(read.last.id, 1);
    expect(read.last.user, "user");
    expect(read.last.children.last.user, "user2");
    expect(read.last.children.length, 1);

    var db2 = await DBPersistence.create(2);
    read = await db2.readClusters();

    expect(read.last.id, 1);
    expect(read.last.user, "user");
    expect(read.last.children.last.user, "user2");
    expect(read.last.children.length, 1);
  });
}

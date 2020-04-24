import 'package:clusterup/cluster.dart';
import 'package:clusterup/db_persistence.dart';
import 'package:flutter_test/flutter_test.dart';

// must be run on device for method getDatabasesPath
// MissingPluginException: https://github.com/tekartik/sqflite/issues/49
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('DBPersistence', () async {
    var db = DBPersistence();
    Cluster input = Cluster(id: 1);
    db.addCluster(input);

    List<Cluster> read = await db.readClusters();

    expect(read.last.id, 1);
  });
}

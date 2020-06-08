import 'package:clusterup/cluster.dart';
import 'package:clusterup/db_persistence.dart';
import 'package:clusterup/remote_action.dart';
import 'package:clusterup/remote_action_runner.dart';
import 'package:clusterup/ssh_key.dart';
import 'package:flutter_test/flutter_test.dart';

// must be run on device for method getDatabasesPath
// MissingPluginException: https://github.com/tekartik/sqflite/issues/49
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('RunCommands', () async {
    var db = DBPersistence();
    List<Cluster> read = await db.readClusters();
    SSHKey key = await db.getSSHKey();
    Cluster cluster = read.first;
    RemoteAction action = RemoteAction.getDiskFreeAction();

    RemoteActionRunner runner = RemoteActionRunner(cluster.creds(), action, key);
    RemoteActionRunnerResult result = await runner.run();

    expect(result.remoteActionStatus, RemoteActionStatus.Success);
  });
}

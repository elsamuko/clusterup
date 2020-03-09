import 'package:clusterup/cluster.dart';
import 'package:clusterup/remote_action.dart';
import 'package:clusterup/ssh_connection.dart';
import 'package:clusterup/ssh_key.dart';

class RemoteActionRunnerResult {
  RemoteActionStatus remoteActionStatus;
  SSHConnectionResult _sshConnectionResult;
}

class RemoteActionRunner {
  Cluster _cluster;
  RemoteAction _action;
  SSHKey _sshKey;

  RemoteActionRunner(this._cluster, this._action, this._sshKey);

  Future<RemoteActionRunnerResult> run() async {
    RemoteActionRunnerResult result = RemoteActionRunnerResult();
    result._sshConnectionResult = await SSHConnection.run(_cluster, _sshKey, _action.commands);
    result.remoteActionStatus = _action.filter(result._sshConnectionResult.output.join("\n"));
    return result;
  }
}

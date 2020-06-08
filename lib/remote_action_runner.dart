import 'package:clusterup/cluster.dart';
import 'package:clusterup/cluster_child.dart';
import 'package:clusterup/remote_action.dart';
import 'package:clusterup/ssh_connection.dart';
import 'package:clusterup/ssh_key.dart';

class RemoteActionRunnerResult {
  RemoteActionStatus remoteActionStatus;
  SSHConnectionResult _sshConnectionResult;
}

class RemoteActionRunner {
  SSHCredentials _creds;
  RemoteAction _action;
  SSHKey _sshKey;

  RemoteActionRunner(this._creds, this._action, this._sshKey);

  Future<RemoteActionRunnerResult> run() async {
    RemoteActionRunnerResult result = RemoteActionRunnerResult();
    result._sshConnectionResult = await SSHConnection.run(_creds, _sshKey, _action.commands);
    if (result._sshConnectionResult.success) {
      result.remoteActionStatus = _action.filter(result._sshConnectionResult.output);
    }
    return result;
  }
}

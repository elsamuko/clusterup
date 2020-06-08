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
  Cluster _cluster;
  RemoteAction _action;
  SSHKey _sshKey;

  RemoteActionRunner(this._cluster, this._action, this._sshKey);

  Future<RemoteActionRunnerResult> run() async {
    RemoteActionRunnerResult result = RemoteActionRunnerResult();
    result._sshConnectionResult = await SSHConnection.run(_cluster.creds(), _sshKey, _action.commands);
    if (result._sshConnectionResult.success) {
      result.remoteActionStatus = _action.filter(result._sshConnectionResult.output);
    }
    return result;
  }

  Future<List<RemoteActionRunnerResult>> runChildren() async {
    List<RemoteActionRunnerResult> results = [];

    for (ClusterChild child in _cluster.children) {
      RemoteActionRunnerResult result = RemoteActionRunnerResult();
      result._sshConnectionResult = await SSHConnection.run(child.creds(), _sshKey, _action.commands);
      if (result._sshConnectionResult.success) {
        result.remoteActionStatus = _action.filter(result._sshConnectionResult.output);
      }
      results.add(result);
    }

    return results;
  }
}

import 'package:clusterup/remote_action.dart';
import 'package:clusterup/ssh_connection.dart';
import 'package:clusterup/ssh_key.dart';

class RemoteActionRunner {
  final SSHCredentials _creds;
  final RemoteAction _action;
  final SSHKey _sshKey;

  RemoteActionRunner(this._creds, this._action, this._sshKey);

  Future<RemoteActionResult> run() async {
    RemoteActionResult result;
    SSHConnectionResult sshConnectionResult = await SSHConnection.run(_creds, _sshKey, _action.commands);
    if (sshConnectionResult.success) {
      result = _action.filter(sshConnectionResult.output);
    } else {
      result = RemoteActionResult.error(sshConnectionResult.error);
    }
    return result;
  }
}

import 'package:clusterup/remote_action.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('test action df', () {
    RemoteAction action = RemoteAction.getDiskFreeAction();
    RemoteActionStatus status = action.filter(
        """Filesystem      1K-blocks      Used  Available Use% Mounted on
/dev/sdd2      1906477340 300465836 1509144976  17% /""");

    expect(status, RemoteActionStatus.Success);
  });

  test('test action uptime', () {
    RemoteAction action = RemoteAction.getUptimeAction();
    RemoteActionStatus status = action.filter("""2020-03-09 17:32:20""");
    expect(status, RemoteActionStatus.Success);
  });
}

import 'package:clusterup/remote_action.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('test action df', () {
    RemoteAction action = RemoteAction.getDiskFreeAction();
    ActionStatus status = action.filter(
        """Filesystem      1K-blocks      Used  Available Use% Mounted on
/dev/sdd2      1906477340 300465836 1509144976  17% /""");

    expect(status, ActionStatus.Success);
  });
}

import 'package:clusterup/remote_action.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('test action df', () {
    RemoteAction action = RemoteAction.getDiskFreeAction();
    RemoteActionResult result =
        action.filter(["Filesystem      1K-blocks      Used  Available Use% Mounted on", "/dev/sdd2      1906477340 300465836 1509144976  17% /"]);

    expect(result.status, RemoteActionStatus.Success);
  });

  test('test action uptime', () {
    RemoteAction action = RemoteAction.getUptimeAction();
    RemoteActionResult result = action.filter(["2020-03-09 17:32:20"]);
    expect(result.status, RemoteActionStatus.Success);
  });

  test('test action updates', () {
    RemoteAction action = RemoteAction.getAptUpdatesAvailableAction();
    RemoteActionResult result = action.filter([
      "Listing... Done",
      "binutils-arm-linux-gnueabihf/stable 2.31.1-16+rpi2 armhf [upgradable from: 2.31.1-16+rpi1]",
      "binutils-common/stable 2.31.1-16+rpi2 armhf [upgradable from: 2.31.1-16+rpi1]",
      "binutils/stable 2.31.1-16+rpi2 armhf [upgradable from: 2.31.1-16+rpi1]",
      "libbinutils/stable 2.31.1-16+rpi2 armhf [upgradable from: 2.31.1-16+rpi1]",
    ]);

    expect(result.status, RemoteActionStatus.Warning);

    RemoteActionResult result2 = action.filter([
      "Listing... Done",
      "libopenexr-dev/focal-updates,focal-security 2.3.0-6ubuntu0.1 amd64 [upgradable from: 2.3.0-6build1]",
      "libopenexr24/focal-updates,focal-security 2.3.0-6ubuntu0.1 amd64 [upgradable from: 2.3.0-6build1]"
    ]);

    expect(result2.status, RemoteActionStatus.Error);
  });

  test('test action lsb_release', () {
    RemoteAction action = RemoteAction.getLsbDescriptionAction();
    RemoteActionResult result = action.filter(["Description:	Raspbian GNU/Linux 10 (buster)"]);
    expect(result.status, RemoteActionStatus.Success);
  });

  test('test action uname', () {
    RemoteAction action = RemoteAction.getUnameAction();
    RemoteActionResult result = action.filter(["4.19.66-v7+"]);
    expect(result.status, RemoteActionStatus.Success);
  });
}

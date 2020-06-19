import 'package:clusterup/remote_action.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('test action df', () {
    RemoteAction action = RemoteAction.getDiskFreeAction();
    RemoteActionResult result = action.filter([
      "Filesystem      1K-blocks      Used  Available Use% Mounted on",
      "/dev/sdd2      1906477340 300465836 1509144976  17% /"
    ]);

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

  test('test action CPU load', () {
    // from a idle raspberry
    RemoteAction action = RemoteAction.getCPULoadAction();
    RemoteActionResult result = action.filter([
      "cpu  767507 9892 329507 1257115062 63614 0 4859 0 0 0",
      "procs_blocked 0",
      "softirq 200284061 8771478 69993392 652986 1139028 0 0 5258061 69446212 358 45022546",
      "cpu  767507 9892 329509 1257115466 63614 0 4859 0 0 0",
      "ctxt 163930158",
    ]);
    expect(result.status, RemoteActionStatus.Success);

    // sysbench --num-threads=3 --test=cpu --cpu-max-prime=20000 run
    result = action.filter([
      "cpu  769737 9892 329610 1257431317 63622 0 4862 0 0 0",
      "cpu0 222527 2144 81383 310606580 19261 0 4822 0 0 0",
      "procs_blocked 0",
      "softirq 200339971 8773527 70013401 653153 1139366 0 0 5259474 69464596 358 45036096",
      "cpu  770040 9892 329611 1257431416 63622 0 4862 0 0 0",
      "ctxt 163970668",
    ]);
    expect(result.status, RemoteActionStatus.Warning);
  });
}

import 'dart:io';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

takeScreenshot(FlutterDriver driver, String path) async {
  List<int> pixels = await driver.screenshot();
  File("screenshots/$path").writeAsBytesSync(pixels);
  print("Screenshot saved to screenshots/$path");
}

// https://medium.com/flutter-community/testing-flutter-ui-with-flutter-driver-c1583681e337
// https://flutter.dev/docs/cookbook/testing/integration/introduction
void main() {
  group('Cluster Up', () {
    FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
      await Directory("screenshots").create();
    });

    tearDownAll(() async {
      if (driver != null) {
        await driver.close();
      }
    });

    test('check driver health', () async {
      Health health = await driver.checkHealth();
      print(health.status);
    });

    test('screenshot add cluster', () async {
      // add cluster
      await driver.tap(find.byValueKey('addCluster'));

      // name it "Server"
      await driver.tap(find.byValueKey("name"));
      await driver.enterText("Server");
      await driver.tap(find.byValueKey("username"));
      await driver.enterText("user");
      await driver.tap(find.byValueKey("server"));
      await driver.enterText("server");
      await driver.tap(find.byValueKey("port"));
      await driver.enterText("22");

      // screenshot
      await takeScreenshot(driver, 'add_server.png');

      // save and return
      await driver.tap(find.byValueKey("saveCluster"));
    });

    test('screenshot edit cluster', () async {
      // go to cluster 'Server'
      await driver.tap(find.text('Server'));

      // add cluster child
      await driver.tap(find.byValueKey('addChild'));
      await driver.tap(find.byValueKey("server"));
      await driver.enterText("server2");
      await driver.tap(find.byValueKey("saveChild"));

      // add another cluster child
      await driver.tap(find.byValueKey('addChild'));
      await driver.tap(find.byValueKey("server"));
      await driver.enterText("server3");
      await driver.tap(find.byValueKey("saveChild"));

      // screenshot
      await takeScreenshot(driver, 'edit_server.png');

      // return
      await driver.tap(find.pageBack());
    });
  });
}

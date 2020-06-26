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

    test('load from json', () async {
      // load json configuration
      String json = File("/home/samuel/Downloads/clusterup.json").readAsStringSync();
      String boundary = "---------------------------337435678212716184261252619964";
      String multipart = """
--$boundary
Content-Disposition: form-data; name="jsonFile"; filename="clusterup.json"
Content-Type: application/json

$json
--$boundary--
"""
          .splitMapJoin("\n", onMatch: (m) => "\r\n");

      // go to load/save view
      await driver.tap(find.byValueKey('optionsMenu'));
      await driver.tap(find.text('Load/Save'));

      // start server
      await driver.tap(find.text('Start server'));

      // screenshot
      await takeScreenshot(driver, 'load_save.png');

      // upload json configuration
      // adb forward tcp:3001 tcp:3001
      HttpClientRequest request = await HttpClient().postUrl(Uri.parse("http://localhost:3001/upload"));
      request.headers.add("Content-Type", "multipart/form-data; boundary=$boundary");
      request.headers.add("Content-Length", multipart.length);
      request.write(multipart);
      /* HttpClientResponse response = */ await request.close();

      // return
      await driver.tap(find.text('Stop server'));
      await driver.tap(find.pageBack());
    });

    test('screenshot view ssh key', () async {
      // go to key
      await driver.tap(find.byValueKey('optionsMenu'));
      await driver.tap(find.text('View SSH Key'));

      // screenshot
      await takeScreenshot(driver, 'view_key.png');

      // return
      await driver.tap(find.byValueKey('back'));
    });

    test('screenshot run actions', () async {
      // go to cluster 'Server'
      await driver.tap(find.text('Raspi'));

      // run
      await driver.tap(find.byValueKey('run'));

      sleep(Duration(seconds: 10));

      // screenshot
      await takeScreenshot(driver, 'run.png');

      // return
      await driver.tap(find.byValueKey('back'));
      await driver.tap(find.pageBack());
    });
  }, timeout: Timeout(Duration(minutes: 5)));
}

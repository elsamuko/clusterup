import 'package:flutter_test/flutter_test.dart';
import 'package:clusterup/server.dart';
import 'dart:io';

void main() {
  test('Running server', () async {
    File f = await File("tmp/web/index.html").create(recursive: true);
    f.writeAsStringSync("OK");

    Server server = Server(3002);
    server.start('tmp/web');

    sleep(Duration(milliseconds: 1000));

    String result = await Http.GET('http://localhost:3002');
    expect(result, "OK");

    server.stop();
  });
}

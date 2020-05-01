import 'package:flutter_test/flutter_test.dart';
import 'package:clusterup/server.dart';
import 'dart:io';

void main() {
  test('Running server', () async {
    String where = "tmp_web";

    File f = await File("$where/index.html").create(recursive: true);
    f.writeAsStringSync("OK");

    Server server = Server(3002);
    server.start(where);

    sleep(Duration(milliseconds: 1000));

    String result = await Http.GET('http://localhost:3002');
    expect(result, "OK");

    await server.stop();

    // clean up
    Directory(where).delete(recursive: true);
  });
}

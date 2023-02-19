#!/usr/bin/env dart

import 'package:clusterup/server.dart';

int main() {
  Server server = Server(3003);
  server.onJsonOrKey = (json) {
    print("Got json");
    server.json = json;
  };
  print("http://localhost:3003");
  server.start('res/web');
  return 0;
}

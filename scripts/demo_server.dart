#!/usr/bin/env dart
import 'package:clusterup/server.dart';

int main() {
  Server server = Server(3003);
  server.start('res/web');
  return 0;
}

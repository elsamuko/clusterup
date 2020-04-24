#!/usr/bin/env dart
import 'package:clusterup/server.dart';
import 'dart:io';

int main() {
  Server server = Server();
  server.start('res/web');
  return 0;
}

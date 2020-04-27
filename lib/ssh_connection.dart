import 'dart:core';
import 'dart:developer' as dev;
import 'package:clusterup/ssh_key.dart';
import 'package:ssh/ssh.dart';
import 'package:flutter/services.dart';
import 'cluster.dart';

class SSHConnectionResult {
  bool success;
  String error;
  List<String> output = [];
  SSHConnectionResult(this.success, [this.error]);
}

// https://pub.dev/packages/ssh#-example-tab-
class SSHConnection {
  static Future<SSHConnectionResult> test(Cluster cluster, SSHKey key) async {
    return run(cluster, key, []);
  }

  static Future<SSHConnectionResult> run(Cluster cluster, SSHKey key, List<String> commands) async {
    SSHConnectionResult rv = SSHConnectionResult(false);
    SSHClient client = SSHClient(
      host: cluster.host,
      port: cluster.port,
      username: cluster.user,
      passwordOrKey: {"privateKey": key?.privString() ?? ""},
    );
    if (client != null) {
      dev.log("trying to connect to ${cluster.userHostPort()}");
      try {
        String result = await client.connect();
        if (result == "session_connected") {
          dev.log("connected to ${cluster.userHostPort()}");
          for (String command in commands) {
            dev.log("Running $command");
            String out = await client.execute(command);
            if (out.isNotEmpty) {
              dev.log("Got $out");
              rv.output += out.split("\r\n");
              if (rv.output.last.isEmpty) {
                rv.output.removeLast();
              }
            }
          }
        }
        client.disconnect();
        dev.log("disconnected from ${cluster.userHostPort()}");
        rv.success = true;
      } on PlatformException catch (e) {
        print('Error: ${e.code}\nError Message: ${e.message}');
        rv.error = e.message;
      }
    }
    return rv;
  }
}

import 'dart:core';
import 'dart:developer' as dev;
import 'package:clusterup/ssh_key.dart';
import 'package:ssh/ssh.dart';
import 'package:flutter/services.dart';

class SSHConnectionResult {
  bool success;
  String error;
  List<String> output = [];
  SSHCredentials creds;
  SSHConnectionResult(this.success, this.creds, [this.error]);
}

class SSHCredentials {
  String user;
  String host;
  int port;
  SSHCredentials(this.user, this.host, this.port);
  String toString() {
    return "$user@$host:$port";
  }
}

// https://pub.dev/packages/ssh#-example-tab-
class SSHConnection {
  static Future<SSHConnectionResult> test(SSHCredentials creds, SSHKey key) async {
    return run(creds, key, []);
  }

  static Future<SSHConnectionResult> run(SSHCredentials creds, SSHKey key, List<String> commands) async {
    SSHConnectionResult rv = SSHConnectionResult(false, creds);
    SSHClient client = SSHClient(
      host: creds.host,
      port: creds.port,
      username: creds.user,
      passwordOrKey: {"privateKey": key?.privString() ?? ""},
    );
    if (client != null) {
      dev.log("trying to connect to $creds");
      try {
        String result = await client.connect();
        if (result == "session_connected") {
          dev.log("connected to $creds");
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
        dev.log("disconnected from $creds");
        rv.success = true;
      } on PlatformException catch (e) {
        print('Error: ${e.code}\nError Message: ${e.message}');
        rv.error = e.message;
      }
    }
    return rv;
  }
}

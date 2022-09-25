import 'dart:core';
import 'package:clusterup/log.dart';
import 'package:clusterup/ssh_key.dart';
import 'package:ssh2/ssh2.dart';
import 'package:flutter/services.dart';

class SSHConnectionResult {
  bool success;
  String error;
  List<String> output = [];
  SSHCredentials creds;
  SSHConnectionResult(this.success, this.creds, [this.error = ""]);
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
      passwordOrKey: {"privateKey": key.privString()},
    );
    log("trying to connect to $creds");
    try {
      String? result = await client.connect();
      if (result == "session_connected") {
        log("connected to $creds");
        for (String command in commands) {
          log("Running $command");
          String? out = await client.execute(command);
          if (out != null && out.isNotEmpty) {
            log("Got $out");
            rv.output += out.split("\r\n");
            if (rv.output.last.isEmpty) {
              rv.output.removeLast();
            }
          }
        }
      }
      client.disconnect();
      log("disconnected from $creds");
      rv.success = true;
    } on PlatformException catch (e) {
      print('Error: ${e.code}\nError Message: ${e.message}');
      rv.error = e.message ?? "SSHConnection.run()";
    }
    return rv;
  }
}

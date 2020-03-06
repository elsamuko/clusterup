import 'dart:core';
import 'dart:developer' as dev;
import 'package:clusterup/ssh_key.dart';
import 'package:ssh/ssh.dart';
import 'package:flutter/services.dart';

class SSHConnectionResult {
  bool success;
  String error;
  SSHConnectionResult(this.success, [this.error]);
}

class SSHConnection {
  static Future<SSHConnectionResult> test(
      String user, String host, int port, SSHKey key) async {
    SSHConnectionResult rv = SSHConnectionResult(false);
    var client = SSHClient(
      host: host,
      port: port,
      username: user,
      passwordOrKey: {"privateKey": key?.privString() ?? ""},
    );
    if (client != null) {
      dev.log("trying to connect to $user@$host:$port");
      try {
        await client.connect();
        dev.log("connected to $user@$host:$port");
        client.disconnect();
        dev.log("disconnected from $user@$host:$port");
        rv.success = true;
      } on PlatformException catch (e) {
        print('Error: ${e.code}\nError Message: ${e.message}');
        rv.error = e.message;
      }
    }
    return rv;
  }
}

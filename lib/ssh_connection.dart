import 'dart:core';
import 'dart:developer' as dev;
import 'package:clusterup/ssh_key.dart';
import 'package:ssh/ssh.dart';
import 'package:flutter/services.dart';

class SSHConnection {
  static Future<bool> test(
      String user, String host, int port, SSHKey key) async {
    bool rv = false;
    var client = new SSHClient(
      host: host,
      port: port,
      username: user,
      passwordOrKey: {"privateKey": key.privString()},
    );
    if (client != null) {
      dev.log("trying to connect to $user@$host:$port");
      try {
        String result = await client.connect();
        dev.log("connected to $user@$host:$port");
        client.disconnect();
        dev.log("disconnected from $user@$host:$port");
        rv = true;
      } on PlatformException catch (e) {
        print('Error: ${e.code}\nError Message: ${e.message}');
      }
    }
    return rv;
  }
}

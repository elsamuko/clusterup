import 'dart:core';
import 'package:clusterup/log.dart';
import 'package:clusterup/ssh_key.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

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
  String? password;
  int port;

  SSHCredentials(this.user, this.host, this.password, this.port);

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
    final socket = await SSHSocket.connect(
      creds.host,
      creds.port,
    );
    final client = SSHClient(
      socket,
      username: creds.user,
      onPasswordRequest: () => creds.password,
      identities: SSHKeyPair.fromPem(key.privString()),
    );
    for (String command in commands) {
      log("Running $command");
      String out = utf8.decode(await client.run(command));
      if (out.isNotEmpty) {
        log("Got $out");
        rv.output += out.split("\n");
        if (rv.output.last.isEmpty) {
          rv.output.removeLast();
        }
      }
    }
    rv.success = true;
    return rv;
  }
}

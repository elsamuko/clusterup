import 'dart:convert';
import 'package:clusterup/log.dart';
import 'cluster.dart';
import 'ssh_key.dart';

class ClusterUpData {
  List<Cluster> clusters;
  SSHKey? sshKey;
  ClusterUpData({clusters, this.sshKey}) : clusters = clusters ?? [];

  String toJSON(bool withPrivateKey) {
    Map<String, dynamic> data = {};

    data["version"] = 1;

    data["clusters"] = clusters;

    if (sshKey != null) {
      // include private key only on demand
      if (withPrivateKey) {
        data["key"] = sshKey;
      } else {
        // only ssh public key
        data["key"] = {"ssh": sshKey?.pubForSSH() ?? "[?]" + " clusterup"};
      }
    }

    // encode as multiline json
    JsonEncoder encoder = JsonEncoder.withIndent("  ");
    return encoder.convert(data);
  }

  static ClusterUpData fromJSON(String input) {
    ClusterUpData output = ClusterUpData();

    Map<String, dynamic>? data;

    try {
      data = jsonDecode(input);
    } on FormatException catch (e) {
      log("json parse error $e");
    }

    // parse as json
    if (data != null) {
      log("upload is json");

      if (data.containsKey("clusters")) {
        data["clusters"].forEach((clusterData) {
          output.clusters.add(Cluster.fromMap(clusterData));
        });
      }

      if (data.containsKey("key")) {
        output.sshKey = SSHKey.fromPEM(data["key"]["private"]);
      }
    }

    // parse as private key
    else if (input.startsWith("-----BEGIN PRIVATE KEY-----") || input.startsWith("-----BEGIN RSA PRIVATE KEY-----")) {
      log("upload is private key");
      SSHKey? key = SSHKey.fromPEM(input);
      if (key != null) {
        output.sshKey = key;
      }
    }

    return output;
  }
}

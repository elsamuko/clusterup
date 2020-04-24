import 'dart:convert';

import 'cluster.dart';
import 'ssh_key.dart';

class ClusterUpData {
  List<Cluster> clusters;
  SSHKey sshKey;
  ClusterUpData({this.clusters, this.sshKey}) {
    clusters ??= [];
  }

  String toJSON(bool withPrivateKey) {
    Map<String, dynamic> data = {};
    data["clusters"] = clusters;

    // include private key only on demand
    if (withPrivateKey) {
      data["key"] = sshKey;
    } else {
      // only ssh public key
      data["key"] = {"ssh": sshKey.pubForSSH()};
    }

    // encode as multiline json
    JsonEncoder encoder = JsonEncoder.withIndent("  ");
    return encoder.convert(data);
  }

  static ClusterUpData fromJSON(String input) {
    ClusterUpData output = ClusterUpData();
    Map<String, dynamic> data = jsonDecode(input);

    data["clusters"].forEach((clusterData) {
      output.clusters.add(Cluster.fromMap(clusterData));
    });

    if (data.containsKey("key")) {
      output.sshKey = SSHKey.fromPEM(data["key"]["private"]);
    }

    return output;
  }
}

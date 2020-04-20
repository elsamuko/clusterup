import 'dart:convert';

import 'cluster.dart';
import 'ssh_key.dart';

class ClusterUpData {
  List<Cluster> clusters;
  SSHKey sshKey;
  ClusterUpData({this.clusters, this.sshKey}) {
    if (this.clusters == null) {
      clusters = [];
    }
  }

  String toJSON(bool withPrivateKey) {
    Map<String, dynamic> data = {};
    data["clusters"] = clusters;

    // include ssh public key
    data["ssh"] = sshKey.pubForSSH();

    // include private key only on demand
    if (withPrivateKey) {
      data["key"] = sshKey;
    }

    return jsonEncode(data);
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

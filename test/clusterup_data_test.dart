import 'package:clusterup/cluster_child.dart';
import 'package:clusterup/remote_action.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clusterup/ssh_key.dart';
import 'package:clusterup/clusterup_data.dart';
import 'package:clusterup/cluster.dart';

void main() {
  test('IO', () async {
    String privPEM = """-----BEGIN RSA PRIVATE KEY-----
MIICXgIBAAKBgQCrtwUnVi/NlhO7TvqzJmlVJNAsU20EFmFijeS3QekYOqt+etCD
7ZaAX8284orEeDJkxtYMC3NjCM23N/F/qEDE2QC4pdCuJP5+Ov/6mvy+6ZrxgIa1
+htTZMfpIKJZlvTiAkvQaFveivDfAQijrUbR+cWBp4loCCiLUC61Y51TQwIDAQAB
AoGBAJ3Gn7SiK3AyGlU733xmqdfy6FgiG4Pq8HY2vFVp+TwrBFJFlHvz/RpdbNPG
MA0QB/WzAQ+2IcJ4X1Se0YYjWcZDNr5LwtJpyyEgDozkAt2Ug+r7BrQCe2g3jOWU
iJgiXVHGNiACfZIu6FFple22pJqhb461F9JAbeQt6rtDpRapAkEA3yRrqCWbpzD7
baj/8raXZWNk28nHyIVC26Vi1hNY6CNWD20Z9v0TUSU22SJXeAXa+mHJKjs9j3bw
+2EH0cq7LwJBAMT//g8ssGlY9k8T6kza9bTsAqWW8NU85SFTi7BFHvKwP/4tyA/U
mCG35T9Qc377iSyA4TFcvftQZyr0P8uhVC0CQQDVrUWeNa0w09ngb7XwkOK3Bw/c
3AOAxAN624uindJEMRpHGV2Ew2FNEgrMsHL8DvdbTmpZE3NmvyoSPh9DyROnAkAL
VRaOVOnJBZ8VqXWe+jGMOM9mKyqreZdMtXuhpjhDibQEsSmDD524wtVjMQOT2HBp
qPhLWKRtIpDsvaQ12I/5AkEAzoq4e3Hin3hED9jsE7VPWINk/sTreDmMZTEdQyM9
s/NAKRvWDv52+0iZRWxTRie1/DQ/4dfKo2R07uctJcdnbw==
-----END RSA PRIVATE KEY-----""";

    SSHKey key = SSHKey.fromPEM(privPEM);
    List<Cluster> clusters = [
      Cluster(
        id: 0,
        name: "name",
        user: "user",
        host: "host",
        port: 22,
        actions: Set.of([RemoteAction.getActionFor("df")]),
      )
    ];

    clusters.first.addChild(host: "host2");

    ClusterUpData data = ClusterUpData(clusters: clusters, sshKey: key);
    String json = data.toJSON(true);
    expect(json.isNotEmpty, true);

    ClusterUpData rv = ClusterUpData.fromJSON(json);
    expect(rv.clusters.isNotEmpty, true);
    expect(rv.clusters.first.children.first.host, "host2");

    expect(rv.clusters, clusters);
    expect(rv.sshKey, key);
  });
}

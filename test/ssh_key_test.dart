import 'dart:convert';
import 'package:clusterup/rsa_key_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clusterup/ssh_key.dart';
import 'package:pointycastle/export.dart';

void main() {
  test('Key generation', () {
    SSHKey key = SSHKey.generate();
    String ssh = key.pubForSSH();
    expect(ssh.isEmpty, false);
  });

  test('Key parsing', () {
    // weak key for testing, use at least 2048 in production
    // openssl genrsa -out private.pem 1024
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

    // openssl rsa -in private.pem -out public.pem -outform PEM -pubout
    // openssl rsa -pubin -in public.pem -RSAPublicKey_out -out public.pkcs1
    String pubPEM = """-----BEGIN RSA PUBLIC KEY-----
MIGJAoGBAKu3BSdWL82WE7tO+rMmaVUk0CxTbQQWYWKN5LdB6Rg6q3560IPtloBf
zbziisR4MmTG1gwLc2MIzbc38X+oQMTZALil0K4k/n46//qa/L7pmvGAhrX6G1Nk
x+kgolmW9OICS9BoW96K8N8BCKOtRtH5xYGniWgIKItQLrVjnVNDAgMBAAE=
-----END RSA PUBLIC KEY-----""";

    // ssh-keygen -f public.pem -i -mPKCS8 > public.ssh
    String expectedSSH =
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQCrtwUnVi/NlhO7TvqzJmlVJNAsU20EFmFijeS3QekYOqt+etCD7ZaAX8284orEeDJkxtYMC3NjCM23N/F/qEDE2QC4pdCuJP5+Ov/6mvy+6ZrxgIa1+htTZMfpIKJZlvTiAkvQaFveivDfAQijrUbR+cWBp4loCCiLUC61Y51TQw==";

    SSHKey key = SSHKey.fromPEM(privPEM);

    String ssh = key.pubForSSH();
    expect(ssh == expectedSSH, true);

    String privGen = key.privString();
    expect(privGen == privPEM, true);

    String pubGen = key.pubString();
    RSAPublicKey publicKey = RsaKeyHelper.parsePublicKeyFromPem(pubGen);
    RSAPublicKey publicKey2 = RsaKeyHelper.parsePublicKeyFromPem(pubPEM);
    expect(pubGen == pubPEM, true);
  });
}

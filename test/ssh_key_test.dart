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

  //! weak key for testing, use at least 2048 in production
  test('Key parsing', () {
    // openssl genrsa -out private.pem 1024
    String privPKCS1 = """-----BEGIN RSA PRIVATE KEY-----
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

    // openssl pkcs8 -topk8 -inform PEM -outform PEM -nocrypt -in private.pem -out private.pkcs8
    String privPKCS8 = """-----BEGIN PRIVATE KEY-----
MIICeAIBADANBgkqhkiG9w0BAQEFAASCAmIwggJeAgEAAoGBAKu3BSdWL82WE7tO
+rMmaVUk0CxTbQQWYWKN5LdB6Rg6q3560IPtloBfzbziisR4MmTG1gwLc2MIzbc3
8X+oQMTZALil0K4k/n46//qa/L7pmvGAhrX6G1Nkx+kgolmW9OICS9BoW96K8N8B
CKOtRtH5xYGniWgIKItQLrVjnVNDAgMBAAECgYEAncaftKIrcDIaVTvffGap1/Lo
WCIbg+rwdja8VWn5PCsEUkWUe/P9Gl1s08YwDRAH9bMBD7YhwnhfVJ7RhiNZxkM2
vkvC0mnLISAOjOQC3ZSD6vsGtAJ7aDeM5ZSImCJdUcY2IAJ9ki7oUWmV7bakmqFv
jrUX0kBt5C3qu0OlFqkCQQDfJGuoJZunMPttqP/ytpdlY2TbycfIhULbpWLWE1jo
I1YPbRn2/RNRJTbZIld4Bdr6YckqOz2PdvD7YQfRyrsvAkEAxP/+DyywaVj2TxPq
TNr1tOwCpZbw1TzlIVOLsEUe8rA//i3ID9SYIbflP1BzfvuJLIDhMVy9+1BnKvQ/
y6FULQJBANWtRZ41rTDT2eBvtfCQ4rcHD9zcA4DEA3rbi6Kd0kQxGkcZXYTDYU0S
CsywcvwO91tOalkTc2a/KhI+H0PJE6cCQAtVFo5U6ckFnxWpdZ76MYw4z2YrKqt5
l0y1e6GmOEOJtASxKYMPnbjC1WMxA5PYcGmo+EtYpG0ikOy9pDXYj/kCQQDOirh7
ceKfeEQP2OwTtU9Yg2T+xOt4OYxlMR1DIz2z80ApG9YO/nb7SJlFbFNGJ7X8ND/h
18qjZHTu5y0lx2dv
-----END PRIVATE KEY-----""";

    // openssl rsa -in private.pem -out public.pem -outform PEM -pubout
    String pubPKCS8 = """-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCrtwUnVi/NlhO7TvqzJmlVJNAs
U20EFmFijeS3QekYOqt+etCD7ZaAX8284orEeDJkxtYMC3NjCM23N/F/qEDE2QC4
pdCuJP5+Ov/6mvy+6ZrxgIa1+htTZMfpIKJZlvTiAkvQaFveivDfAQijrUbR+cWB
p4loCCiLUC61Y51TQwIDAQAB
-----END PUBLIC KEY-----""";

    // openssl rsa -pubin -in public.pem -RSAPublicKey_out -out public.pkcs1
    String pubPKCS1 = """-----BEGIN RSA PUBLIC KEY-----
MIGJAoGBAKu3BSdWL82WE7tO+rMmaVUk0CxTbQQWYWKN5LdB6Rg6q3560IPtloBf
zbziisR4MmTG1gwLc2MIzbc38X+oQMTZALil0K4k/n46//qa/L7pmvGAhrX6G1Nk
x+kgolmW9OICS9BoW96K8N8BCKOtRtH5xYGniWgIKItQLrVjnVNDAgMBAAE=
-----END RSA PUBLIC KEY-----""";

    // ssh-keygen -f public.pem -i -mPKCS8 > public.ssh
    String expectedSSH =
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQCrtwUnVi/NlhO7TvqzJmlVJNAsU20EFmFijeS3QekYOqt+etCD7ZaAX8284orEeDJkxtYMC3NjCM23N/F/qEDE2QC4pdCuJP5+Ov/6mvy+6ZrxgIa1+htTZMfpIKJZlvTiAkvQaFveivDfAQijrUbR+cWBp4loCCiLUC61Y51TQw==";

    SSHKey key = SSHKey.fromPEM(privPKCS1);
    expect(key, SSHKey.fromPEM(privPKCS8));

    RSAPrivateKey privKey = RsaKeyHelper.fromPEMToPrivateKey(privPKCS1);
    expect(privPKCS8, RsaKeyHelper.fromPrivateKeyToPEMPKCS8(privKey));

    String ssh = key.pubForSSH();
    expect(ssh, expectedSSH);

    String privGen = key.privString();
    expect(privGen, privPKCS1);

    String pubGen = key.pubString();
    RSAPublicKey publicKey = RsaKeyHelper.fromPEMToPublicKey(pubGen);
    RSAPublicKey publicKey2 = RsaKeyHelper.fromPEMToPublicKey(pubPKCS1);
    expect(publicKey, RsaKeyHelper.fromPEMToPublicKey(pubPKCS8));
    expect(pubPKCS8, RsaKeyHelper.fromPublicKeyToPEMPKCS8(publicKey));
    expect(pubGen, pubPKCS1);
    expect(publicKey, publicKey2);
  });
}

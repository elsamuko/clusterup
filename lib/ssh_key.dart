import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';
import 'package:pointycastle/export.dart';
import 'package:pointycastle/pointycastle.dart';
import 'rsa_key_helper.dart';

class SSHKey {
  RSAPrivateKey _privateKey;
  RSAPublicKey _publicKey;

  SSHKey(this._privateKey) {
    BigInt publicExponent = RsaKeyHelper.getPublicExponent(_privateKey);
    assert(publicExponent == BigInt.from(65537)); // usually it's 65537
    _publicKey = RSAPublicKey(_privateKey.modulus, publicExponent);
  }

  // https://github.com/PointyCastle/pointycastle/blob/master/tutorials/rsa.md
  static SecureRandom _getSecureRandom() {
    final secureRandom = FortunaRandom();

    final seedSource = Random.secure();
    final seeds = <int>[];
    for (int i = 0; i < 32; i++) {
      seeds.add(seedSource.nextInt(255));
    }
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

    return secureRandom;
  }

  // https://github.com/dart-lang/sdk/issues/32803#issuecomment-387405784
  List<int> _writeBigInt(BigInt number, [int size]) {
    // Not handling negative numbers. Decide how you want to do that.
    int bytes = size ?? 1 + (number.bitLength + 7) >> 3;
    BigInt b256 = BigInt.from(256);
    List<int> result = List<int>(bytes);

    int pos = bytes - 1;

    do {
      result[pos] = number.remainder(b256).toInt();
      number = number >> 8;
    } while (pos-- != 0);

    return result;
  }

  String pubForSSH() {
    List<int> head = utf8.encode("ssh-rsa");
    List<int> e = _writeBigInt(_publicKey.e);
    List<int> n = _writeBigInt(_publicKey.n);
    List<int> szHead = _writeBigInt(BigInt.from(head.length), 4);
    List<int> szE = _writeBigInt(BigInt.from(e.length), 4);
    List<int> szN = _writeBigInt(BigInt.from(n.length), 4);
    List<int> binary = szHead + head + szE + e + szN + n;
    return "ssh-rsa " + base64.encode(binary);
  }

  String privString() {
    return RsaKeyHelper.encodePrivateKeyToPemPKCS1(_privateKey);
  }

  String pubString() {
    return RsaKeyHelper.encodePublicKeyToPemPKCS1(_publicKey);
  }

  // https://github.com/PointyCastle/pointycastle/blob/master/tutorials/rsa.md
  static SSHKey generate() {
    SecureRandom rnd = SSHKey._getSecureRandom();

    final rsaParams = RSAKeyGeneratorParameters(BigInt.from(65537), 2048, 64);
    final params = ParametersWithRandom(rsaParams, rnd);

    RSAKeyGenerator keyGenerator = RSAKeyGenerator();
    keyGenerator.init(params);

    final pair = keyGenerator.generateKeyPair();
    final publicKey = pair.publicKey as RSAPublicKey;
    final privateKey = pair.privateKey as RSAPrivateKey;

    return SSHKey(privateKey);
  }

  static SSHKey fromPEM(String PEM) {
    RSAPrivateKey privateKey = RsaKeyHelper.parsePrivateKeyFromPem(PEM);
    return SSHKey(privateKey);
  }
}

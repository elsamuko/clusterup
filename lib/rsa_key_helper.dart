// derived from
// https://github.com/Vanethos/flutter_rsa_generator_example/blob/master/lib/utils/rsa_key_helper.dart
//! \sa https://tls.mbed.org/kb/cryptography/asn1-key-structures-in-der-and-pem
//! \sa https://www.cem.me/pki/

import 'dart:convert';
import 'dart:typed_data';
import "package:asn1lib/asn1lib.dart";
import "package:pointycastle/export.dart";

class RsaKeyHelper {
  /// convert PEM to DER
  static Uint8List _fromPEMToDER(String pem) {
    pem = pem.trim();
    pem = pem.replaceAll('\n', '');
    pem = pem.replaceAll('\r', '');

    List<String> headers = [
      "-----BEGIN PUBLIC KEY-----",
      "-----BEGIN PRIVATE KEY-----",
      "-----BEGIN RSA PUBLIC KEY-----",
      "-----BEGIN RSA PRIVATE KEY-----",
    ];

    List<String> footers = [
      "-----END PUBLIC KEY-----",
      "-----END PRIVATE KEY-----",
      "-----END RSA PUBLIC KEY-----",
      "-----END RSA PRIVATE KEY-----",
    ];

    for (String header in headers) {
      if (pem.startsWith(header)) {
        pem = pem.substring(header.length);
        break;
      }
    }

    for (String footer in footers) {
      if (pem.endsWith(footer)) {
        pem = pem.substring(0, pem.length - footer.length);
        break;
      }
    }

    pem = pem.replaceAll(' ', '');
    return base64.decode(pem);
  }

  /// wraps a string with newlines every 64 characters
  static String _wrap64(String input) {
    StringBuffer buffer = StringBuffer();
    int size = input.length;
    int lines = size ~/ 64;
    int rest = size % 64;

    for (int i = 0; i < lines; ++i) {
      buffer.write(input.substring(i * 64, (i + 1) * 64));
      buffer.write("\n");
    }

    if (rest > 0) {
      buffer.write(input.substring(size - rest));
      buffer.write("\n");
    }

    return buffer.toString();
  }

  /// inverse of private exponent -> public exponent
  //! \sa rsa_key_generator.dart
  static BigInt getPublicExponent(RSAPrivateKey privateKey) {
    BigInt pSub1 = (privateKey.p - BigInt.one);
    BigInt qSub1 = (privateKey.q - BigInt.one);
    BigInt phi = (pSub1 * qSub1);
    BigInt publicExponent = privateKey.exponent.modInverse(phi);
    return publicExponent;
  }

  /// parse rsa public key from PKCS1/PKCS8 ASN1 sequence
  static RSAPublicKey _fromASN1ToPublicKey(ASN1Sequence sequence) {
    RSAPublicKey pubKey;

    // PKCS1
    if (sequence.elements.first.runtimeType == ASN1Integer) {
      ASN1Integer modulus = sequence.elements[0];
      ASN1Integer exponent = sequence.elements[1];
      pubKey = RSAPublicKey(modulus.valueAsBigInteger, exponent.valueAsBigInteger);
    }
    // PKCS8 -> get PKCS1 part and reenter
    else {
      ASN1Object sub = sequence.elements[1];
      ASN1Sequence subSequence = ASN1Parser(sub.contentBytes()).nextObject();
      pubKey = _fromASN1ToPublicKey(subSequence);
    }

    return pubKey;
  }

  /// parse rsa public key from PKCS1/PKCS8 PEM
  static RSAPublicKey fromPEMToPublicKey(String pem) {
    Uint8List der = _fromPEMToDER(pem);
    ASN1Sequence sequence = ASN1Parser(der).nextObject();
    return _fromASN1ToPublicKey(sequence);
  }

  /// parse rsa private key from PKCS1/PKCS8 ASN1 sequence
  static RSAPrivateKey _fromASN1ToPrivateKey(ASN1Sequence sequence) {
    RSAPrivateKey privKey;

    // PKCS1
    if (sequence.elements[1].runtimeType == ASN1Integer) {
      ASN1Integer modulus = sequence.elements[1];
      // ASN1Integer publicExponent = sequence.elements[2];
      ASN1Integer privateExponent = sequence.elements[3];
      ASN1Integer p = sequence.elements[4];
      ASN1Integer q = sequence.elements[5];
      privKey = RSAPrivateKey(
          modulus.valueAsBigInteger, privateExponent.valueAsBigInteger, p.valueAsBigInteger, q.valueAsBigInteger);
    }
    // PKCS8 -> get PKCS1 part and reenter
    else {
      ASN1Object sub = sequence.elements[2];
      ASN1Sequence subSequence = ASN1Parser(sub.contentBytes()).nextObject();
      privKey = _fromASN1ToPrivateKey(subSequence);
    }

    return privKey;
  }

  /// parse rsa public key from PKCS1/PKCS8 PEM
  static RSAPrivateKey fromPEMToPrivateKey(String pem) {
    Uint8List der = _fromPEMToDER(pem);
    ASN1Sequence sequence = ASN1Parser(der).nextObject();
    return _fromASN1ToPrivateKey(sequence);
  }

  /// generate PKCS1 ASN1 from rsa private key
  static ASN1Sequence _fromPrivateKeyToASN1PKCS1(RSAPrivateKey privateKey) {
    ASN1Sequence sequence = ASN1Sequence();

    ASN1Integer version = ASN1Integer(BigInt.from(0));
    ASN1Integer modulus = ASN1Integer(privateKey.modulus);
    ASN1Integer publicExponent = ASN1Integer(getPublicExponent(privateKey));
    ASN1Integer privateExponent = ASN1Integer(privateKey.exponent);
    ASN1Integer p = ASN1Integer(privateKey.p);
    ASN1Integer q = ASN1Integer(privateKey.q);
    ASN1Integer exp1 = ASN1Integer(privateKey.d % (privateKey.p - BigInt.from(1)));
    ASN1Integer exp2 = ASN1Integer(privateKey.d % (privateKey.q - BigInt.from(1)));
    ASN1Integer co = ASN1Integer(privateKey.q.modInverse(privateKey.p));

    sequence.add(version);
    sequence.add(modulus);
    sequence.add(publicExponent);
    sequence.add(privateExponent);
    sequence.add(p);
    sequence.add(q);
    sequence.add(exp1);
    sequence.add(exp2);
    sequence.add(co);

    return sequence;
  }

  /// generate PKCS1 PEM from rsa private key
  static String fromPrivateKeyToPEMPKCS1(RSAPrivateKey privateKey) {
    ASN1Sequence sequence = _fromPrivateKeyToASN1PKCS1(privateKey);
    String dataBase64 = base64.encode(sequence.encodedBytes);
    String wrapped = _wrap64(dataBase64);
    return """-----BEGIN RSA PRIVATE KEY-----\n$wrapped-----END RSA PRIVATE KEY-----""";
  }

  /// generate PKCS8 PEM from rsa private key
  static String fromPrivateKeyToPEMPKCS8(RSAPrivateKey privateKey) {
    ASN1Sequence sequence = ASN1Sequence();

    // version
    ASN1Integer version = ASN1Integer(BigInt.from(0));

    // private key algorithm identifier
    ASN1Sequence identifier = ASN1Sequence();
    ASN1ObjectIdentifier.registerFrequentNames();
    identifier.add(ASN1ObjectIdentifier.fromName("rsaEncryption"));
    identifier.add(ASN1Null());

    // PKCS1
    ASN1OctetString octets = ASN1OctetString(_fromPrivateKeyToASN1PKCS1(privateKey).encodedBytes);

    sequence.add(version);
    sequence.add(identifier);
    sequence.add(octets);

    String dataBase64 = base64.encode(sequence.encodedBytes);
    String wrapped = _wrap64(dataBase64);

    return """-----BEGIN PRIVATE KEY-----\n$wrapped-----END PRIVATE KEY-----""";
  }

  /// generate PKCS1 ASN1 from rsa public key
  static ASN1Sequence _fromPublicKeyToASN1PKCS1(RSAPublicKey publicKey) {
    ASN1Sequence sequence = ASN1Sequence();
    sequence.add(ASN1Integer(publicKey.modulus));
    sequence.add(ASN1Integer(publicKey.exponent));
    return sequence;
  }

  /// generate PKCS1 PEM from rsa public key
  static String fromPublicKeyToPEMPKCS1(RSAPublicKey publicKey) {
    ASN1Sequence sequence = _fromPublicKeyToASN1PKCS1(publicKey);
    String data64 = base64.encode(sequence.encodedBytes);
    String wrapped = _wrap64(data64);
    return """-----BEGIN RSA PUBLIC KEY-----\n$wrapped-----END RSA PUBLIC KEY-----""";
  }

  /// generate PKCS8 PEM from rsa public key
  static String fromPublicKeyToPEMPKCS8(RSAPublicKey publicKey) {
    ASN1Sequence sequence = ASN1Sequence();

    // private key algorithm identifier
    ASN1Sequence identifier = ASN1Sequence();
    ASN1ObjectIdentifier.registerFrequentNames();
    identifier.add(ASN1ObjectIdentifier.fromName("rsaEncryption"));
    identifier.add(ASN1Null());

    // PKCS1
    ASN1BitString bits = ASN1BitString(_fromPublicKeyToASN1PKCS1(publicKey).encodedBytes);

    sequence.add(identifier);
    sequence.add(bits);

    String dataBase64 = base64.encode(sequence.encodedBytes);
    String wrapped = _wrap64(dataBase64);

    return """-----BEGIN PUBLIC KEY-----\n$wrapped-----END PUBLIC KEY-----""";
  }
}

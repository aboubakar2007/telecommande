/// Certificat client du téléphone + lecture des clés RSA.
///
/// Chaque téléphone génère UNE fois une paire RSA 2048 et un certificat
/// auto-signé. Le téléviseur mémorise ce certificat lors de l'association :
/// c'est lui qui identifie le téléphone ensuite (port 6466).
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:pointycastle/asn1.dart';

class ClientIdentity {
  const ClientIdentity({required this.certificatePem, required this.privateKeyPem});

  final String certificatePem;
  final String privateKeyPem;

  Map<String, String> toJson() => {'cert': certificatePem, 'key': privateKeyPem};

  factory ClientIdentity.fromJson(Map<String, Object?> j) =>
      ClientIdentity(certificatePem: j['cert']! as String, privateKeyPem: j['key']! as String);
}

class RsaPublicNumbers {
  const RsaPublicNumbers(this.modulus, this.exponent);
  final BigInt modulus;
  final BigInt exponent;
}

abstract final class CertificateManager {
  /// Génère une identité client (≈1 à 3 s sur téléphone : à faire hors UI).
  static ClientIdentity generate({String commonName = 'atvremote'}) {
    final pair = CryptoUtils.generateRSAKeyPair(keySize: 2048);
    final priv = pair.privateKey as RSAPrivateKey;
    final pub = pair.publicKey as RSAPublicKey;
    final csr = X509Utils.generateRsaCsrPem({'CN': commonName}, priv, pub);
    final cert = X509Utils.generateSelfSignedCertificate(
      priv,
      csr,
      365 * 20,
      serialNumber: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    return ClientIdentity(
      certificatePem: cert,
      privateKeyPem: CryptoUtils.encodeRSAPrivateKeyToPemPkcs1(priv),
    );
  }

  static Uint8List pemToDer(String pem) {
    final body = pem
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && !l.startsWith('-----'))
        .join();
    return base64.decode(body);
  }

  /// Extrait modulus/exposant RSA d'un certificat X.509 (DER).
  static RsaPublicNumbers publicNumbersFromCertDer(Uint8List der) {
    final spki = _findRsaSpki(ASN1Parser(der).nextObject());
    if (spki == null) {
      throw const FormatException('Clé publique RSA introuvable dans le certificat');
    }
    final bitString = spki.elements![1] as ASN1BitString;
    final keyBytes = Uint8List.fromList(bitString.stringValues!);
    final rsaSeq = ASN1Parser(keyBytes).nextObject() as ASN1Sequence;
    final n = (rsaSeq.elements![0] as ASN1Integer).integer!;
    final e = (rsaSeq.elements![1] as ASN1Integer).integer!;
    return RsaPublicNumbers(n, e);
  }

  static RsaPublicNumbers publicNumbersFromCertPem(String pem) =>
      publicNumbersFromCertDer(pemToDer(pem));

  static const _rsaOid = '1.2.840.113549.1.1.1';

  /// Parcourt l'arbre ASN.1 à la recherche de SubjectPublicKeyInfo RSA.
  static ASN1Sequence? _findRsaSpki(ASN1Object obj) {
    if (obj is! ASN1Sequence) return null;
    final els = obj.elements ?? const [];
    if (els.length == 2 && els[0] is ASN1Sequence && els[1] is ASN1BitString) {
      final alg = (els[0] as ASN1Sequence).elements ?? const [];
      if (alg.isNotEmpty &&
          alg[0] is ASN1ObjectIdentifier &&
          (alg[0] as ASN1ObjectIdentifier).objectIdentifierAsString == _rsaOid) {
        return obj;
      }
    }
    for (final child in els) {
      final found = _findRsaSpki(child);
      if (found != null) return found;
    }
    return null;
  }
}

import 'dart:io';

import 'package:family_remote/core/protocol/atv/certificate_manager.dart';
import 'package:family_remote/core/protocol/atv/pairing_secret.dart';
import 'package:flutter_test/flutter_test.dart';

String hex(List<int> b) => b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

void main() {
  group('secret d’association', () {
    // Vecteur calculé indépendamment avec Python (hashlib), cf. androidtvremote2.
    final clientN = BigInt.parse('${'c0ffee' * 40}01', radix: 16);
    final serverN = BigInt.parse('abcdef12' * 32, radix: 16);
    final e = BigInt.from(65537);

    test('valeur attendue', () {
      final s = computePairingSecret(
        clientModulus: clientN,
        clientExponent: e,
        serverModulus: serverN,
        serverExponent: e,
        code: 'b43a7f',
      );
      expect(hex(s), 'b4d8c7cdfcdb5eb837f0b27fd67c70f30a594fb239a1c859bf7bdfca93f32826');
    });

    test('mauvais code détecté localement', () {
      expect(
        () => computePairingSecret(
            clientModulus: clientN, clientExponent: e, serverModulus: serverN, serverExponent: e, code: 'B53A7F'),
        throwsA(isA<InvalidPairingCodeException>()),
      );
    });

    test('format de code invalide', () {
      expect(
        () => computePairingSecret(
            clientModulus: clientN, clientExponent: e, serverModulus: serverN, serverExponent: e, code: 'ZZ12'),
        throwsA(isA<InvalidPairingCodeException>()),
      );
    });

    test('bigIntToBytes : longueur minimale', () {
      expect(hex(bigIntToBytes(BigInt.from(65537))), '010001');
    });
  });

  group('certificats', () {
    test('lecture de la clé publique du vrai certificat Sony', () {
      final der = File('test/fixtures/sony_bravia_cert.der').readAsBytesSync();
      final pub = CertificateManager.publicNumbersFromCertDer(der);
      expect(pub.exponent, BigInt.from(65537));
      expect(pub.modulus.bitLength, 2048);
      expect(pub.modulus.toRadixString(16).toUpperCase(), startsWith('ACD5B9768C00D06F164A27AFA9D365F3'));
    });

    test('identité client générée, relue, et acceptée par SecurityContext (TLS)', () {
      final id = CertificateManager.generate();
      final pub = CertificateManager.publicNumbersFromCertPem(id.certificatePem);
      expect(pub.modulus.bitLength, 2048);
      expect(pub.exponent, BigInt.from(65537));

      final ctx = SecurityContext(withTrustedRoots: false)
        ..useCertificateChainBytes(id.certificatePem.codeUnits)
        ..usePrivateKeyBytes(id.privateKeyPem.codeUnits);
      expect(ctx, isNotNull);
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}

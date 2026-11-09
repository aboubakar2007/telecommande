/// Calcul du secret d'association Android TV Remote v2.
///
/// secret = SHA-256( n_client ‖ e_client ‖ n_tv ‖ e_tv ‖ octets(code[2..6]) )
/// et le 1er octet du secret doit valoir code[0..2] : cela permet de détecter
/// une faute de frappe AVANT d'envoyer quoi que ce soit au téléviseur.
library;

import 'dart:typed_data';

import 'package:crypto/crypto.dart';

class InvalidPairingCodeException implements Exception {
  const InvalidPairingCodeException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Encode un entier positif en big-endian, longueur minimale
/// (équivalent de `int.to_bytes((n.bit_length()+7)//8, 'big')`).
Uint8List bigIntToBytes(BigInt n) {
  if (n.isNegative) throw ArgumentError('entier négatif');
  if (n == BigInt.zero) return Uint8List(0);
  final len = (n.bitLength + 7) >> 3;
  final out = Uint8List(len);
  var v = n;
  final mask = BigInt.from(0xFF);
  for (var i = len - 1; i >= 0; i--) {
    out[i] = (v & mask).toInt();
    v >>= 8;
  }
  return out;
}

final _hex6 = RegExp(r'^[0-9a-fA-F]{6}$');

Uint8List computePairingSecret({
  required BigInt clientModulus,
  required BigInt clientExponent,
  required BigInt serverModulus,
  required BigInt serverExponent,
  required String code,
}) {
  final c = code.trim();
  if (!_hex6.hasMatch(c)) {
    throw const InvalidPairingCodeException('Le code doit contenir 6 caractères (0-9, A-F).');
  }
  final tail = [
    int.parse(c.substring(2, 4), radix: 16),
    int.parse(c.substring(4, 6), radix: 16),
  ];
  final input = BytesBuilder(copy: false)
    ..add(bigIntToBytes(clientModulus))
    ..add(bigIntToBytes(clientExponent))
    ..add(bigIntToBytes(serverModulus))
    ..add(bigIntToBytes(serverExponent))
    ..add(tail);
  final digest = Uint8List.fromList(sha256.convert(input.toBytes()).bytes);

  if (digest[0] != int.parse(c.substring(0, 2), radix: 16)) {
    throw const InvalidPairingCodeException('Code incorrect : vérifiez le code affiché sur le téléviseur.');
  }
  return digest;
}

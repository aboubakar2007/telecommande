/// Messages du protocole d'association (« polo », port 6467).
library;

import 'dart:typed_data';

import 'proto_codec.dart';

abstract final class PoloStatus {
  static const ok = 200;
  static const error = 400;
  static const badConfiguration = 401;
  static const badSecret = 402;
}

/// Numéros de champ de OuterMessage.
abstract final class PoloField {
  static const protocolVersion = 1;
  static const status = 2;
  static const pairingRequest = 10;
  static const pairingRequestAck = 11;
  static const options = 20;
  static const configuration = 30;
  static const configurationAck = 31;
  static const secret = 40;
  static const secretAck = 41;
}

const _encodingHexadecimal = 3;
const _roleInput = 1;
const _symbolLength = 6;

ProtoWriter _outer() => ProtoWriter()
  ..varint(PoloField.protocolVersion, 2)
  ..varint(PoloField.status, PoloStatus.ok);

ProtoWriter _hexEncoding() => ProtoWriter()
  ..varint(1, _encodingHexadecimal)
  ..varint(2, _symbolLength);

abstract final class PairingMessages {
  static Uint8List _wrap(int field, ProtoWriter body) =>
      (_outer()..message(field, body)).toBytes();

  static Uint8List pairingRequest(String clientName) => _wrap(
      PoloField.pairingRequest,
      ProtoWriter()
        ..string(1, 'atvremote')
        ..string(2, clientName));

  static Uint8List options() => _wrap(
      PoloField.options,
      ProtoWriter()
        ..message(1, _hexEncoding())
        ..varint(3, _roleInput));

  static Uint8List configuration() => _wrap(
      PoloField.configuration,
      ProtoWriter()
        ..message(1, _hexEncoding())
        ..varint(2, _roleInput));

  static Uint8List secret(List<int> secret) =>
      _wrap(PoloField.secret, ProtoWriter()..bytes(1, secret));
}

/// Réponse du téléviseur pendant l'association.
enum PoloReply { pairingRequestAck, options, configurationAck, secretAck, unknown }

class PoloResponse {
  PoloResponse(this.status, this.reply);

  final int status;
  final PoloReply reply;

  bool get ok => status == PoloStatus.ok;

  factory PoloResponse.parse(Uint8List data) {
    final m = ProtoMessage.parse(data);
    final status = m.intField(PoloField.status) ?? 0;
    final reply = m.has(PoloField.pairingRequestAck)
        ? PoloReply.pairingRequestAck
        : m.has(PoloField.options)
            ? PoloReply.options
            : m.has(PoloField.configurationAck)
                ? PoloReply.configurationAck
                : m.has(PoloField.secretAck)
                    ? PoloReply.secretAck
                    : PoloReply.unknown;
    return PoloResponse(status, reply);
  }
}

/// Encodeur/décodeur protobuf minimal + framing « longueur varint ».
///
/// Le protocole Android TV Remote v2 n'utilise que deux types de champs :
/// varint (wire type 0) et length-delimited (wire type 2 : bytes, string,
/// sous-message). Inutile d'embarquer protoc pour si peu.
library;

import 'dart:convert';
import 'dart:typed_data';

/// Construit un message protobuf champ par champ.
class ProtoWriter {
  final BytesBuilder _b = BytesBuilder(copy: false);

  static void writeVarint(BytesBuilder b, int value) {
    // Les entiers négatifs ne sont jamais utilisés par ce protocole.
    if (value < 0) throw ArgumentError('varint négatif non supporté: $value');
    var v = value;
    while (v >= 0x80) {
      b.addByte((v & 0x7F) | 0x80);
      v >>= 7;
    }
    b.addByte(v);
  }

  void _tag(int field, int wireType) => writeVarint(_b, (field << 3) | wireType);

  void varint(int field, int value) {
    _tag(field, 0);
    writeVarint(_b, value);
  }

  void boolean(int field, bool value) => varint(field, value ? 1 : 0);

  void bytes(int field, List<int> value) {
    _tag(field, 2);
    writeVarint(_b, value.length);
    _b.add(value);
  }

  void string(int field, String value) => bytes(field, utf8.encode(value));

  /// Sous-message (éventuellement vide).
  void message(int field, ProtoWriter sub) => bytes(field, sub.toBytes());

  Uint8List toBytes() => _b.toBytes();
}

/// Message protobuf décodé : numéro de champ → valeurs (int ou Uint8List).
class ProtoMessage {
  ProtoMessage._(this._fields);

  final Map<int, List<Object>> _fields;

  factory ProtoMessage.parse(Uint8List data) {
    final fields = <int, List<Object>>{};
    var pos = 0;
    (int, int) readVarint() {
      var result = 0;
      var shift = 0;
      while (true) {
        if (pos >= data.length) throw const FormatException('varint tronqué');
        final byte = data[pos++];
        result |= (byte & 0x7F) << shift;
        if (byte & 0x80 == 0) return (result, pos);
        shift += 7;
        if (shift > 63) throw const FormatException('varint trop long');
      }
    }

    while (pos < data.length) {
      final (tag, _) = readVarint();
      final field = tag >> 3;
      final wire = tag & 7;
      switch (wire) {
        case 0:
          final (v, _) = readVarint();
          fields.putIfAbsent(field, () => []).add(v);
        case 2:
          final (len, _) = readVarint();
          if (pos + len > data.length) throw const FormatException('champ tronqué');
          fields.putIfAbsent(field, () => []).add(Uint8List.sublistView(data, pos, pos + len));
          pos += len;
        case 1:
          pos += 8; // fixed64 : ignoré
        case 5:
          pos += 4; // fixed32 : ignoré
        default:
          throw FormatException('wire type inconnu: $wire');
      }
    }
    return ProtoMessage._(fields);
  }

  bool has(int field) => _fields.containsKey(field);

  int? intField(int field) => _fields[field]?.whereType<int>().lastOrNull;

  Uint8List? bytesField(int field) => _fields[field]?.whereType<Uint8List>().lastOrNull;

  String? stringField(int field) {
    final b = bytesField(field);
    return b == null ? null : utf8.decode(b, allowMalformed: true);
  }

  ProtoMessage? messageField(int field) {
    final b = bytesField(field);
    return b == null ? null : ProtoMessage.parse(b);
  }

  List<ProtoMessage> repeatedMessages(int field) =>
      (_fields[field] ?? const []).whereType<Uint8List>().map(ProtoMessage.parse).toList();

  Iterable<int> get fieldNumbers => _fields.keys;
}

/// Préfixe un message par sa longueur (varint).
Uint8List frame(Uint8List message) {
  final b = BytesBuilder(copy: false);
  ProtoWriter.writeVarint(b, message.length);
  b.add(message);
  return b.toBytes();
}

/// Reconstitue les messages à partir d'un flux TCP découpé arbitrairement.
class FrameDecoder {
  final BytesBuilder _buf = BytesBuilder();

  static const maxMessageSize = 1 << 20;

  /// Ajoute des octets reçus et retourne les messages complets.
  List<Uint8List> add(List<int> chunk) {
    _buf.add(chunk);
    final data = _buf.takeBytes();
    final out = <Uint8List>[];
    var pos = 0;
    while (pos < data.length) {
      var len = 0;
      var shift = 0;
      var p = pos;
      var complete = false;
      while (p < data.length) {
        final byte = data[p++];
        len |= (byte & 0x7F) << shift;
        if (byte & 0x80 == 0) {
          complete = true;
          break;
        }
        shift += 7;
        if (shift > 28) throw const FormatException('longueur de trame invalide');
      }
      if (!complete) break; // varint incomplet
      if (len > maxMessageSize) throw const FormatException('trame trop grande');
      if (p + len > data.length) break; // corps incomplet
      out.add(Uint8List.fromList(data.sublist(p, p + len)));
      pos = p + len;
    }
    if (pos < data.length) _buf.add(data.sublist(pos));
    return out;
  }
}

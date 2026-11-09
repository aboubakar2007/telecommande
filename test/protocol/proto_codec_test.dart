import 'dart:typed_data';

import 'package:family_remote/core/protocol/atv/key_codes.dart';
import 'package:family_remote/core/protocol/atv/pairing_messages.dart';
import 'package:family_remote/core/protocol/atv/proto_codec.dart';
import 'package:family_remote/core/protocol/atv/remote_messages.dart';
import 'package:family_remote/core/protocol/tv_protocol.dart';
import 'package:flutter_test/flutter_test.dart';

String hex(List<int> b) => b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

Uint8List unhex(String s) =>
    Uint8List.fromList([for (var i = 0; i < s.length; i += 2) int.parse(s.substring(i, i + 2), radix: 16)]);

void main() {
  group('varint / framing', () {
    test('varint multi-octets', () {
      final w = ProtoWriter()..varint(1, 300);
      expect(hex(w.toBytes()), '08ac02');
    });

    test('FrameDecoder reconstitue des messages coupés au hasard', () {
      final a = Uint8List.fromList(List.generate(200, (i) => i % 256)); // longueur 200 → varint 2 octets
      final b = Uint8List.fromList([1, 2, 3]);
      final stream = [...frame(a), ...frame(b)];
      final dec = FrameDecoder();
      final out = <Uint8List>[];
      for (var i = 0; i < stream.length; i += 7) {
        out.addAll(dec.add(stream.sublist(i, (i + 7).clamp(0, stream.length))));
      }
      expect(out.length, 2);
      expect(out[0], a);
      expect(out[1], b);
    });
  });

  group('messages d’association (octets exacts)', () {
    test('pairing_request', () {
      // 08 02 | 10 c8 01 | 52 len { 0a 09 "atvremote" 12 01 "x" }
      expect(hex(PairingMessages.pairingRequest('x')),
          '0802' '10c801' '520e' '0a09${hex('atvremote'.codeUnits)}' '120178');
    });

    test('options : HEXADECIMAL / 6 / INPUT', () {
      expect(hex(PairingMessages.options()), '0802' '10c801' 'a20108' '0a0408031006' '1801');
    });

    test('configuration', () {
      expect(hex(PairingMessages.configuration()), '0802' '10c801' 'f20108' '0a0408031006' '1001');
    });

    test('parse configuration_ack', () {
      // status 200 + champ 31 vide
      final r = PoloResponse.parse(unhex('080210c801fa0100'));
      expect(r.ok, isTrue);
      expect(r.reply, PoloReply.configurationAck);
    });

    test('parse erreur BAD_SECRET', () {
      // status 402 = varint 92 03
      final r = PoloResponse.parse(unhex('0802109203'));
      expect(r.status, 402);
      expect(r.ok, isFalse);
    });
  });

  group('messages de télécommande', () {
    test('appui court sur OK', () {
      final bytes = RemoteMessages.keyInject(androidKeyCodes[TvKey.ok]!, directionCode(KeyPress.short));
      expect(hex(bytes), '5204' '0817' '1003');
    });

    test('ping : la requête est comprise', () {
      final ping = (ProtoWriter()..message(RemoteField.pingRequest, ProtoWriter()..varint(1, 42))).toBytes();
      final msg = RemoteIncoming.parse(ping);
      expect(msg, isA<PingRequest>().having((p) => p.val1, 'val1', 42));
      expect(hex(RemoteMessages.pingResponse(42)), '4a02082a');
    });

    test('remote_configure décodé', () {
      final cfg = (ProtoWriter()
            ..message(
                RemoteField.configure,
                ProtoWriter()
                  ..varint(1, 622)
                  ..message(2, ProtoWriter()..string(1, 'BRAVIA 4K GB')..string(2, 'Sony'))))
          .toBytes();
      final msg = RemoteIncoming.parse(cfg) as ConfigureRequest;
      expect(msg.features, 622);
      expect(msg.vendor, 'Sony');
      expect(msg.model, 'BRAVIA 4K GB');
    });

    test('volume décodé', () {
      final v = (ProtoWriter()
            ..message(RemoteField.setVolumeLevel, ProtoWriter()..varint(6, 100)..varint(7, 25)..varint(8, 0)))
          .toBytes();
      final msg = RemoteIncoming.parse(v) as VolumeNotice;
      expect((msg.level, msg.max, msg.muted), (25, 100, false));
    });

    test('toutes les touches ont un code', () {
      for (final k in TvKey.values) {
        expect(androidKeyCodes[k], isNotNull, reason: '$k');
      }
    });
  });
}

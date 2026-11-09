/// Messages de la session de télécommande (RemoteMessage, port 6466).
library;

import 'dart:typed_data';

import 'proto_codec.dart';

/// Numéros de champ de RemoteMessage.
abstract final class RemoteField {
  static const configure = 1;
  static const setActive = 2;
  static const error = 3;
  static const pingRequest = 8;
  static const pingResponse = 9;
  static const keyInject = 10;
  static const imeKeyInject = 20;
  static const imeBatchEdit = 21;
  static const imeShowRequest = 22;
  static const start = 40;
  static const setVolumeLevel = 50;
  static const appLinkLaunch = 90;
}

/// Bitmask des fonctionnalités négociées avec le téléviseur.
abstract final class RemoteFeature {
  static const ping = 1;
  static const key = 2;
  static const ime = 4;
  static const voice = 8;
  static const power = 32;
  static const volume = 64;
  static const appLink = 512;

  static const wanted = ping | key | ime | power | volume | appLink;
}

abstract final class RemoteMessages {
  static Uint8List _wrap(int field, ProtoWriter body) =>
      (ProtoWriter()..message(field, body)).toBytes();

  /// Réponse à remote_configure.
  static Uint8List configure(int features) => _wrap(
      RemoteField.configure,
      ProtoWriter()
        ..varint(1, features)
        ..message(
            2,
            ProtoWriter()
              ..string(1, 'Family Remote')
              ..string(2, 'FamilyRemote')
              ..varint(3, 1)
              ..string(4, '1')
              ..string(5, 'atvremote')
              ..string(6, '1.0.0')));

  static Uint8List setActive(int features) =>
      _wrap(RemoteField.setActive, ProtoWriter()..varint(1, features));

  static Uint8List pingResponse(int val1) =>
      _wrap(RemoteField.pingResponse, ProtoWriter()..varint(1, val1));

  static Uint8List keyInject(int keyCode, int direction) => _wrap(
      RemoteField.keyInject,
      ProtoWriter()
        ..varint(1, keyCode)
        ..varint(2, direction));

  /// Remplace le contenu du champ texte ouvert sur la TV par [text].
  static Uint8List imeBatchEdit({
    required int imeCounter,
    required int fieldCounter,
    required String text,
  }) {
    // Position du curseur = fin du texte (comme l'implémentation de référence).
    final cursor = text.length;
    return _wrap(
        RemoteField.imeBatchEdit,
        ProtoWriter()
          ..varint(1, imeCounter)
          ..varint(2, fieldCounter)
          ..message(
              3,
              ProtoWriter()
                ..varint(1, 1)
                ..message(
                    2,
                    ProtoWriter()
                      ..varint(1, cursor)
                      ..varint(2, cursor)
                      ..string(3, text))));
  }

  static Uint8List appLink(String link) =>
      _wrap(RemoteField.appLinkLaunch, ProtoWriter()..string(1, link));
}

/// Message reçu du téléviseur, décodé dans ce qui nous intéresse.
sealed class RemoteIncoming {
  const RemoteIncoming();

  factory RemoteIncoming.parse(Uint8List data) {
    final m = ProtoMessage.parse(data);
    if (m.messageField(RemoteField.pingRequest) case final p?) {
      return PingRequest(p.intField(1) ?? 0);
    }
    if (m.messageField(RemoteField.configure) case final c?) {
      final info = c.messageField(2);
      return ConfigureRequest(
        features: c.intField(1) ?? 0,
        model: info?.stringField(1),
        vendor: info?.stringField(2),
      );
    }
    if (m.has(RemoteField.setActive)) return const SetActiveRequest();
    if (m.messageField(RemoteField.start) case final s?) {
      return StartNotice(started: (s.intField(1) ?? 0) != 0);
    }
    if (m.messageField(RemoteField.setVolumeLevel) case final v?) {
      return VolumeNotice(
        max: v.intField(6) ?? 0,
        level: v.intField(7) ?? 0,
        muted: (v.intField(8) ?? 0) != 0,
      );
    }
    if (m.messageField(RemoteField.imeKeyInject) case final k?) {
      final app = k.messageField(1);
      final field = k.messageField(2);
      return ImeNotice(
        imeCounter: app?.intField(1),
        fieldCounter: field?.intField(1),
        appPackage: app?.stringField(12),
      );
    }
    if (m.messageField(RemoteField.imeBatchEdit) case final b?) {
      return ImeNotice(imeCounter: b.intField(1), fieldCounter: b.intField(2));
    }
    if (m.messageField(RemoteField.error) case final e?) {
      return RemoteErrorNotice(e.stringField(2) ?? 'erreur ${e.intField(1)}');
    }
    return const OtherMessage();
  }
}

class PingRequest extends RemoteIncoming {
  const PingRequest(this.val1);
  final int val1;
}

class ConfigureRequest extends RemoteIncoming {
  const ConfigureRequest({required this.features, this.model, this.vendor});
  final int features;
  final String? model;
  final String? vendor;
}

class SetActiveRequest extends RemoteIncoming {
  const SetActiveRequest();
}

class StartNotice extends RemoteIncoming {
  const StartNotice({required this.started});
  final bool started;
}

class VolumeNotice extends RemoteIncoming {
  const VolumeNotice({required this.max, required this.level, required this.muted});
  final int max;
  final int level;
  final bool muted;
}

class ImeNotice extends RemoteIncoming {
  const ImeNotice({this.imeCounter, this.fieldCounter, this.appPackage});
  final int? imeCounter;
  final int? fieldCounter;
  final String? appPackage;
}

class RemoteErrorNotice extends RemoteIncoming {
  const RemoteErrorNotice(this.message);
  final String message;
}

class OtherMessage extends RemoteIncoming {
  const OtherMessage();
}

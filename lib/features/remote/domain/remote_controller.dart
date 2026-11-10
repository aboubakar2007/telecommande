import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/protocol/atv/atv_remote_client.dart';
import '../../../core/protocol/atv/key_codes.dart';
import '../../../core/protocol/tv_protocol.dart';
import '../../../core/storage/identity_store.dart';
import '../../../shared/models/tv_device.dart';
import '../../devices/data/device_repository.dart';

/// État de la session de télécommande vue par l'interface.
class RemoteSession {
  const RemoteSession({
    this.device,
    this.connection = const TvConnectionState.disconnected(),
    this.volume,
  });

  final TvDevice? device;
  final TvConnectionState connection;
  final TvVolume? volume;

  RemoteSession copyWith({TvConnectionState? connection, TvVolume? volume}) => RemoteSession(
        device: device,
        connection: connection ?? this.connection,
        volume: volume ?? this.volume,
      );
}

/// Point d'entrée unique de l'UI vers le téléviseur.
class RemoteController extends Notifier<RemoteSession> {
  AtvRemoteClient? _client;
  final List<StreamSubscription<Object?>> _subs = [];

  @override
  RemoteSession build() {
    ref.onDispose(_release);
    return const RemoteSession();
  }

  Future<void> _release() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    final c = _client;
    _client = null;
    await c?.dispose();
  }

  /// Se connecte à un téléviseur déjà associé.
  ///
  /// Lève [TvNotPairedException] si le téléviseur ne reconnaît pas ce téléphone.
  Future<void> connectTo(TvDevice device) async {
    await _release();
    state = RemoteSession(
      device: device,
      connection: const TvConnectionState(TvConnectionStatus.connecting),
    );
    final identity = await ref.read(identityProvider.future);
    final client = AtvRemoteClient(host: device.host, port: device.remotePort, identity: identity);
    _client = client;
    _subs
      ..add(client.states.listen((s) => state = state.copyWith(connection: s)))
      ..add(client.volumes.listen((v) => state = state.copyWith(volume: v)));
    try {
      await client.connect();
      await ref.read(savedDevicesProvider.notifier).upsert(device.copyWith(paired: true));
    } on TvNotPairedException {
      await ref.read(savedDevicesProvider.notifier).markUnpaired(device.id);
      rethrow;
    }
  }

  Future<void> reconnect() async {
    final d = state.device;
    if (d != null) await connectTo(d);
  }

  Future<void> disconnect() async {
    await _release();
    state = RemoteSession(device: state.device);
  }

  TvProtocol _requireConnected() {
    final c = _client;
    if (c == null || !state.connection.isConnected) throw const TvNotConnectedException();
    return c;
  }

  Future<void> press(TvKey key, {KeyPress press = KeyPress.short}) =>
      _requireConnected().sendKey(key, press: press);

  Future<void> sendText(String text) => _requireConnected().sendText(text);

  Future<void> launchApp(String link) => _requireConnected().launchApp(link);

  /// Synchronise le champ texte du téléviseur avec [text] (saisie en direct).
  ///
  /// 1. Si le téléviseur a signalé un champ texte : le contenu est remplacé
  ///    d'un coup (méthode IME, gère accents et majuscules).
  /// 2. Sinon : secours lettre par lettre via les touches (Effacer + lettres),
  ///    à partir de la différence avec [previous].
  Future<void> syncText(String text, String previous) async {
    _requireConnected();
    final c = _client!;
    if (c.hasTextField) {
      await c.sendText(text);
      return;
    }
    var common = 0;
    while (common < text.length && common < previous.length && text[common] == previous[common]) {
      common++;
    }
    for (var i = 0; i < previous.length - common; i++) {
      await c.sendKeyCode(androidKeyCodes[TvKey.delete]!);
    }
    for (final ch in text.substring(common).split('')) {
      final code = charKeyCode(ch);
      if (code != null) await c.sendKeyCode(code);
    }
  }
}

final remoteControllerProvider =
    NotifierProvider<RemoteController, RemoteSession>(RemoteController.new);

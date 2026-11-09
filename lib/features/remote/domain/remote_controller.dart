import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/protocol/tv_protocol.dart';
import '../../../shared/models/tv_device.dart';

/// État de la session de télécommande vue par l'interface.
class RemoteSession {
  const RemoteSession({this.device, this.connection = const TvConnectionState.disconnected()});

  final TvDevice? device;
  final TvConnectionState connection;

  RemoteSession copyWith({TvDevice? device, TvConnectionState? connection}) => RemoteSession(
        device: device ?? this.device,
        connection: connection ?? this.connection,
      );
}

/// Point d'entrée unique de l'UI vers le téléviseur.
///
/// Phase 2 : aucun protocole n'est encore branché ([_protocol] reste null),
/// donc chaque commande lève [TvNotConnectedException] : on n'affiche jamais
/// un faux succès. Le protocole Android TV Remote v2 sera branché en phase 3.
class RemoteController extends Notifier<RemoteSession> {
  TvProtocol? _protocol;
  StreamSubscription<TvConnectionState>? _sub;

  @override
  RemoteSession build() {
    ref.onDispose(() => _sub?.cancel());
    return const RemoteSession();
  }

  /// Attache un protocole connecté (utilisé à partir de la phase 3).
  void attach(TvDevice device, TvProtocol protocol) {
    _sub?.cancel();
    _protocol = protocol;
    state = RemoteSession(device: device);
    _sub = protocol.states.listen((s) => state = state.copyWith(connection: s));
  }

  Future<void> press(TvKey key, {KeyPress press = KeyPress.short}) {
    final p = _requireConnected();
    return p.sendKey(key, press: press);
  }

  Future<void> sendText(String text) => _requireConnected().sendText(text);

  Future<void> launchApp(String link) => _requireConnected().launchApp(link);

  TvProtocol _requireConnected() {
    final p = _protocol;
    if (p == null || !state.connection.isConnected) {
      throw const TvNotConnectedException();
    }
    return p;
  }
}

final remoteControllerProvider =
    NotifierProvider<RemoteController, RemoteSession>(RemoteController.new);

/// Session de télécommande Android TV Remote v2 (port 6466).
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../tv_protocol.dart';
import 'certificate_manager.dart';
import 'key_codes.dart';
import 'pairing_client.dart';
import 'proto_codec.dart';
import 'remote_messages.dart';

class TvVolume {
  const TvVolume(this.level, this.max, this.muted);
  final int level;
  final int max;
  final bool muted;
}

class AtvRemoteClient implements TvProtocol {
  AtvRemoteClient({
    required this.host,
    required this.identity,
    this.port = 6466,
    this.autoReconnect = true,
  });

  final String host;
  final int port;
  final ClientIdentity identity;
  final bool autoReconnect;

  /// Le téléviseur coupe après 16 s sans échange (il ping toutes les 5 s).
  static const idleTimeout = Duration(seconds: 16);

  final _states = StreamController<TvConnectionState>.broadcast();
  final _volumes = StreamController<TvVolume>.broadcast();

  SecureSocket? _socket;
  StreamSubscription<Uint8List>? _sub;
  Timer? _idle;
  Timer? _retry;
  int _retryCount = 0;
  bool _wantConnected = false;
  Completer<void>? _ready;

  int _features = RemoteFeature.wanted;
  int? _imeCounter;
  int? _fieldCounter;
  TvConnectionState _state = const TvConnectionState.disconnected();

  String? vendor;
  String? model;
  String? currentApp;

  @override
  Stream<TvConnectionState> get states => _states.stream;
  TvConnectionState get state => _state;
  Stream<TvVolume> get volumes => _volumes.stream;

  void _emit(TvConnectionState s) {
    _state = s;
    if (!_states.isClosed) _states.add(s);
  }

  @override
  Future<void> connect() async {
    _wantConnected = true;
    _retry?.cancel();
    await _open();
  }

  Future<void> _open() async {
    _emit(const TvConnectionState(TvConnectionStatus.connecting));
    try {
      // 1) TCP : échoue si le téléviseur est éteint / sur un autre réseau.
      final raw = await Socket.connect(host, port, timeout: const Duration(seconds: 8));
      // 2) TLS : le téléviseur rejette un certificat qu'il ne connaît pas.
      final SecureSocket socket;
      try {
        socket = await SecureSocket.secure(
          raw,
          context: PairingClient.securityContext(identity),
          onBadCertificate: (_) => true,
        ).timeout(const Duration(seconds: 8));
      } on Object {
        raw.destroy();
        throw const _NotPaired();
      }
      _socket = socket;
      _ready = Completer<void>();
      final decoder = FrameDecoder();
      _sub = socket.listen(
        (chunk) {
          try {
            decoder.add(chunk).forEach(_handle);
          } on FormatException {
            _drop('Flux corrompu');
          }
        },
        onError: (Object e) => _drop('Erreur réseau : $e'),
        onDone: () => _drop('Connexion fermée par le téléviseur'),
        cancelOnError: true,
      );
      _touch();
      // Connecté quand la négociation (configure + set_active) est terminée.
      await _ready!.future.timeout(const Duration(seconds: 8));
      _retryCount = 0;
      _emit(const TvConnectionState(TvConnectionStatus.connected));
    } on _NotPaired {
      // Certificat non reconnu : ce téléphone n'est pas (ou plus) associé.
      await _teardown();
      _wantConnected = false;
      _emit(const TvConnectionState(TvConnectionStatus.error,
          message: 'Ce téléphone n’est pas associé au téléviseur.'));
      throw const TvNotPairedException();
    } on Object catch (e) {
      await _teardown();
      _emit(TvConnectionState(TvConnectionStatus.error, message: _describe(e)));
      _scheduleRetry();
      if (e is SocketException || e is TimeoutException) return;
      rethrow;
    }
  }

  String _describe(Object e) => switch (e) {
        SocketException() => 'Téléviseur injoignable (éteint ou sur un autre réseau ?)',
        TimeoutException() => 'Le téléviseur ne répond pas',
        _ => e.toString(),
      };

  void _handle(Uint8List raw) {
    _touch();
    final msg = RemoteIncoming.parse(raw);
    switch (msg) {
      case PingRequest(:final val1):
        _send(RemoteMessages.pingResponse(val1));
      case ConfigureRequest(:final features, vendor: final v, model: final m):
        vendor = v;
        model = m;
        _features = RemoteFeature.wanted & features;
        _send(RemoteMessages.configure(_features));
      case SetActiveRequest():
        _send(RemoteMessages.setActive(_features));
        if (_ready != null && !_ready!.isCompleted) _ready!.complete();
      case VolumeNotice(:final level, :final max, :final muted):
        _volumes.add(TvVolume(level, max, muted));
      case ImeNotice(:final imeCounter, :final fieldCounter, :final appPackage):
        _imeCounter = imeCounter ?? _imeCounter;
        _fieldCounter = fieldCounter ?? _fieldCounter;
        currentApp = appPackage ?? currentApp;
      case RemoteErrorNotice(:final message):
        _emit(TvConnectionState(TvConnectionStatus.connected, message: message));
      case StartNotice() || OtherMessage():
        break;
    }
  }

  void _touch() {
    _idle?.cancel();
    _idle = Timer(idleTimeout, () => _drop('Plus de réponse du téléviseur'));
  }

  void _send(Uint8List message) {
    final s = _socket;
    if (s == null) throw const TvNotConnectedException();
    s.add(frame(message));
    _touch();
  }

  Future<void> _drop(String reason) async {
    if (_socket == null) return;
    await _teardown();
    if (_ready != null && !_ready!.isCompleted) {
      // Coupé avant la fin de la négociation : le téléviseur refuse ce
      // certificat (comportement observé sur Sony Bravia).
      _ready!.completeError(const _NotPaired());
      return;
    }
    _emit(TvConnectionState(TvConnectionStatus.disconnected, message: reason));
    _scheduleRetry();
  }

  void _scheduleRetry() {
    if (!autoReconnect || !_wantConnected) return;
    _retry?.cancel();
    // 1 s, 2 s, 4 s… plafonné à 30 s.
    final delay = Duration(seconds: (1 << _retryCount.clamp(0, 5)).clamp(1, 30));
    _retryCount++;
    _retry = Timer(delay, () => _open().catchError((_) {}));
  }

  Future<void> _teardown() async {
    _idle?.cancel();
    await _sub?.cancel();
    _sub = null;
    _socket?.destroy();
    _socket = null;
  }

  @override
  Future<void> disconnect() async {
    _wantConnected = false;
    _retry?.cancel();
    await _teardown();
    _emit(const TvConnectionState.disconnected());
  }

  Future<void> dispose() async {
    await disconnect();
    await _states.close();
    await _volumes.close();
  }

  void _requireConnected() {
    if (!_state.isConnected || _socket == null) throw const TvNotConnectedException();
  }

  @override
  Future<void> sendKey(TvKey key, {KeyPress press = KeyPress.short}) async {
    _requireConnected();
    _send(RemoteMessages.keyInject(androidKeyCodes[key]!, directionCode(press)));
  }

  /// Vrai si le téléviseur a signalé un champ texte (compteurs IME connus).
  bool get hasTextField => _imeCounter != null && _fieldCounter != null;

  /// Remplace le contenu du champ texte ouvert sur le téléviseur par [text].
  @override
  Future<void> sendText(String text) async {
    _requireConnected();
    final ime = _imeCounter;
    final field = _fieldCounter;
    if (ime == null || field == null) {
      throw const TvFeatureException('Aucun champ texte ouvert sur le téléviseur.');
    }
    _send(RemoteMessages.imeBatchEdit(imeCounter: ime, fieldCounter: field, text: text));
  }

  /// Envoie un code touche Android brut (saisie lettre par lettre).
  Future<void> sendKeyCode(int keyCode) async {
    _requireConnected();
    _send(RemoteMessages.keyInject(keyCode, directionCode(KeyPress.short)));
  }

  @override
  Future<void> launchApp(String appLink) async {
    _requireConnected();
    if (_features & RemoteFeature.appLink == 0) {
      throw const TvFeatureException('Le téléviseur ne permet pas de lancer des applications.');
    }
    _send(RemoteMessages.appLink(appLink));
  }
}

/// Signal interne : le téléviseur a refusé le certificat de ce téléphone.
class _NotPaired implements Exception {
  const _NotPaired();
}

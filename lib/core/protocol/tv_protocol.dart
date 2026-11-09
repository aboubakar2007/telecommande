/// Abstraction du protocole de communication avec un téléviseur.
///
/// L'interface graphique ne dépend QUE de ce fichier. L'implémentation
/// Android TV Remote v2 (core/protocol/atv) arrive en phase 3 ; d'autres
/// protocoles (ex. Sony IRCC) pourront être ajoutés sans toucher à l'UI.
library;

/// Touches logiques exposées à l'interface.
enum TvKey {
  power,
  up,
  down,
  left,
  right,
  ok,
  back,
  home,
  menu,
  volumeUp,
  volumeDown,
  mute,
  playPause,
  play,
  pause,
  fastForward,
  rewind,
  next,
  previous,
  channelUp,
  channelDown,
  settings,
  info,
  delete,
  enter,
}

/// Type d'appui envoyé au téléviseur.
enum KeyPress { short, longStart, longEnd }

enum TvConnectionStatus { disconnected, connecting, connected, error }

class TvConnectionState {
  const TvConnectionState(this.status, {this.message});

  const TvConnectionState.disconnected()
      : status = TvConnectionStatus.disconnected,
        message = null;

  final TvConnectionStatus status;
  final String? message;

  bool get isConnected => status == TvConnectionStatus.connected;
}

/// Contrat que toute implémentation de protocole TV doit respecter.
abstract interface class TvProtocol {
  Stream<TvConnectionState> get states;

  Future<void> connect();
  Future<void> disconnect();

  Future<void> sendKey(TvKey key, {KeyPress press = KeyPress.short});
  Future<void> sendText(String text);
  Future<void> launchApp(String appLink);
}

/// Erreur levée quand une action est demandée sans connexion active.
class TvNotConnectedException implements Exception {
  const TvNotConnectedException();
  @override
  String toString() => 'Aucun téléviseur connecté.';
}

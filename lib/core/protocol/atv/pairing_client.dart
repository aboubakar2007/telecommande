/// Client d'association Android TV Remote v2 (port 6467).
///
/// Utilisation :
///   final c = PairingClient(host: ip, identity: id, clientName: 'Tél. de Karim');
///   await c.start();            // le téléviseur affiche un code
///   await c.finish('A1B2C3');   // le code saisi par l'utilisateur
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'certificate_manager.dart';
import 'pairing_messages.dart';
import 'pairing_secret.dart';
import 'proto_codec.dart';

class PairingException implements Exception {
  const PairingException(this.message);
  final String message;
  @override
  String toString() => message;
}

class PairingClient {
  PairingClient({
    required this.host,
    required this.identity,
    required this.clientName,
    this.port = 6467,
    this.timeout = const Duration(seconds: 10),
  });

  final String host;
  final int port;
  final ClientIdentity identity;
  final String clientName;
  final Duration timeout;

  SecureSocket? _socket;
  StreamIterator<Uint8List>? _messages;

  static SecurityContext securityContext(ClientIdentity id) => SecurityContext(withTrustedRoots: false)
    ..useCertificateChainBytes(id.certificatePem.codeUnits)
    ..usePrivateKeyBytes(id.privateKeyPem.codeUnits);

  /// Ouvre la connexion et déclenche l'affichage du code sur le téléviseur.
  Future<void> start() async {
    try {
      _socket = await SecureSocket.connect(
        host,
        port,
        context: securityContext(identity),
        // Le téléviseur présente un certificat auto-signé : on l'accepte,
        // son authenticité est garantie par le code affiché à l'écran
        // (il entre dans le calcul du secret).
        onBadCertificate: (_) => true,
        timeout: timeout,
      );
    } on SocketException catch (e) {
      throw PairingException('Impossible de joindre le téléviseur ($host:$port) : ${e.message}');
    } on HandshakeException catch (e) {
      throw PairingException('Échec de la connexion sécurisée : ${e.message}');
    }

    final decoder = FrameDecoder();
    _messages = StreamIterator(_socket!.expand(decoder.add));

    await _exchange(PairingMessages.pairingRequest(clientName), PoloReply.pairingRequestAck);
    await _exchange(PairingMessages.options(), PoloReply.options);
    await _exchange(PairingMessages.configuration(), PoloReply.configurationAck);
  }

  /// Envoie le secret calculé à partir du [code] affiché sur le téléviseur.
  Future<void> finish(String code) async {
    final socket = _socket;
    if (socket == null) throw const PairingException('Association non démarrée.');
    final serverCert = socket.peerCertificate;
    if (serverCert == null) throw const PairingException('Certificat du téléviseur absent.');

    final client = CertificateManager.publicNumbersFromCertPem(identity.certificatePem);
    final server = CertificateManager.publicNumbersFromCertDer(serverCert.der);

    final secret = computePairingSecret(
      clientModulus: client.modulus,
      clientExponent: client.exponent,
      serverModulus: server.modulus,
      serverExponent: server.exponent,
      code: code,
    );
    await _exchange(PairingMessages.secret(secret), PoloReply.secretAck);
    await close();
  }

  Future<void> _exchange(Uint8List message, PoloReply expected) async {
    _socket!.add(frame(message));
    await _socket!.flush();

    final it = _messages!;
    final bool hasNext;
    try {
      hasNext = await it.moveNext().timeout(timeout);
    } on TimeoutException {
      throw const PairingException('Le téléviseur ne répond pas.');
    }
    if (!hasNext) throw const PairingException('Connexion fermée par le téléviseur.');

    final reply = PoloResponse.parse(it.current);
    if (!reply.ok) {
      throw PairingException(switch (reply.status) {
        PoloStatus.badSecret => 'Code refusé par le téléviseur.',
        PoloStatus.badConfiguration => 'Configuration refusée par le téléviseur.',
        _ => 'Erreur du téléviseur (statut ${reply.status}).',
      });
    }
    if (reply.reply != expected) {
      throw PairingException('Réponse inattendue : ${reply.reply.name} au lieu de ${expected.name}.');
    }
  }

  Future<void> close() async {
    await _messages?.cancel();
    _messages = null;
    _socket?.destroy();
    _socket = null;
  }
}

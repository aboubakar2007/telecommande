import 'dart:convert';
import 'dart:isolate';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../protocol/atv/certificate_manager.dart';

/// Identité (certificat + clé privée) de CE téléphone.
///
/// Générée une seule fois, conservée dans le Keystore (Android) /
/// Keychain (iOS). La clé privée n'est jamais journalisée.
class IdentityStore {
  IdentityStore([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _key = 'client_identity_v1';

  Future<ClientIdentity> loadOrCreate() async {
    final saved = await _storage.read(key: _key);
    if (saved != null) {
      return ClientIdentity.fromJson(jsonDecode(saved) as Map<String, Object?>);
    }
    // La génération RSA 2048 prend 1 à 3 s : hors du thread de l'interface.
    final id = await Isolate.run(CertificateManager.generate);
    await _storage.write(key: _key, value: jsonEncode(id.toJson()));
    return id;
  }
}

final identityProvider = FutureProvider<ClientIdentity>((ref) => IdentityStore().loadOrCreate());

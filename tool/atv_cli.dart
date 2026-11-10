// Outil de test du protocole depuis un PC (sans téléphone).
//
//   dart run tool/atv_cli.dart pair 192.168.100.3
//       → le téléviseur affiche un code ; l'écrire dans tool/.code
//         (ou le passer en 3e argument : pair <ip> <code> si déjà affiché)
//   dart run tool/atv_cli.dart key 192.168.100.3 home down ok
//   dart run tool/atv_cli.dart info 192.168.100.3
//   dart run tool/atv_cli.dart text 192.168.100.3 "mot"   (champ texte ouvert sur la TV)
import 'dart:convert';
import 'dart:io';

import 'package:family_remote/core/protocol/atv/atv_remote_client.dart';
import 'package:family_remote/core/protocol/atv/certificate_manager.dart';
import 'package:family_remote/core/protocol/atv/pairing_client.dart';
import 'package:family_remote/core/protocol/tv_protocol.dart';

final _idFile = File('tool/.identity.json');
final _codeFile = File('tool/.code');

ClientIdentity _identity() {
  if (_idFile.existsSync()) {
    return ClientIdentity.fromJson(jsonDecode(_idFile.readAsStringSync()) as Map<String, Object?>);
  }
  stdout.writeln('Génération du certificat client…');
  final id = CertificateManager.generate();
  _idFile.writeAsStringSync(jsonEncode(id.toJson()));
  return id;
}

Future<void> main(List<String> args) async {
  if (args.length < 2) {
    stderr.writeln('usage: pair <ip> | key <ip> <touches…> | info <ip>');
    exit(64);
  }
  final cmd = args[0];
  final ip = args[1];
  final id = _identity();

  switch (cmd) {
    case 'pair':
      if (_codeFile.existsSync()) _codeFile.deleteSync();
      final c = PairingClient(host: ip, identity: id, clientName: 'Family Remote (PC test)');
      await c.start();
      stdout.writeln('CODE_AFFICHE : le téléviseur affiche un code. En attente de tool/.code …');
      String? code;
      for (var i = 0; i < 1200 && code == null; i++) {
        if (_codeFile.existsSync()) code = _codeFile.readAsStringSync().trim();
        if (code == null) await Future<void>.delayed(const Duration(milliseconds: 500));
      }
      if (code == null) {
        stderr.writeln('Aucun code reçu (10 min).');
        await c.close();
        exit(1);
      }
      await c.finish(code);
      stdout.writeln('ASSOCIATION_OK');

    case 'key' || 'info' || 'text':
      final r = AtvRemoteClient(host: ip, identity: id, autoReconnect: false);
      r.states.listen((s) => stdout.writeln('état: ${s.status.name} ${s.message ?? ''}'));
      r.volumes.listen((v) => stdout.writeln('volume: ${v.level}/${v.max} muet=${v.muted}'));
      await r.connect();
      stdout.writeln('TV: ${r.vendor} ${r.model}');
      if (cmd == 'key') {
        for (final name in args.skip(2)) {
          final key = TvKey.values.byName(name);
          await r.sendKey(key);
          stdout.writeln('→ $name');
          await Future<void>.delayed(const Duration(milliseconds: 600));
        }
      } else if (cmd == 'text') {
        // Laisse au téléviseur le temps d'annoncer son champ texte.
        await Future<void>.delayed(const Duration(seconds: 2));
        stdout.writeln('champ texte signalé : ${r.hasTextField}  appli : ${r.currentApp}');
        if (r.hasTextField) {
          await r.sendText(args[2]);
          stdout.writeln('→ texte envoyé (IME)');
        }
        await Future<void>.delayed(const Duration(seconds: 2));
      } else {
        await Future<void>.delayed(const Duration(seconds: 3));
      }
      await r.dispose();
  }
  exit(0);
}

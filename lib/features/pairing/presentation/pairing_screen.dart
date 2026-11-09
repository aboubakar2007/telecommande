import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/protocol/atv/pairing_client.dart';
import '../../../core/protocol/atv/pairing_secret.dart';
import '../../../core/storage/identity_store.dart';
import '../../../shared/models/tv_device.dart';
import '../../remote/domain/remote_controller.dart';
import '../../settings/domain/settings_controller.dart';

enum _Step { preparing, waitingCode, sending, connecting, error }

/// Association réelle avec le téléviseur (port 6467).
///
/// À l'ouverture : connexion + demande d'association → le téléviseur affiche
/// un code hexadécimal à 6 caractères que l'utilisateur saisit ici.
class PairingScreen extends ConsumerStatefulWidget {
  const PairingScreen({super.key, required this.device});

  final TvDevice device;

  @override
  ConsumerState<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends ConsumerState<PairingScreen> {
  final _codeCtrl = TextEditingController();
  PairingClient? _client;
  _Step _step = _Step.preparing;
  String? _error;
  String _status = 'Préparation du certificat du téléphone…';

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _client?.close();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    await _client?.close();
    setState(() {
      _step = _Step.preparing;
      _error = null;
      _status = 'Préparation du certificat du téléphone…';
      _codeCtrl.clear();
    });
    try {
      final identity = await ref.read(identityProvider.future);
      final settings = await ref.read(settingsProvider.future);
      if (!mounted) return;
      setState(() => _status = 'Connexion au téléviseur…');
      final client = PairingClient(
        host: widget.device.host,
        port: widget.device.pairingPort,
        identity: identity,
        clientName: settings.phoneName,
      );
      _client = client;
      await client.start();
      if (mounted) setState(() => _step = _Step.waitingCode);
    } on Object catch (e) {
      _fail(e);
    }
  }

  Future<void> _submit() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length != 6) {
      setState(() => _error = 'Le code contient 6 caractères.');
      return;
    }
    setState(() {
      _step = _Step.sending;
      _error = null;
    });
    try {
      await _client!.finish(code);
      _client = null;
      if (!mounted) return;
      setState(() => _step = _Step.connecting);
      await ref.read(remoteControllerProvider.notifier).connectTo(widget.device.copyWith(paired: true));
      if (mounted) context.go(Routes.remote);
    } on InvalidPairingCodeException catch (e) {
      // Code mal saisi : la session d'association reste ouverte, on peut réessayer.
      setState(() {
        _step = _Step.waitingCode;
        _error = e.message;
      });
    } on Object catch (e) {
      _fail(e);
    }
  }

  void _fail(Object e) {
    if (!mounted) return;
    setState(() {
      _step = _Step.error;
      _error = e.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Association')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.link_rounded, size: 56, color: AppColors.accent),
          const SizedBox(height: 16),
          Text(
            widget.device.name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          Text(widget.device.host,
              textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 28),
          ...switch (_step) {
            _Step.preparing || _Step.sending || _Step.connecting => [
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 16),
                Text(
                  switch (_step) {
                    _Step.sending => 'Vérification du code…',
                    _Step.connecting => 'Association réussie ! Connexion…',
                    _ => _status,
                  },
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            _Step.waitingCode => _codeForm(),
            _Step.error => [
                const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 40),
                const SizedBox(height: 12),
                Text(_error ?? 'Erreur', textAlign: TextAlign.center),
                const SizedBox(height: 8),
                const Text(
                  'Vérifiez que le téléviseur est allumé et sur le même Wi-Fi que ce téléphone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                FilledButton(onPressed: _start, child: const Text('Réessayer')),
              ],
          },
        ],
      ),
    );
  }

  List<Widget> _codeForm() => [
        const Text(
          'Saisissez le code affiché sur l’écran du téléviseur.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _codeCtrl,
          autofocus: true,
          textAlign: TextAlign.center,
          maxLength: 6,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(fontSize: 28, letterSpacing: 10, fontWeight: FontWeight.w700),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[0-9a-fA-F]')),
            TextInputFormatter.withFunction((o, n) => n.copyWith(text: n.text.toUpperCase())),
          ],
          decoration: InputDecoration(hintText: '······', counterText: '', errorText: _error),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 20),
        FilledButton(onPressed: _submit, child: const Text('Associer')),
        const SizedBox(height: 8),
        TextButton(onPressed: _start, child: const Text('Afficher un nouveau code')),
      ];
}

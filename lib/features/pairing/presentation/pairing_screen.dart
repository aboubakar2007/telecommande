import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_theme.dart';
import '../../../shared/models/tv_device.dart';

/// Association avec le téléviseur (code hexadécimal à 6 caractères).
///
/// Phase 2 : interface seule. Le protocole d'association réel (port 6467)
/// est branché en phase 3c — aucun succès n'est simulé ici.
class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key, required this.device});

  final TvDevice device;

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final _codeCtrl = TextEditingController();

  static final _hex6 = RegExp(r'^[0-9A-F]{6}$');

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  void _validate() {
    final code = _codeCtrl.text.toUpperCase();
    final msg = _hex6.hasMatch(code)
        ? 'Association pas encore disponible : elle arrive en phase 3.'
        : 'Le code doit contenir 6 caractères (0-9, A-F).';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
          Text(widget.device.host, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 28),
          const Text(
            'Saisissez le code affiché sur l’écran du téléviseur.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _codeCtrl,
            textAlign: TextAlign.center,
            maxLength: 6,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(fontSize: 28, letterSpacing: 10, fontWeight: FontWeight.w700),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9a-fA-F]'))],
            decoration: const InputDecoration(hintText: '······', counterText: ''),
            onSubmitted: (_) => _validate(),
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: _validate, child: const Text('Associer')),
        ],
      ),
    );
  }
}

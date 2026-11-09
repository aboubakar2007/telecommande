import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/protocol/tv_protocol.dart';
import '../../../shared/widgets/remote_button.dart';
import '../domain/remote_controller.dart';

/// Saisie de texte vers le téléviseur.
///
/// Fonctionne uniquement quand un champ texte est ouvert sur la TV
/// (ex. recherche YouTube) : c'est une contrainte du protocole.
class KeyboardScreen extends ConsumerStatefulWidget {
  const KeyboardScreen({super.key});

  @override
  ConsumerState<KeyboardScreen> createState() => _KeyboardScreenState();
}

class _KeyboardScreenState extends ConsumerState<KeyboardScreen> {
  final _ctrl = TextEditingController();
  bool _obscure = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _ctrl.text;
    if (text.isEmpty) return;
    try {
      await ref.read(remoteControllerProvider.notifier).sendText(text);
      _ctrl.clear();
    } on Exception catch (e) {
      if (mounted) showNotConnected(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clavier')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Ouvrez d’abord un champ de saisie sur le téléviseur (recherche, mot de passe…).',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _ctrl,
                autofocus: true,
                obscureText: _obscure,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: 'Texte à envoyer',
                  suffixIcon: IconButton(
                    tooltip: _obscure ? 'Afficher' : 'Masquer (mot de passe)',
                    icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.send_rounded),
                label: const Text('Envoyer au téléviseur'),
              ),
              const SizedBox(height: 24),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  RemoteButton(tvKey: TvKey.delete, icon: Icons.backspace_outlined, label: 'Effacer', repeat: true),
                  RemoteButton(tvKey: TvKey.enter, icon: Icons.keyboard_return_rounded, label: 'Valider'),
                  RemoteButton(tvKey: TvKey.back, icon: Icons.arrow_back_rounded, label: 'Retour'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

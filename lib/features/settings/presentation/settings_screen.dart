import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../domain/settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _editName(BuildContext context, WidgetRef ref, String current) async {
    final ctrl = TextEditingController(text: current);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nom du téléphone'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 30,
          decoration: const InputDecoration(hintText: 'Ex. Téléphone de Karim'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Enregistrer')),
        ],
      ),
    );
    ctrl.dispose();
    if (name != null) await ref.read(settingsProvider.notifier).setPhoneName(name);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: settings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (s) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.smartphone_rounded, color: AppColors.accent),
                title: const Text('Nom du téléphone'),
                subtitle: Text(s.phoneName, style: const TextStyle(color: AppColors.textSecondary)),
                trailing: const Icon(Icons.edit_rounded),
                onTap: () => _editName(context, ref, s.phoneName),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sensibilité du pavé tactile'),
                    Slider(
                      value: s.touchpadSensitivity,
                      onChanged: (v) => ref.read(settingsProvider.notifier).setSensitivity(v),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              child: SwitchListTile(
                title: const Text('Vibrations'),
                value: s.haptics,
                onChanged: (v) => ref.read(settingsProvider.notifier).setHaptics(v),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.devices_rounded, color: AppColors.accent),
                title: const Text('Téléviseurs enregistrés'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(Routes.devices),
              ),
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text('Family Remote 0.1.0 · usage familial local',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

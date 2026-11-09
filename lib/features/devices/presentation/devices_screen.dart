import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/models/tv_device.dart';
import '../../../shared/widgets/connection_badge.dart';
import '../../discovery/presentation/discovery_screen.dart';
import '../../remote/domain/remote_controller.dart';
import '../data/device_repository.dart';

/// Téléviseurs enregistrés sur ce téléphone.
class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  Future<void> _forget(BuildContext context, WidgetRef ref, TvDevice d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Oublier « ${d.name} » ?'),
        content: const Text(
          'Le téléviseur sera retiré de ce téléphone. Pour révoquer aussi l’accès côté téléviseur : '
          'Paramètres › Applications › Android TV Remote Service › Effacer les données.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Oublier')),
        ],
      ),
    );
    if (ok != true) return;
    final session = ref.read(remoteControllerProvider);
    if (session.device?.id == d.id) await ref.read(remoteControllerProvider.notifier).disconnect();
    await ref.read(savedDevicesProvider.notifier).remove(d.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedDevicesProvider);
    final session = ref.watch(remoteControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mes appareils')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.discovery),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Ajouter'),
      ),
      body: saved.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (s) => s.devices.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tv_off_rounded, size: 56, color: AppColors.textSecondary),
                      SizedBox(height: 16),
                      Text('Aucun téléviseur enregistré', style: TextStyle(fontSize: 18)),
                    ],
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                children: [
                  for (final d in s.devices)
                    Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: Icon(Icons.tv_rounded,
                            color: d.paired ? AppColors.accent : AppColors.textSecondary),
                        title: Text(d.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${d.host} · ${d.paired ? 'associé' : 'à associer'}',
                                style: const TextStyle(color: AppColors.textSecondary)),
                            if (session.device?.id == d.id) ...[
                              const SizedBox(height: 4),
                              ConnectionBadge(state: session.connection),
                            ],
                          ],
                        ),
                        onTap: () => openTv(context, ref, d),
                        trailing: IconButton(
                          tooltip: 'Oublier',
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: () => _forget(context, ref, d),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

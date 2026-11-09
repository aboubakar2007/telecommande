import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/protocol/tv_protocol.dart';
import '../../../shared/widgets/connection_badge.dart';
import '../../../shared/widgets/connection_banner.dart';
import '../../../shared/widgets/remote_button.dart';
import '../../remote/domain/remote_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(remoteControllerProvider);
    final device = session.device;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Remote'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const ConnectionBanner(),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.tv_rounded, color: AppColors.accent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          device?.name ?? 'Aucun téléviseur',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ),
                      ConnectionBadge(state: session.connection),
                    ],
                  ),
                  if (device != null) ...[
                    const SizedBox(height: 4),
                    Text(device.host, style: const TextStyle(color: AppColors.textSecondary)),
                  ],
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => context.push(Routes.discovery),
                    icon: const Icon(Icons.search_rounded),
                    label: Text(device == null ? 'Rechercher un téléviseur' : 'Changer de téléviseur'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Commandes rapides', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              RemoteButton(tvKey: TvKey.power, icon: Icons.power_settings_new_rounded, label: 'Power', iconColor: AppColors.danger),
              RemoteButton(tvKey: TvKey.home, icon: Icons.home_rounded, label: 'Accueil'),
              RemoteButton(tvKey: TvKey.mute, icon: Icons.volume_off_rounded, label: 'Muet'),
              RemoteButton(tvKey: TvKey.playPause, icon: Icons.play_arrow_rounded, label: 'Lecture/Pause'),
            ],
          ),
          const SizedBox(height: 24),
          _NavTile(
            icon: Icons.settings_remote_rounded,
            title: 'Télécommande',
            subtitle: 'Pavé directionnel, volume, multimédia',
            onTap: () => context.push(Routes.remote),
          ),
          _NavTile(
            icon: Icons.devices_rounded,
            title: 'Mes appareils',
            subtitle: 'Téléviseurs enregistrés',
            onTap: () => context.push(Routes.devices),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        leading: Icon(icon, color: AppColors.accent),
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

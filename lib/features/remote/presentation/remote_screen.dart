import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/protocol/tv_protocol.dart';
import '../../../shared/widgets/connection_badge.dart';
import '../../../shared/widgets/connection_banner.dart';
import '../../../shared/widgets/quick_text_bar.dart';
import '../../../shared/widgets/remote_button.dart';
import '../../../shared/widgets/touchpad_surface.dart';
import '../domain/remote_controller.dart';

class RemoteScreen extends ConsumerWidget {
  const RemoteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(remoteControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(session.device?.name ?? 'Télécommande'),
            ConnectionBadge(state: session.connection),
          ],
        ),
        toolbarHeight: 64,
        actions: [
          IconButton(
            tooltip: 'Clavier',
            icon: const Icon(Icons.keyboard_rounded),
            onPressed: () => context.push(Routes.keyboard),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  final dpad = (c.maxWidth * 0.72).clamp(220.0, 300.0);
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: Column(
                      children: [
                        const ConnectionBanner(),
                        const QuickTextBar(),
                        const SizedBox(height: 20),
                        // Ligne du haut : Power / Accueil / Menu
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            RemoteButton(
                              tvKey: TvKey.power,
                              icon: Icons.power_settings_new_rounded,
                              label: 'Power',
                              iconColor: AppColors.danger,
                            ),
                            RemoteButton(
                              tvKey: TvKey.home,
                              icon: Icons.home_rounded,
                              label: 'Accueil',
                            ),
                            RemoteButton(
                              tvKey: TvKey.menu,
                              icon: Icons.menu_rounded,
                              label: 'Menu',
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        _DPad(size: dpad),
                        const SizedBox(height: 28),
                        // Retour / volume / pavé tactile
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const RemoteButton(
                              tvKey: TvKey.back,
                              icon: Icons.arrow_back_rounded,
                              label: 'Retour',
                            ),
                            const _VolumeRocker(),
                            Column(
                              children: [
                                const RemoteButton(
                                  tvKey: TvKey.mute,
                                  icon: Icons.volume_off_rounded,
                                  label: 'Muet',
                                ),
                                const SizedBox(height: 16),
                                _ActionCircle(
                                  icon: Icons.touch_app_rounded,
                                  label: 'Pavé tactile',
                                  onTap: () => context.push(Routes.touchpad),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        // Multimédia
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            RemoteButton(
                              tvKey: TvKey.rewind,
                              icon: Icons.fast_rewind_rounded,
                              label: 'Retour rapide',
                              size: 56,
                              repeat: true,
                            ),
                            RemoteButton(
                              tvKey: TvKey.playPause,
                              icon: Icons.play_arrow_rounded,
                              label: 'Lecture/Pause',
                              size: 64,
                              color: AppColors.accent,
                            ),
                            RemoteButton(
                              tvKey: TvKey.fastForward,
                              icon: Icons.fast_forward_rounded,
                              label: 'Avance rapide',
                              size: 56,
                              repeat: true,
                            ),
                          ],
                        ),
                        if (session.volume case final v?) ...[
                          const SizedBox(height: 20),
                          _VolumeBar(
                            level: v.level,
                            max: v.max,
                            muted: v.muted,
                          ),
                        ],
                        const SizedBox(height: 28),
                        const _AppShortcuts(),
                        const SizedBox(height: 12),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Petit pavé tactile fixe en bas (hors du défilement pour ne pas
            // confondre glisser sur le pavé et faire défiler l'écran).
            Container(
              height: 150,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              decoration: const BoxDecoration(
                color: AppColors.background,
                border: Border(top: BorderSide(color: AppColors.surfaceHigh)),
              ),
              child: const TouchpadSurface(compact: true),
            ),
          ],
        ),
      ),
    );
  }
}

class _DPad extends StatelessWidget {
  const _DPad({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final arrow = size * 0.24;
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: RemoteButton(
              tvKey: TvKey.up,
              icon: Icons.keyboard_arrow_up_rounded,
              label: 'Haut',
              size: arrow,
              repeat: true,
              color: Colors.transparent,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: RemoteButton(
              tvKey: TvKey.down,
              icon: Icons.keyboard_arrow_down_rounded,
              label: 'Bas',
              size: arrow,
              repeat: true,
              color: Colors.transparent,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: RemoteButton(
              tvKey: TvKey.left,
              icon: Icons.keyboard_arrow_left_rounded,
              label: 'Gauche',
              size: arrow,
              repeat: true,
              color: Colors.transparent,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: RemoteButton(
              tvKey: TvKey.right,
              icon: Icons.keyboard_arrow_right_rounded,
              label: 'Droite',
              size: arrow,
              repeat: true,
              color: Colors.transparent,
            ),
          ),
          RemoteButton(
            tvKey: TvKey.ok,
            icon: Icons.circle_outlined,
            label: 'OK',
            size: size * 0.36,
            color: AppColors.surfaceHigh,
          ),
        ],
      ),
    );
  }
}

class _VolumeRocker extends StatelessWidget {
  const _VolumeRocker();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(40),
      ),
      child: const Column(
        children: [
          RemoteButton(
            tvKey: TvKey.volumeUp,
            icon: Icons.add_rounded,
            label: 'Volume +',
            size: 60,
            repeat: true,
            color: Colors.transparent,
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'VOL',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
          ),
          RemoteButton(
            tvKey: TvKey.volumeDown,
            icon: Icons.remove_rounded,
            label: 'Volume -',
            size: 60,
            repeat: true,
            color: Colors.transparent,
          ),
        ],
      ),
    );
  }
}

class _ActionCircle extends StatelessWidget {
  const _ActionCircle({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Material(
        color: AppColors.surfaceHigh,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 64,
            height: 64,
            child: Icon(icon, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}

class _VolumeBar extends StatelessWidget {
  const _VolumeBar({
    required this.level,
    required this.max,
    required this.muted,
  });

  final int level;
  final int max;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
          size: 18,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: max > 0 ? level / max : 0,
              minHeight: 6,
              backgroundColor: AppColors.surfaceHigh,
              color: muted ? AppColors.textSecondary : AppColors.accent,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text('$level', style: const TextStyle(color: AppColors.textSecondary)),
      ],
    );
  }
}

/// Raccourcis applications (liens d'application Android TV).
class _AppShortcuts extends ConsumerWidget {
  const _AppShortcuts();

  static const _apps = [
    ('YouTube', 'https://www.youtube.com', Color(0xFFFF0033)),
    ('Netflix', 'https://www.netflix.com/title', Color(0xFFE50914)),
    ('Prime Video', 'https://app.primevideo.com', Color(0xFF1399FF)),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Applications',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final (name, link, color) in _apps)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Material(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () async {
                        try {
                          await ref
                              .read(remoteControllerProvider.notifier)
                              .launchApp(link);
                        } on Exception catch (e) {
                          if (context.mounted) showNotConnected(context, e);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Column(
                          children: [
                            Icon(Icons.play_circle_fill_rounded, color: color),
                            const SizedBox(height: 6),
                            Text(name, style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

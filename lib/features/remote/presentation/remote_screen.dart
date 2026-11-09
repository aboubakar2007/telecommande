import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/protocol/tv_protocol.dart';
import '../../../shared/widgets/connection_badge.dart';
import '../../../shared/widgets/remote_button.dart';
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
        child: LayoutBuilder(
          builder: (context, c) {
            final dpad = (c.maxWidth * 0.72).clamp(220.0, 300.0);
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                children: [
                  // Ligne du haut : Power / Accueil / Menu
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RemoteButton(tvKey: TvKey.power, icon: Icons.power_settings_new_rounded, label: 'Power', iconColor: AppColors.danger),
                      RemoteButton(tvKey: TvKey.home, icon: Icons.home_rounded, label: 'Accueil'),
                      RemoteButton(tvKey: TvKey.menu, icon: Icons.menu_rounded, label: 'Menu'),
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
                      const RemoteButton(tvKey: TvKey.back, icon: Icons.arrow_back_rounded, label: 'Retour'),
                      const _VolumeRocker(),
                      Column(
                        children: [
                          const RemoteButton(tvKey: TvKey.mute, icon: Icons.volume_off_rounded, label: 'Muet'),
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
                      RemoteButton(tvKey: TvKey.rewind, icon: Icons.fast_rewind_rounded, label: 'Retour rapide', size: 56, repeat: true),
                      RemoteButton(tvKey: TvKey.playPause, icon: Icons.play_arrow_rounded, label: 'Lecture/Pause', size: 64, color: AppColors.accent),
                      RemoteButton(tvKey: TvKey.fastForward, icon: Icons.fast_forward_rounded, label: 'Avance rapide', size: 56, repeat: true),
                    ],
                  ),
                ],
              ),
            );
          },
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
      decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: RemoteButton(tvKey: TvKey.up, icon: Icons.keyboard_arrow_up_rounded, label: 'Haut', size: arrow, repeat: true, color: Colors.transparent),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: RemoteButton(tvKey: TvKey.down, icon: Icons.keyboard_arrow_down_rounded, label: 'Bas', size: arrow, repeat: true, color: Colors.transparent),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: RemoteButton(tvKey: TvKey.left, icon: Icons.keyboard_arrow_left_rounded, label: 'Gauche', size: arrow, repeat: true, color: Colors.transparent),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: RemoteButton(tvKey: TvKey.right, icon: Icons.keyboard_arrow_right_rounded, label: 'Droite', size: arrow, repeat: true, color: Colors.transparent),
          ),
          RemoteButton(tvKey: TvKey.ok, icon: Icons.circle_outlined, label: 'OK', size: size * 0.36, color: AppColors.surfaceHigh),
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
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(40)),
      child: const Column(
        children: [
          RemoteButton(tvKey: TvKey.volumeUp, icon: Icons.add_rounded, label: 'Volume +', size: 60, repeat: true, color: Colors.transparent),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text('VOL', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, letterSpacing: 1.5)),
          ),
          RemoteButton(tvKey: TvKey.volumeDown, icon: Icons.remove_rounded, label: 'Volume -', size: 60, repeat: true, color: Colors.transparent),
        ],
      ),
    );
  }
}

class _ActionCircle extends StatelessWidget {
  const _ActionCircle({required this.icon, required this.label, required this.onTap});

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
          child: SizedBox(width: 64, height: 64, child: Icon(icon, color: AppColors.textPrimary)),
        ),
      ),
    );
  }
}

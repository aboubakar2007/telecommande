import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/storage/identity_store.dart';
import '../../devices/data/device_repository.dart';
import '../../remote/domain/remote_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  String _status = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final minDelay = Future<void>.delayed(const Duration(milliseconds: 700));
    try {
      // Prépare le certificat dès le 1er lancement (quelques secondes, une seule fois).
      setState(() => _status = 'Préparation…');
      await ref.read(identityProvider.future);
      final last = (await ref.read(savedDevicesProvider.future)).lastUsed;
      if (last != null && last.paired) {
        // Reconnexion automatique en arrière-plan : l'accueil affiche l'état.
        ref.read(remoteControllerProvider.notifier).connectTo(last).catchError((_) {});
      }
    } on Object catch (e) {
      debugPrint('Initialisation : $e');
    }
    await minDelay;
    if (mounted) context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(Icons.settings_remote_rounded, size: 52, color: AppColors.accent),
            ),
            const SizedBox(height: 20),
            const Text('Family Remote', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text('Télécommande familiale', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            Text(_status, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

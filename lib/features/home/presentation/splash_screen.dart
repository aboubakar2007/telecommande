import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Phase 5 : chargement des téléviseurs enregistrés + reconnexion auto ici.
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) context.go(Routes.home);
    });
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
            const Text(
              'Family Remote',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text('Télécommande familiale', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

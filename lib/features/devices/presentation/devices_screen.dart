import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';

/// Téléviseurs enregistrés. La persistance et la gestion arrivent en phase 5.
class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes appareils')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.tv_off_rounded, size: 56, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              const Text('Aucun téléviseur enregistré', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              const Text(
                'Les téléviseurs associés apparaîtront ici.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.push(Routes.discovery),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Ajouter un téléviseur'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

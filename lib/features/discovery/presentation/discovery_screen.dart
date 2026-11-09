import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/models/tv_device.dart';

/// Recherche des téléviseurs.
///
/// Phase 2 : saisie manuelle de l'adresse IP uniquement.
/// Phase 3b : découverte automatique mDNS (_androidtvremote2._tcp).
class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final _ipCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _ipCtrl.dispose();
    super.dispose();
  }

  void _useManualIp() {
    final ip = _ipCtrl.text.trim();
    final parsed = InternetAddress.tryParse(ip);
    if (parsed == null || parsed.type != InternetAddressType.IPv4) {
      setState(() => _error = 'Adresse IPv4 invalide (ex. 192.168.1.20)');
      return;
    }
    setState(() => _error = null);
    final device = TvDevice(id: ip, name: 'Téléviseur ($ip)', host: ip);
    context.push(Routes.pairing, extra: device);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rechercher un téléviseur')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Card(
            child: ListTile(
              contentPadding: EdgeInsets.all(16),
              leading: Icon(Icons.wifi_find_rounded, color: AppColors.warning),
              title: Text('Détection automatique'),
              subtitle: Text(
                'Disponible à la prochaine étape du développement (phase 3). '
                'En attendant, saisissez l’adresse IP du téléviseur.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Adresse IP du téléviseur', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _ipCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(hintText: '192.168.100.3', errorText: _error),
            onSubmitted: (_) => _useManualIp(),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sur la Sony : Paramètres › Réseau › État du réseau.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _useManualIp, child: const Text('Continuer')),
        ],
      ),
    );
  }
}

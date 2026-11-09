import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/protocol/tv_protocol.dart';
import '../../../shared/models/tv_device.dart';
import '../../devices/data/device_repository.dart';
import '../../remote/domain/remote_controller.dart';
import '../data/discovery_service.dart';

final _wifiProvider = StreamProvider.autoDispose<bool>((ref) async* {
  final c = Connectivity();
  bool isWifi(List<ConnectivityResult> r) =>
      r.contains(ConnectivityResult.wifi) || r.contains(ConnectivityResult.ethernet);
  yield isWifi(await c.checkConnectivity());
  yield* c.onConnectivityChanged.map(isWifi);
});

/// Sélection d'un téléviseur : déjà associé → connexion directe,
/// sinon (ou si le téléviseur ne reconnaît plus ce téléphone) → association.
Future<void> openTv(BuildContext context, WidgetRef ref, TvDevice device) async {
  final saved = (await ref.read(savedDevicesProvider.future)).devices;
  final known = saved.where((d) => d.id == device.id).firstOrNull;
  if (known != null && known.paired) {
    final updated = known.copyWith(host: device.host);
    try {
      await ref.read(remoteControllerProvider.notifier).connectTo(updated);
      if (context.mounted) context.go(Routes.remote);
      return;
    } on TvNotPairedException {
      // On retombe sur l'association.
    }
  }
  if (context.mounted) context.push(Routes.pairing, extra: device);
}

class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  final _ipCtrl = TextEditingController();
  String? _ipError;
  bool _busy = false;

  @override
  void dispose() {
    _ipCtrl.dispose();
    super.dispose();
  }

  Future<void> _open(TvDevice d) async {
    setState(() => _busy = true);
    try {
      await openTv(context, ref, d);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _useManualIp() {
    final ip = _ipCtrl.text.trim();
    final parsed = InternetAddress.tryParse(ip);
    if (parsed == null || parsed.type != InternetAddressType.IPv4) {
      setState(() => _ipError = 'Adresse IPv4 invalide (ex. 192.168.1.20)');
      return;
    }
    setState(() => _ipError = null);
    _open(TvDevice(id: ip, name: 'Téléviseur ($ip)', host: ip));
  }

  @override
  Widget build(BuildContext context) {
    final wifi = ref.watch(_wifiProvider).value ?? true;
    final found = ref.watch(discoveryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rechercher un téléviseur'),
        actions: [
          IconButton(
            tooltip: 'Relancer la recherche',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(discoveryProvider),
          ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (!wifi) const _WifiWarning(),
            if (_busy) const LinearProgressIndicator(),
            const SizedBox(height: 8),
            const Text('Téléviseurs détectés', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            found.when(
              loading: () => const _Searching(),
              error: (e, _) => _InfoCard(
                icon: Icons.error_outline_rounded,
                color: AppColors.danger,
                text: 'La recherche automatique a échoué ($e). Utilisez l’adresse IP ci-dessous.',
              ),
              data: (list) => list.isEmpty
                  ? const _Searching()
                  : Column(
                      children: [
                        for (final d in list)
                          Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                              leading: const Icon(Icons.tv_rounded, color: AppColors.accent),
                              title: Text(d.name),
                              subtitle: Text(d.host, style: const TextStyle(color: AppColors.textSecondary)),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () => _open(d),
                            ),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 28),
            const Text('Ou saisir l’adresse IP', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _ipCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(hintText: '192.168.100.3', errorText: _ipError),
              onSubmitted: (_) => _useManualIp(),
            ),
            const SizedBox(height: 6),
            const Text(
              'Sur la Sony : Paramètres › Réseau › Configuration réseau › État du réseau.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: _useManualIp, child: const Text('Continuer avec cette adresse')),
          ],
        ),
      ),
    );
  }
}

class _Searching extends StatelessWidget {
  const _Searching();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5)),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                'Recherche sur le réseau Wi-Fi…\nLe téléviseur doit être allumé.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WifiWarning extends StatelessWidget {
  const _WifiWarning();

  @override
  Widget build(BuildContext context) => const _InfoCard(
        icon: Icons.wifi_off_rounded,
        color: AppColors.warning,
        text: 'Le Wi-Fi semble désactivé. Connectez ce téléphone au même Wi-Fi que le téléviseur.',
      );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}

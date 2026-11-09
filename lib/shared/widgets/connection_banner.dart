import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/app_theme.dart';
import '../../core/protocol/tv_protocol.dart';
import '../../features/remote/domain/remote_controller.dart';

/// Bandeau affiché quand la connexion au téléviseur n'est pas active.
class ConnectionBanner extends ConsumerWidget {
  const ConnectionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(remoteControllerProvider);
    final device = s.device;
    final status = s.connection.status;
    if (device == null || status == TvConnectionStatus.connected) return const SizedBox.shrink();

    final notPaired = !device.paired ||
        (s.connection.message?.contains('pas associé') ?? false);
    final connecting = status == TvConnectionStatus.connecting;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: (connecting ? AppColors.warning : AppColors.danger).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          if (connecting)
            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          else
            const Icon(Icons.link_off_rounded, color: AppColors.danger),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              connecting
                  ? 'Connexion à ${device.name}…'
                  : s.connection.message ?? 'Téléviseur déconnecté',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          if (!connecting)
            TextButton(
              onPressed: () => notPaired
                  ? context.push(Routes.pairing, extra: device)
                  : ref.read(remoteControllerProvider.notifier).reconnect().catchError((_) {}),
              child: Text(notPaired ? 'Associer' : 'Reconnecter'),
            ),
        ],
      ),
    );
  }
}

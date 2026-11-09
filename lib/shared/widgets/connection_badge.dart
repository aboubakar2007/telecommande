import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../core/protocol/tv_protocol.dart';

/// Pastille d'état de connexion.
class ConnectionBadge extends StatelessWidget {
  const ConnectionBadge({super.key, required this.state});

  final TvConnectionState state;

  @override
  Widget build(BuildContext context) {
    final (color, text) = switch (state.status) {
      TvConnectionStatus.connected => (AppColors.success, 'Connecté'),
      TvConnectionStatus.connecting => (AppColors.warning, 'Connexion…'),
      TvConnectionStatus.error => (AppColors.danger, 'Erreur'),
      TvConnectionStatus.disconnected => (AppColors.textSecondary, 'Non connecté'),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: color, fontSize: 13)),
      ],
    );
  }
}

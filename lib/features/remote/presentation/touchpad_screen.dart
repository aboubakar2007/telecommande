import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/protocol/tv_protocol.dart';
import '../../../shared/widgets/remote_button.dart';
import '../../../shared/widgets/touchpad_surface.dart';

/// Pavé tactile plein écran.
class TouchpadScreen extends StatelessWidget {
  const TouchpadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pavé tactile')),
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(child: TouchpadSurface()),
              SizedBox(height: 12),
              Text(
                'Navigation directionnelle : le téléviseur ne propose pas de curseur souris.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  RemoteButton(tvKey: TvKey.back, icon: Icons.arrow_back_rounded, label: 'Retour'),
                  RemoteButton(tvKey: TvKey.home, icon: Icons.home_rounded, label: 'Accueil'),
                  RemoteButton(tvKey: TvKey.volumeDown, icon: Icons.volume_down_rounded, label: 'Volume -', repeat: true),
                  RemoteButton(tvKey: TvKey.volumeUp, icon: Icons.volume_up_rounded, label: 'Volume +', repeat: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

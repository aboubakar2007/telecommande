import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/protocol/tv_protocol.dart';
import '../../../shared/widgets/remote_button.dart';
import '../../settings/domain/settings_controller.dart';

/// Pavé tactile directionnel.
///
/// Le protocole Android TV Remote n'expose PAS de curseur souris : les
/// glissements sont convertis en flèches (une flèche tous les [_step] pixels),
/// un tap = OK, un appui long = OK maintenu.
class TouchpadScreen extends ConsumerStatefulWidget {
  const TouchpadScreen({super.key});

  @override
  ConsumerState<TouchpadScreen> createState() => _TouchpadScreenState();
}

class _TouchpadScreenState extends ConsumerState<TouchpadScreen> {
  Offset _accum = Offset.zero;
  String _hint = 'Glissez pour naviguer · Touchez pour valider';

  double get _step {
    final s = ref.read(settingsProvider).value?.touchpadSensitivity ?? 0.5;
    // Sensibilité 0 → 90 px par flèche ; 1 → 25 px.
    return 90 - s * 65;
  }

  void _send(TvKey key, String label, {KeyPress press = KeyPress.short}) {
    HapticFeedback.selectionClick();
    setState(() => _hint = label);
    sendTvKey(context, ref, key, press: press);
  }

  void _onPan(DragUpdateDetails d) {
    _accum += d.delta;
    final step = _step;
    while (_accum.dx.abs() >= step || _accum.dy.abs() >= step) {
      if (_accum.dx.abs() > _accum.dy.abs()) {
        final right = _accum.dx > 0;
        _send(right ? TvKey.right : TvKey.left, right ? 'Droite' : 'Gauche');
        _accum = Offset(_accum.dx - (right ? step : -step), 0);
      } else {
        final down = _accum.dy > 0;
        _send(down ? TvKey.down : TvKey.up, down ? 'Bas' : 'Haut');
        _accum = Offset(0, _accum.dy - (down ? step : -step));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pavé tactile')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (_) => _accum = Offset.zero,
                  onPanUpdate: _onPan,
                  onTap: () => _send(TvKey.ok, 'OK'),
                  onLongPressStart: (_) => _send(TvKey.ok, 'OK maintenu', press: KeyPress.longStart),
                  onLongPressEnd: (_) => _send(TvKey.ok, 'OK relâché', press: KeyPress.longEnd),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppColors.surfaceHigh),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.swipe_rounded, size: 48, color: AppColors.textSecondary),
                        const SizedBox(height: 12),
                        Text(_hint, style: const TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Navigation directionnelle : votre téléviseur ne propose pas de curseur souris.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 16),
              const Row(
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

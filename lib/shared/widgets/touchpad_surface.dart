import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../core/protocol/tv_protocol.dart';
import '../../features/settings/domain/settings_controller.dart';
import 'remote_button.dart';

/// Surface tactile : glisser = flèches, tap = OK, appui long = OK maintenu.
///
/// Le protocole Android TV Remote n'expose pas de curseur souris : on
/// convertit les gestes en navigation directionnelle (comme l'appli Google TV).
class TouchpadSurface extends ConsumerStatefulWidget {
  const TouchpadSurface({super.key, this.compact = false});

  /// Version réduite (bas de la télécommande).
  final bool compact;

  @override
  ConsumerState<TouchpadSurface> createState() => _TouchpadSurfaceState();
}

class _TouchpadSurfaceState extends ConsumerState<TouchpadSurface> {
  Offset _accum = Offset.zero;
  String? _last;
  Offset? _touch;

  double get _step {
    final s = ref.read(settingsProvider).value?.touchpadSensitivity ?? 0.5;
    final base = 90 - s * 65; // sensibilité 0 → 90 px par flèche, 1 → 25 px
    return widget.compact ? base * 0.75 : base;
  }

  void _send(TvKey key, String label, {KeyPress press = KeyPress.short}) {
    if (ref.read(settingsProvider).value?.haptics ?? true) HapticFeedback.selectionClick();
    setState(() => _last = label);
    sendTvKey(context, ref, key, press: press);
  }

  void _onPan(DragUpdateDetails d) {
    setState(() => _touch = d.localPosition);
    _accum += d.delta;
    final step = _step;
    while (_accum.dx.abs() >= step || _accum.dy.abs() >= step) {
      if (_accum.dx.abs() > _accum.dy.abs()) {
        final right = _accum.dx > 0;
        _send(right ? TvKey.right : TvKey.left, right ? '→' : '←');
        _accum = Offset(_accum.dx - (right ? step : -step), 0);
      } else {
        final down = _accum.dy > 0;
        _send(down ? TvKey.down : TvKey.up, down ? '↓' : '↑');
        _accum = Offset(0, _accum.dy - (down ? step : -step));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (d) => setState(() {
        _accum = Offset.zero;
        _touch = d.localPosition;
      }),
      onPanUpdate: _onPan,
      onPanEnd: (_) => setState(() => _touch = null),
      onTapDown: (d) => setState(() => _touch = d.localPosition),
      onTap: () {
        _send(TvKey.ok, 'OK');
        setState(() => _touch = null);
      },
      onLongPressStart: (_) => _send(TvKey.ok, 'OK maintenu', press: KeyPress.longStart),
      onLongPressEnd: (_) {
        _send(TvKey.ok, 'OK', press: KeyPress.longEnd);
        setState(() => _touch = null);
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(widget.compact ? 22 : 28),
          border: Border.all(color: AppColors.surfaceHigh),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swipe_rounded,
                      size: widget.compact ? 26 : 48, color: AppColors.textSecondary.withValues(alpha: 0.6)),
                  const SizedBox(height: 6),
                  Text(
                    _last ?? 'Glissez pour naviguer · Touchez = OK',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: widget.compact ? 12 : 14),
                  ),
                ],
              ),
            ),
            if (_touch case final p?)
              Positioned(
                left: p.dx - 18,
                top: p.dy - 18,
                child: IgnorePointer(
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accent.withValues(alpha: 0.25),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

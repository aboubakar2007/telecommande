import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../core/protocol/tv_protocol.dart';
import '../../features/remote/domain/remote_controller.dart';
import '../../features/settings/domain/settings_controller.dart';

/// Envoie une touche et affiche une erreur claire en cas d'échec.
Future<void> sendTvKey(BuildContext context, WidgetRef ref, TvKey key,
    {KeyPress press = KeyPress.short}) async {
  try {
    await ref.read(remoteControllerProvider.notifier).press(key, press: press);
  } on Exception catch (e) {
    if (context.mounted) showNotConnected(context, e);
  }
}

DateTime _lastSnack = DateTime(0);

void showNotConnected(BuildContext context, Object error) {
  if (!context.mounted) return;
  // Évite d'empiler les messages lors d'appuis répétés.
  final now = DateTime.now();
  if (now.difference(_lastSnack) < const Duration(seconds: 2)) return;
  _lastSnack = now;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(error.toString())));
}

/// Bouton rond de télécommande.
///
/// - Retour visuel + vibration à l'appui.
/// - Anti double-appui involontaire ([debounce]).
/// - [repeat] : un appui maintenu répète la commande (volume, flèches).
class RemoteButton extends ConsumerStatefulWidget {
  const RemoteButton({
    super.key,
    required this.tvKey,
    required this.icon,
    this.label,
    this.size = 64,
    this.repeat = false,
    this.color,
    this.iconColor,
  });

  final TvKey tvKey;
  final IconData icon;
  final String? label;
  final double size;
  final bool repeat;
  final Color? color;
  final Color? iconColor;

  static const debounce = Duration(milliseconds: 120);
  static const repeatDelay = Duration(milliseconds: 400);
  static const repeatInterval = Duration(milliseconds: 120);

  @override
  ConsumerState<RemoteButton> createState() => _RemoteButtonState();
}

class _RemoteButtonState extends ConsumerState<RemoteButton> {
  bool _pressed = false;
  DateTime _lastSent = DateTime(0);
  Timer? _repeatTimer;

  void _send() {
    final now = DateTime.now();
    if (now.difference(_lastSent) < RemoteButton.debounce) return;
    _lastSent = now;
    if (ref.read(settingsProvider).value?.haptics ?? true) {
      HapticFeedback.lightImpact();
    }
    sendTvKey(context, ref, widget.tvKey);
  }

  void _down(_) {
    setState(() => _pressed = true);
    _send();
    if (widget.repeat) {
      _repeatTimer = Timer(RemoteButton.repeatDelay, () {
        _repeatTimer = Timer.periodic(RemoteButton.repeatInterval, (_) {
          _lastSent = DateTime(0);
          _send();
        });
      });
    }
  }

  void _up([_]) {
    _repeatTimer?.cancel();
    _repeatTimer = null;
    if (mounted) setState(() => _pressed = false);
  }

  @override
  void dispose() {
    _repeatTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.color ?? AppColors.surfaceHigh;
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        onTapDown: _down,
        onTapUp: _up,
        onTapCancel: _up,
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1,
          duration: const Duration(milliseconds: 90),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: _pressed ? Color.lerp(bg, Colors.white, 0.12) : bg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.icon,
              size: widget.size * 0.42,
              color: widget.iconColor ?? AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

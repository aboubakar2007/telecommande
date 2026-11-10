import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../core/protocol/tv_protocol.dart';
import '../../features/remote/domain/remote_controller.dart';
import 'remote_button.dart';

/// Champ de saisie directe : le texte tapé sur le téléphone apparaît en
/// direct dans la barre de recherche ouverte sur le téléviseur.
class QuickTextBar extends ConsumerStatefulWidget {
  const QuickTextBar({super.key});

  @override
  ConsumerState<QuickTextBar> createState() => _QuickTextBarState();
}

class _QuickTextBarState extends ConsumerState<QuickTextBar> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  String _sent = '';
  Timer? _debounce;
  Future<void> _queue = Future.value();

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), _sync);
  }

  /// Les envois sont sérialisés pour garder l'ordre des lettres.
  void _sync() {
    final text = _ctrl.text;
    _queue = _queue.then((_) async {
      if (text == _sent) return;
      try {
        await ref.read(remoteControllerProvider.notifier).syncText(text, _sent);
        _sent = text;
      } on Exception catch (e) {
        if (mounted) showNotConnected(context, e);
      }
    });
  }

  Future<void> _submit() async {
    _debounce?.cancel();
    _sync();
    await _queue;
    if (mounted) await sendTvKey(context, ref, TvKey.enter);
  }

  void _clear() {
    _ctrl.clear();
    _onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      focusNode: _focus,
      textInputAction: TextInputAction.search,
      onChanged: _onChanged,
      onSubmitted: (_) => _submit(),
      decoration: InputDecoration(
        hintText: 'Taper sur la TV (recherche…)',
        prefixIcon: const Icon(Icons.keyboard_alt_outlined, color: AppColors.textSecondary),
        suffixIcon: ValueListenableBuilder(
          valueListenable: _ctrl,
          builder: (_, v, _) => v.text.isEmpty
              ? const SizedBox.shrink()
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(tooltip: 'Effacer', icon: const Icon(Icons.close_rounded), onPressed: _clear),
                    IconButton(
                      tooltip: 'Valider',
                      icon: const Icon(Icons.search_rounded, color: AppColors.accent),
                      onPressed: _submit,
                    ),
                  ],
                ),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}

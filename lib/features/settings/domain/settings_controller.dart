import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  const AppSettings({this.phoneName = 'Mon téléphone', this.touchpadSensitivity = 0.5, this.haptics = true});

  /// Nom affiché sur le téléviseur lors de l'association.
  final String phoneName;

  /// 0 = peu sensible (grands gestes), 1 = très sensible.
  final double touchpadSensitivity;

  final bool haptics;

  AppSettings copyWith({String? phoneName, double? touchpadSensitivity, bool? haptics}) => AppSettings(
        phoneName: phoneName ?? this.phoneName,
        touchpadSensitivity: touchpadSensitivity ?? this.touchpadSensitivity,
        haptics: haptics ?? this.haptics,
      );
}

class SettingsController extends AsyncNotifier<AppSettings> {
  static const _kName = 'phone_name';
  static const _kSens = 'touchpad_sensitivity';
  static const _kHaptics = 'haptics';

  @override
  Future<AppSettings> build() async {
    final p = await SharedPreferences.getInstance();
    return AppSettings(
      phoneName: p.getString(_kName) ?? 'Mon téléphone',
      touchpadSensitivity: p.getDouble(_kSens) ?? 0.5,
      haptics: p.getBool(_kHaptics) ?? true,
    );
  }

  Future<void> setPhoneName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    await (await SharedPreferences.getInstance()).setString(_kName, trimmed);
    state = AsyncData(_current.copyWith(phoneName: trimmed));
  }

  Future<void> setSensitivity(double v) async {
    await (await SharedPreferences.getInstance()).setDouble(_kSens, v);
    state = AsyncData(_current.copyWith(touchpadSensitivity: v));
  }

  Future<void> setHaptics(bool v) async {
    await (await SharedPreferences.getInstance()).setBool(_kHaptics, v);
    state = AsyncData(_current.copyWith(haptics: v));
  }

  AppSettings get _current => state.value ?? const AppSettings();
}

final settingsProvider = AsyncNotifierProvider<SettingsController, AppSettings>(SettingsController.new);

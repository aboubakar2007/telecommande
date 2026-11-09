import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/devices/presentation/devices_screen.dart';
import '../features/discovery/presentation/discovery_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/home/presentation/splash_screen.dart';
import '../features/pairing/presentation/pairing_screen.dart';
import '../features/remote/presentation/keyboard_screen.dart';
import '../features/remote/presentation/remote_screen.dart';
import '../features/remote/presentation/touchpad_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../shared/models/tv_device.dart';

abstract final class Routes {
  static const splash = '/';
  static const home = '/home';
  static const discovery = '/discovery';
  static const pairing = '/pairing';
  static const remote = '/remote';
  static const touchpad = '/remote/touchpad';
  static const keyboard = '/remote/keyboard';
  static const devices = '/devices';
  static const settings = '/settings';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.splash,
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen()),
      GoRoute(path: Routes.discovery, builder: (_, _) => const DiscoveryScreen()),
      GoRoute(
        path: Routes.pairing,
        builder: (_, state) => PairingScreen(device: state.extra! as TvDevice),
      ),
      GoRoute(path: Routes.remote, builder: (_, _) => const RemoteScreen()),
      GoRoute(path: Routes.touchpad, builder: (_, _) => const TouchpadScreen()),
      GoRoute(path: Routes.keyboard, builder: (_, _) => const KeyboardScreen()),
      GoRoute(path: Routes.devices, builder: (_, _) => const DevicesScreen()),
      GoRoute(path: Routes.settings, builder: (_, _) => const SettingsScreen()),
    ],
  );
});

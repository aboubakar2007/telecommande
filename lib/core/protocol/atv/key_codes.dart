import '../tv_protocol.dart';

/// Correspondance TvKey → code touche Android (RemoteKeyCode).
const Map<TvKey, int> androidKeyCodes = {
  TvKey.power: 26,
  TvKey.up: 19,
  TvKey.down: 20,
  TvKey.left: 21,
  TvKey.right: 22,
  TvKey.ok: 23,
  TvKey.back: 4,
  TvKey.home: 3,
  TvKey.menu: 82,
  TvKey.volumeUp: 24,
  TvKey.volumeDown: 25,
  TvKey.mute: 164,
  TvKey.playPause: 85,
  TvKey.play: 126,
  TvKey.pause: 127,
  TvKey.fastForward: 90,
  TvKey.rewind: 89,
  TvKey.next: 87,
  TvKey.previous: 88,
  TvKey.channelUp: 166,
  TvKey.channelDown: 167,
  TvKey.settings: 176,
  TvKey.info: 165,
  TvKey.delete: 67,
  TvKey.enter: 66,
};

/// RemoteDirection : START_LONG=1, END_LONG=2, SHORT=3.
int directionCode(KeyPress press) => switch (press) {
      KeyPress.longStart => 1,
      KeyPress.longEnd => 2,
      KeyPress.short => 3,
    };

/// Code touche Android pour un caractère (saisie de secours lettre par lettre).
/// Retourne null pour les caractères non représentables (accents…).
int? charKeyCode(String ch) {
  final c = ch.toLowerCase();
  final u = c.codeUnitAt(0);
  if (u >= 0x61 && u <= 0x7A) return 29 + (u - 0x61); // a-z → KEYCODE_A..Z
  if (u >= 0x30 && u <= 0x39) return 7 + (u - 0x30); // 0-9 → KEYCODE_0..9
  return const {
    ' ': 62,
    '.': 56,
    ',': 55,
    '-': 69,
    '=': 70,
    '@': 77,
    '/': 76,
    "'": 75,
    ';': 74,
    '+': 81,
  }[c];
}

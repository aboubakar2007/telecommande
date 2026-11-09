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

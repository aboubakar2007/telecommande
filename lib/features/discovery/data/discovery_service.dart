import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nsd/nsd.dart' as nsd;

import '../../../shared/models/tv_device.dart';

/// Type de service annoncé par les Android TV / Google TV (Remote Service v5+).
const atvServiceType = '_androidtvremote2._tcp';

/// Découverte mDNS / DNS-SD des téléviseurs compatibles.
///
/// Seuls les appareils annonçant [atvServiceType] sont listés : un appareil
/// qui répond simplement au ping n'est pas considéré comme compatible.
Stream<List<TvDevice>> discoverTvs() {
  late final StreamController<List<TvDevice>> ctrl;
  nsd.Discovery? discovery;
  final found = <String, TvDevice>{};

  Future<void> start() async {
    try {
      discovery = await nsd.startDiscovery(atvServiceType, ipLookupType: nsd.IpLookupType.v4);
      discovery!.addServiceListener((service, status) {
        final name = service.name;
        if (name == null) return;
        if (status == nsd.ServiceStatus.lost) {
          found.remove(name);
        } else {
          final ip = service.addresses
              ?.firstWhere((a) => a.type == InternetAddressType.IPv4, orElse: () => service.addresses!.first)
              .address;
          final host = ip ?? service.host;
          if (host == null) return;
          found[name] = TvDevice(id: name, name: name, host: host, remotePort: service.port ?? 6466);
        }
        if (!ctrl.isClosed) ctrl.add(found.values.toList());
      });
      if (!ctrl.isClosed) ctrl.add(const []);
    } on Object catch (e, st) {
      debugPrint('Découverte mDNS impossible : $e');
      if (!ctrl.isClosed) ctrl.addError(e, st);
    }
  }

  ctrl = StreamController<List<TvDevice>>(
    onListen: start,
    onCancel: () async {
      final d = discovery;
      if (d != null) await nsd.stopDiscovery(d);
    },
  );
  return ctrl.stream;
}

/// Liste en direct des téléviseurs détectés (s'arrête quand l'écran est fermé).
final discoveryProvider = StreamProvider.autoDispose<List<TvDevice>>((ref) => discoverTvs());

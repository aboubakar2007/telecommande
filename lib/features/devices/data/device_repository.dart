import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/models/tv_device.dart';

class SavedDevices {
  const SavedDevices({this.devices = const [], this.lastUsedId});

  final List<TvDevice> devices;
  final String? lastUsedId;

  TvDevice? get lastUsed {
    for (final d in devices) {
      if (d.id == lastUsedId) return d;
    }
    return null;
  }
}

/// Téléviseurs enregistrés (stockage local du téléphone).
class SavedDevicesController extends AsyncNotifier<SavedDevices> {
  static const _kDevices = 'saved_tvs_v1';
  static const _kLast = 'last_tv_id';

  @override
  Future<SavedDevices> build() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kDevices);
    final list = raw == null
        ? <TvDevice>[]
        : (jsonDecode(raw) as List).map((e) => TvDevice.fromJson(e as Map<String, Object?>)).toList();
    return SavedDevices(devices: list, lastUsedId: p.getString(_kLast));
  }

  Future<void> _save(SavedDevices s) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kDevices, jsonEncode(s.devices.map((d) => d.toJson()).toList()));
    if (s.lastUsedId == null) {
      await p.remove(_kLast);
    } else {
      await p.setString(_kLast, s.lastUsedId!);
    }
    state = AsyncData(s);
  }

  SavedDevices get _current => state.value ?? const SavedDevices();

  /// Ajoute ou met à jour (même id) et le marque comme dernier utilisé.
  Future<void> upsert(TvDevice device) async {
    final list = [..._current.devices.where((d) => d.id != device.id), device];
    await _save(SavedDevices(devices: list, lastUsedId: device.id));
  }

  /// Met à jour l'adresse IP d'un téléviseur connu retrouvé par la découverte.
  Future<void> updateHost(String id, String host) async {
    final cur = _current;
    final list = [
      for (final d in cur.devices) d.id == id && d.host != host ? d.copyWith(host: host) : d,
    ];
    await _save(SavedDevices(devices: list, lastUsedId: cur.lastUsedId));
  }

  Future<void> markUnpaired(String id) async {
    final cur = _current;
    final list = [for (final d in cur.devices) d.id == id ? d.copyWith(paired: false) : d];
    await _save(SavedDevices(devices: list, lastUsedId: cur.lastUsedId));
  }

  Future<void> remove(String id) async {
    final cur = _current;
    await _save(SavedDevices(
      devices: cur.devices.where((d) => d.id != id).toList(),
      lastUsedId: cur.lastUsedId == id ? null : cur.lastUsedId,
    ));
  }
}

final savedDevicesProvider =
    AsyncNotifierProvider<SavedDevicesController, SavedDevices>(SavedDevicesController.new);

/// Téléviseur détecté ou enregistré.
class TvDevice {
  const TvDevice({
    required this.id,
    required this.name,
    required this.host,
    this.remotePort = 6466,
    this.pairingPort = 6467,
    this.paired = false,
  });

  final String id;
  final String name;
  final String host;
  final int remotePort;
  final int pairingPort;
  final bool paired;

  TvDevice copyWith({String? name, bool? paired}) => TvDevice(
        id: id,
        name: name ?? this.name,
        host: host,
        remotePort: remotePort,
        pairingPort: pairingPort,
        paired: paired ?? this.paired,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'host': host,
        'remotePort': remotePort,
        'pairingPort': pairingPort,
        'paired': paired,
      };

  factory TvDevice.fromJson(Map<String, Object?> json) => TvDevice(
        id: json['id']! as String,
        name: json['name']! as String,
        host: json['host']! as String,
        remotePort: json['remotePort'] as int? ?? 6466,
        pairingPort: json['pairingPort'] as int? ?? 6467,
        paired: json['paired'] as bool? ?? false,
      );
}

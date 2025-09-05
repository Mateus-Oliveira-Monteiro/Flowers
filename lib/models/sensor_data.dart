class SensorData {
  final int raw;
  final int timestamp;
  final int umidade;

  SensorData({
    required this.raw,
    required this.timestamp,
    required this.umidade,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      raw: json['raw'] ?? 0,
      timestamp: json['timestamp'] ?? 0,
      umidade: json['umidade'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'raw': raw, 'timestamp': timestamp, 'umidade': umidade};
  }

  @override
  String toString() {
    return 'SensorData(raw: $raw, timestamp: $timestamp, umidade: $umidade)';
  }
}

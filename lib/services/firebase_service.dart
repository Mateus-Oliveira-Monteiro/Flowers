import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../models/sensor_data.dart';

class FirebaseService {
  static const String _databaseUrl =
      'https://umidade-solo-default-rtdb.firebaseio.com';

  DatabaseReference get _sensorRef => FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: _databaseUrl,
      ).ref('sensor');

  DatabaseReference get _pumpRef => FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: _databaseUrl,
      ).ref('bomba');

  SensorData? _parseSensorValue(Object? value) {
    if (value is! Map) {
      return null;
    }

    final data = Map<String, dynamic>.from(value as Map);
    return SensorData.fromJson(data);
  }

  /// Busca os dados do sensor do Firebase Realtime Database
  Future<SensorData?> getSensorData() async {
    try {
      final snapshot = await _sensorRef.get();
      return _parseSensorValue(snapshot.value);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro na requisição: $e');
      }
      return null;
    }
  }

  /// Stream para receber atualizações em tempo real dos dados do sensor
  Stream<SensorData?> getSensorDataStream() {
    return _sensorRef.onValue.map((event) {
      return _parseSensorValue(event.snapshot.value);
    });
  }

  /// Liga/Desliga a bomba de água (caminho: /bomba/on)
  Future<bool> setPumpOn(bool on) async {
    try {
      await _pumpRef.update({'on': on});
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro na requisição da bomba: $e');
      }
      return false;
    }
  }
}

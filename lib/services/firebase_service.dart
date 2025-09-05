import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/sensor_data.dart';

class FirebaseService {
  static const String _baseUrl =
      'https://umidade-solo-default-rtdb.firebaseio.com';

  /// Busca os dados do sensor do Firebase Realtime Database
  Future<SensorData?> getSensorData() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/sensor.json'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return SensorData.fromJson(data);
      } else {
        if (kDebugMode) {
          debugPrint('Erro ao buscar dados: ${response.statusCode}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro na requisição: $e');
      }
      return null;
    }
  }

  /// Stream para receber atualizações em tempo real dos dados do sensor
  Stream<SensorData?> getSensorDataStream() async* {
    while (true) {
      final data = await getSensorData();
      yield data;
      await Future.delayed(
        const Duration(seconds: 2),
      ); // Atualiza a cada 2 segundos
    }
  }
}

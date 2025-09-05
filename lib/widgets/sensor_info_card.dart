import 'package:flutter/material.dart';
import '../models/sensor_data.dart';

class SensorInfoCard extends StatelessWidget {
  final SensorData sensorData;

  const SensorInfoCard({super.key, required this.sensorData});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informações do Sensor',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              'Umidade',
              '${sensorData.umidade}%',
              Icons.water_drop,
              _getHumidityColor(sensorData.umidade.toDouble()),
            ),
            const Divider(),
            _buildInfoRow(
              'Valor Raw',
              sensorData.raw.toString(),
              Icons.sensors,
              Colors.blue,
            ),
            const Divider(),
            _buildInfoRow(
              'Horário',
              _formatTimestamp(sensorData.timestamp),
              Icons.access_time,
              Colors.grey[600]!,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getHumidityColor(double humidity) {
    if (humidity < 30) return Colors.red;
    if (humidity < 60) return Colors.orange;
    return Colors.green;
  }

  String _formatTimestamp(int timestamp) {
    // Converte o timestamp Unix (milissegundos desde 1970) para uma data legível
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }
}

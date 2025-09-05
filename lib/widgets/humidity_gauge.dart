import 'package:flutter/material.dart';
import 'dart:math' as math;

class HumidityGauge extends StatelessWidget {
  final double humidity;
  final double size;

  const HumidityGauge({super.key, required this.humidity, this.size = 200.0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: HumidityGaugePainter(humidity: humidity),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${humidity.toInt()}%',
                style: TextStyle(
                  fontSize: size * 0.15,
                  fontWeight: FontWeight.bold,
                  color: _getHumidityColor(humidity),
                ),
              ),
              Text(
                'Umidade',
                style: TextStyle(
                  fontSize: size * 0.08,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getHumidityColor(double humidity) {
    if (humidity < 30) return Colors.red;
    if (humidity < 60) return Colors.orange;
    return Colors.green;
  }
}

class HumidityGaugePainter extends CustomPainter {
  final double humidity;

  HumidityGaugePainter({required this.humidity});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.8;
    final strokeWidth = size.width * 0.05;

    // Desenha o fundo do gauge
    final backgroundPaint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.75, // Começa em -135 graus
      math.pi * 1.5, // Arco de 270 graus
      false,
      backgroundPaint,
    );

    // Desenha o preenchimento baseado na umidade
    final fillPaint = Paint()
      ..color = _getHumidityColor(humidity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (humidity / 100) * math.pi * 1.5;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.75,
      sweepAngle,
      false,
      fillPaint,
    );

    // Desenha as marcações
    _drawMarkers(canvas, center, radius, size);
  }

  void _drawMarkers(Canvas canvas, Offset center, double radius, Size size) {
    final markerPaint = Paint()
      ..color = Colors.grey[600]!
      ..strokeWidth = 2;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i <= 100; i += 20) {
      final angle = -math.pi * 0.75 + (i / 100) * math.pi * 1.5;
      final markerStart = Offset(
        center.dx + (radius - 15) * math.cos(angle),
        center.dy + (radius - 15) * math.sin(angle),
      );
      final markerEnd = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      canvas.drawLine(markerStart, markerEnd, markerPaint);

      // Adiciona números nas marcações
      textPainter.text = TextSpan(
        text: '$i',
        style: TextStyle(color: Colors.grey[600], fontSize: size.width * 0.04),
      );
      textPainter.layout();

      final textOffset = Offset(
        center.dx + (radius - 25) * math.cos(angle) - textPainter.width / 2,
        center.dy + (radius - 25) * math.sin(angle) - textPainter.height / 2,
      );

      textPainter.paint(canvas, textOffset);
    }
  }

  Color _getHumidityColor(double humidity) {
    if (humidity < 30) return Colors.red;
    if (humidity < 60) return Colors.orange;
    return Colors.green;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is HumidityGaugePainter &&
        oldDelegate.humidity != humidity;
  }
}

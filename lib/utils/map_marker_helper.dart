import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Creates custom BitmapDescriptor markers for the live map.
class MapMarkerHelper {
  static Future<BitmapDescriptor> createBusMarker({
    Color color = const Color(0xFF1565C0),
    double size = 96,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = color;

    final center = Offset(size / 2, size / 2);
    canvas.drawCircle(center, size / 2, paint);
    canvas.drawCircle(
      center,
      size / 2 - 3,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    final textPainter = TextPainter(
      text: const TextSpan(
        text: '🚌',
        style: TextStyle(fontSize: 42),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        (size - textPainter.width) / 2,
        (size - textPainter.height) / 2 - 2,
      ),
    );

    final image = await recorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  static Future<BitmapDescriptor> createStudentMarker({
    Color color = const Color(0xFFE53935),
    double size = 80,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2,
      Paint()..color = color,
    );
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2 - 3,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    final textPainter = TextPainter(
      text: const TextSpan(
        text: '📍',
        style: TextStyle(fontSize: 34),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        (size - textPainter.width) / 2,
        (size - textPainter.height) / 2 - 2,
      ),
    );

    final image = await recorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }
}

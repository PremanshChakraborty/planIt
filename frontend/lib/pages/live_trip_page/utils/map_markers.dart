import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapMarkers {
  MapMarkers._();

  static final Map<String, BitmapDescriptor> _cache = {};

  static const Color _primaryColor = Color(0xFF3B82F6);
  static const Color _secondaryColor = Color(0xFF22C55E);
  static const Color _tertiaryColor = Color(0xFFF97316);
  static const Color _textColor = Colors.white;

  static Future<BitmapDescriptor> getMarker({
    required int index,
    required bool isSelected,
    required bool isStart,
  }) async {
    final key = _cacheKey(index, isSelected, isStart);

    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }

    final descriptor = await _createMarker(
      index: index,
      isSelected: isSelected,
      isStart: isStart,
    );

    _cache[key] = descriptor;
    return descriptor;
  }

  /// Retrieves the cached hotel marker (scaled based on selection) or loads it from assets.
  static Future<BitmapDescriptor> getHotelMarker({
    required bool isSelected,
  }) async {
    final key = 'asset_hotel_${isSelected ? 'sel' : 'norm'}';

    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }

    final descriptor = await _createAssetMarker(
      path: 'assets/images/hotel.png',
      isSelected: isSelected,
    );

    _cache[key] = descriptor;
    return descriptor;
  }

  /// Retrieves the cached photography location marker (scaled based on selection) or loads it from assets.
  static Future<BitmapDescriptor> getPhotographyLocationMarker({
    required bool isSelected,
  }) async {
    final key = 'asset_photography_location_${isSelected ? 'sel' : 'norm'}';

    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }

    final descriptor = await _createAssetMarker(
      path: 'assets/images/photography-location.png',
      isSelected: isSelected,
    );

    _cache[key] = descriptor;
    return descriptor;
  }

  static void clearCache() {
    _cache.clear();
  }

  static String _cacheKey(int index, bool isSelected, bool isStart) {
    return 'num_${index}_${isSelected ? 'sel' : 'norm'}_${isStart ? 'start' : 'mid'}';
  }

  /// Helper to load and resize asset images for markers
  static Future<BitmapDescriptor> _createAssetMarker({
    required String path,
    required bool isSelected,
  }) async {
    // Define sizes for unselected and selected states
    final double size = isSelected ? 150.0 : 130.0;

    final ByteData data = await rootBundle.load(path);
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: size.toInt(),
    );
    final ui.FrameInfo fi = await codec.getNextFrame();

    final ByteData? byteData = await fi.image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    return BitmapDescriptor.fromBytes(
      byteData!.buffer.asUint8List(),
    );
  }

  static Future<BitmapDescriptor> _createMarker({
    required int index,
    required bool isSelected,
    required bool isStart,
  }) async {
    final Color markerColor;
    if (isSelected) {
      markerColor = _secondaryColor;
    } else if (isStart) {
      markerColor = _primaryColor;
    } else {
      markerColor = _tertiaryColor;
    }

    final double size = isSelected ? 160.0 : 140.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.30)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 6);

    canvas.drawCircle(
      Offset(size / 2 + 3, size / 2 + 4),
      size / 3.5,
      shadowPaint,
    );

    final fillPaint = Paint()
      ..color = markerColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 3.5,
      fillPaint,
    );

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 4.0 : 3.0;

    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 3.5,
      borderPaint,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: '${index + 1}',
        style: TextStyle(
          color: _textColor,
          fontSize: isSelected ? 44.0 : 40.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    textPainter.paint(
      canvas,
      Offset(
        (size - textPainter.width) / 2,
        (size - textPainter.height) / 2,
      ),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(
      byteData!.buffer.asUint8List(),
    );
  }
}

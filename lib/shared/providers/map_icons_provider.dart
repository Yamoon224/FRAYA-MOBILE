import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart' as vg;
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/utils/vehicle_ui_utils.dart';

const _driverCarSvgAssetPath =
    'assets/images/FRAYA_TAXI_Icone_couleur_voiture.svg';
const _pickupMarkerSvgAssetPath =
    'assets/images/FRAYA_TAXI_MARQUEUR_POSITION.svg';
const _destinationMarkerSvgAssetPath =
    'assets/images/FRAYA_TAXI_MARQUEUR_POSITION_2.svg';
const compactDriverCarMarkerLogicalWidth = 17.0;
const compactDriverCarMarkerLogicalHeight = 34.0;
const compactDriverCarMarkerLogicalSize = compactDriverCarMarkerLogicalWidth;
const compactUserMarkerLogicalSize = 22.0;
const compactRoutePinMarkerLogicalSize = 20.0;
const pickupMarkerLogicalWidth = 16.0;
const pickupMarkerLogicalHeight = 32.0;
const destinationMarkerLogicalWidth = 19.0;
const destinationMarkerLogicalHeight = 25.0;
const _defaultDriverCarColor = Color(0xFF9CA3AF);
final Map<String, Future<BitmapDescriptor>> _driverCarSvgIconCache = {};
final Map<String, Future<BitmapDescriptor>> _compactPinIconCache = {};

enum CompactMapPinColor { green, red, orange }

double _resolveMarkerDevicePixelRatio() {
  final views = ui.PlatformDispatcher.instance.views;
  if (views.isEmpty) return 1.0;
  final pixelRatio = views.first.devicePixelRatio;
  return pixelRatio > 0 ? pixelRatio : 1.0;
}

int _resolveMarkerRasterSize(double logicalSize) {
  return (logicalSize * _resolveMarkerDevicePixelRatio()).ceil();
}

BitmapDescriptor _buildSizedBitmapDescriptor(
  Uint8List bytes, {
  required double logicalWidth,
  required double logicalHeight,
}) {
  return BitmapDescriptor.bytes(
    bytes,
    width: logicalWidth,
    height: logicalHeight,
  );
}

Future<BitmapDescriptor?> getResizedMarker(
  String path,
  double logicalWidth,
) async {
  try {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: _resolveMarkerRasterSize(logicalWidth),
    );
    ui.FrameInfo fi = await codec.getNextFrame();
    final bytes = (await fi.image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
    return _buildSizedBitmapDescriptor(
      bytes,
      logicalWidth: logicalWidth,
      logicalHeight: logicalWidth,
    );
  } catch (e) {
    debugPrint('Error resizing marker $path: $e');
    return null;
  }
}

Future<BitmapDescriptor?> getTintedMarker(
  String path,
  double logicalWidth,
  Color color,
) async {
  try {
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: _resolveMarkerRasterSize(logicalWidth),
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final rect = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );

    canvas.drawImageRect(image, rect, rect, Paint());
    canvas.drawRect(
      rect,
      Paint()
        ..blendMode = BlendMode.srcATop
        ..color = color.withValues(alpha: 0.72),
    );

    final tintedImage = await recorder.endRecording().toImage(
      image.width,
      image.height,
    );
    final bytes = (await tintedImage.toByteData(
      format: ui.ImageByteFormat.png,
    ))?.buffer.asUint8List();

    if (bytes == null) {
      return null;
    }
    return _buildSizedBitmapDescriptor(
      bytes,
      logicalWidth: logicalWidth,
      logicalHeight: logicalWidth,
    );
  } catch (e) {
    debugPrint('Error tinting marker $path: $e');
    return null;
  }
}

Future<BitmapDescriptor?> getTintedSvgMarker({
  required String path,
  required double logicalSize,
  required Color color,
}) async {
  return getSvgMarker(
    path: path,
    logicalWidth: logicalSize,
    logicalHeight: logicalSize,
    color: color,
  );
}

Future<BitmapDescriptor?> getSvgMarker({
  required String path,
  required double logicalWidth,
  required double logicalHeight,
  Color? color,
}) async {
  try {
    final rasterWidth = _resolveMarkerRasterSize(logicalWidth);
    final rasterHeight = _resolveMarkerRasterSize(logicalHeight);
    final pictureInfo = await vg.vg.loadPicture(
      vg.SvgAssetLoader(
        path,
        theme: vg.SvgTheme(currentColor: color ?? Colors.black),
      ),
      null,
    );
    final sourceSize = pictureInfo.size;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    if (sourceSize.width > 0 && sourceSize.height > 0) {
      canvas.scale(
        rasterWidth / sourceSize.width,
        rasterHeight / sourceSize.height,
      );
    }
    canvas.drawPicture(pictureInfo.picture);

    final image = await recorder.endRecording().toImage(
      rasterWidth,
      rasterHeight,
    );
    final bytes = (await image.toByteData(
      format: ui.ImageByteFormat.png,
    ))?.buffer.asUint8List();
    if (bytes == null) {
      return null;
    }
    return _buildSizedBitmapDescriptor(
      bytes,
      logicalWidth: logicalWidth,
      logicalHeight: logicalHeight,
    );
  } catch (e) {
    debugPrint('Error loading svg marker $path: $e');
    return null;
  }
}

Future<BitmapDescriptor> getCompactPinMarker({
  required Color color,
  double logicalSize = compactRoutePinMarkerLogicalSize,
}) {
  final key =
      '${color.toARGB32().toRadixString(16)}-${logicalSize.toStringAsFixed(2)}';
  return _compactPinIconCache.putIfAbsent(
    key,
    () => _buildCompactPinMarker(color: color, logicalSize: logicalSize),
  );
}

Future<BitmapDescriptor> _buildCompactPinMarker({
  required Color color,
  required double logicalSize,
}) async {
  final rasterSize = _resolveMarkerRasterSize(logicalSize).toDouble();
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final iconData = Icons.location_on_rounded;
  final iconFontSize = rasterSize * 0.92;
  final paintOffset = Offset(0, rasterSize * 0.04);

  final shadowPainter = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: iconFontSize,
        fontFamily: iconData.fontFamily,
        package: iconData.fontPackage,
        color: Colors.black.withValues(alpha: 0.18),
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  final iconPainter = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: iconFontSize,
        fontFamily: iconData.fontFamily,
        package: iconData.fontPackage,
        color: color,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  final dx = (rasterSize - iconPainter.width) / 2;
  shadowPainter.paint(canvas, Offset(dx, 2) + paintOffset);
  iconPainter.paint(canvas, Offset(dx, 0) + paintOffset);

  final center = Offset(rasterSize / 2, rasterSize * 0.36);
  canvas.drawCircle(center, rasterSize * 0.095, Paint()..color = Colors.white);
  canvas.drawCircle(
    center,
    rasterSize * 0.042,
    Paint()..color = color.withValues(alpha: 0.9),
  );

  final image = await recorder.endRecording().toImage(
    rasterSize.ceil(),
    rasterSize.ceil(),
  );
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return _buildSizedBitmapDescriptor(
    bytes!.buffer.asUint8List(),
    logicalWidth: logicalSize,
    logicalHeight: logicalSize,
  );
}

Color compactPinColorValue(CompactMapPinColor color) => switch (color) {
  CompactMapPinColor.green => const Color(0xFF16A34A),
  CompactMapPinColor.red => const Color(0xFFEF4444),
  CompactMapPinColor.orange => const Color(0xFFF59E0B),
};

final carIconProvider = FutureProvider<BitmapDescriptor?>((ref) async {
  return await getSvgMarker(
    path: _driverCarSvgAssetPath,
    logicalWidth: compactDriverCarMarkerLogicalWidth,
    logicalHeight: compactDriverCarMarkerLogicalHeight,
    color: _defaultDriverCarColor,
  );
});

final driverCarMarkerIconProvider =
    FutureProvider.family<BitmapDescriptor, Color>((ref, color) async {
      final svgIcon = await getSvgMarker(
        path: _driverCarSvgAssetPath,
        logicalWidth: compactDriverCarMarkerLogicalWidth,
        logicalHeight: compactDriverCarMarkerLogicalHeight,
        color: color,
      );
      if (svgIcon != null) {
        return svgIcon;
      }
      return BitmapDescriptor.defaultMarkerWithHue(
        VehicleUiUtils.markerHueFromColor(color),
      );
    });

final driverCarSvgIconProvider =
    FutureProvider.family<BitmapDescriptor, String?>((ref, vehicleColorRaw) {
      final color = vehicleColorRaw == null
          ? _defaultDriverCarColor
          : VehicleUiUtils.colorFromVehicleName(vehicleColorRaw);
      final key =
          '${color.toARGB32().toRadixString(16)}'
          '-${compactDriverCarMarkerLogicalWidth.toStringAsFixed(2)}'
          '-${compactDriverCarMarkerLogicalHeight.toStringAsFixed(2)}';

      return _driverCarSvgIconCache.putIfAbsent(key, () async {
        final svgIcon = await getSvgMarker(
          path: _driverCarSvgAssetPath,
          logicalWidth: compactDriverCarMarkerLogicalWidth,
          logicalHeight: compactDriverCarMarkerLogicalHeight,
          color: color,
        );
        if (svgIcon != null) {
          return svgIcon;
        }
        return BitmapDescriptor.defaultMarkerWithHue(
          VehicleUiUtils.markerHueFromColor(color),
        );
      });
    });

final userIconProvider = FutureProvider<BitmapDescriptor>((ref) {
  return getCompactPinMarker(
    color: compactPinColorValue(CompactMapPinColor.green),
    logicalSize: compactUserMarkerLogicalSize,
  );
});

final pickupMarkerIconProvider = FutureProvider<BitmapDescriptor?>((ref) {
  return getSvgMarker(
    path: _pickupMarkerSvgAssetPath,
    logicalWidth: pickupMarkerLogicalWidth,
    logicalHeight: pickupMarkerLogicalHeight,
  );
});

final destinationMarkerIconProvider = FutureProvider<BitmapDescriptor?>((ref) {
  return getSvgMarker(
    path: _destinationMarkerSvgAssetPath,
    logicalWidth: destinationMarkerLogicalWidth,
    logicalHeight: destinationMarkerLogicalHeight,
  );
});

final compactPinMarkerIconProvider =
    FutureProvider.family<BitmapDescriptor, CompactMapPinColor>((ref, color) {
      return getCompactPinMarker(color: compactPinColorValue(color));
    });

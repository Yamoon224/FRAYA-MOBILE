import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class VehicleUiUtils {
  VehicleUiUtils._();

  static String rangeLabel(String range) {
    switch (range.toUpperCase()) {
      case 'MAGIC':
        return 'Magic';
      case 'GLADIATEUR':
        return 'Gladiateur';
      case 'ELITE':
        return 'Élite';
      default:
        return range;
    }
  }

  static IconData rangeIcon(String range) {
    switch (range.toUpperCase()) {
      case 'MAGIC':
        return Icons.auto_awesome;
      case 'GLADIATEUR':
        return Icons.shield_rounded;
      case 'ELITE':
        return Icons.diamond;
      default:
        return Icons.local_taxi;
    }
  }

  static Color rangeColor(String range) {
    switch (range.toUpperCase()) {
      case 'MAGIC':
        return const Color(0xFFFDB913);
      case 'GLADIATEUR':
        return const Color(0xFF6366F1);
      case 'ELITE':
        return const Color(0xFF3B82F6);
      default:
        return AppColors.textSecondary;
    }
  }

  static Color colorFromVehicleName(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return const Color(0xFF9CA3AF);

    final fromHex = _colorFromHex(raw);
    if (fromHex != null) return fromHex;

    final normalized = raw.toLowerCase();
    if (normalized.contains('rouge') || normalized.contains('red')) {
      return const Color(0xFFD32F2F);
    }
    if (normalized.contains('bleu') || normalized.contains('blue')) {
      return const Color(0xFF1976D2);
    }
    if (normalized.contains('vert') || normalized.contains('green')) {
      return const Color(0xFF2E7D32);
    }
    if (normalized.contains('jaune') || normalized.contains('yellow')) {
      return const Color(0xFFF9A825);
    }
    if (normalized.contains('noir') || normalized.contains('black')) {
      return const Color(0xFF212121);
    }
    if (normalized.contains('blanc') || normalized.contains('white')) {
      return const Color(0xFFECEFF1);
    }
    if (normalized.contains('gris') || normalized.contains('gray')) {
      return const Color(0xFF757575);
    }

    return const Color(0xFF9CA3AF);
  }

  static double markerHueFromColor(Color color) {
    return HSVColor.fromColor(color).hue;
  }

  static Color? _colorFromHex(String value) {
    final hex = value.replaceAll('#', '').trim();
    if (hex.length != 6 && hex.length != 8) {
      return null;
    }

    final normalized = hex.length == 6 ? 'FF$hex' : hex;
    final parsed = int.tryParse(normalized, radix: 16);
    if (parsed == null) return null;
    return Color(parsed);
  }
}

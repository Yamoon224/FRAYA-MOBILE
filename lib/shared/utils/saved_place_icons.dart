import 'package:flutter/material.dart';

class SavedPlaceIconOption {
  const SavedPlaceIconOption({
    required this.key,
    required this.icon,
    required this.label,
  });

  final String key;
  final IconData icon;
  final String label;
}

abstract final class SavedPlaceIcons {
  static const String star = 'star';
  static const String heart = 'heart';
  static const String school = 'school';
  static const String shopping = 'shopping';
  static const String gym = 'gym';
  static const String hospital = 'hospital';

  static const List<SavedPlaceIconOption> options = [
    SavedPlaceIconOption(key: star, icon: Icons.star_rounded, label: 'Favori'),
    SavedPlaceIconOption(
      key: heart,
      icon: Icons.favorite_rounded,
      label: 'Personnel',
    ),
    SavedPlaceIconOption(
      key: school,
      icon: Icons.school_rounded,
      label: 'École',
    ),
    SavedPlaceIconOption(
      key: shopping,
      icon: Icons.shopping_bag_rounded,
      label: 'Shopping',
    ),
    SavedPlaceIconOption(
      key: gym,
      icon: Icons.fitness_center_rounded,
      label: 'Sport',
    ),
    SavedPlaceIconOption(
      key: hospital,
      icon: Icons.local_hospital_rounded,
      label: 'Santé',
    ),
  ];

  static IconData iconFromKey(String? key) {
    for (final option in options) {
      if (option.key == key) return option.icon;
    }
    return Icons.star_rounded;
  }
}

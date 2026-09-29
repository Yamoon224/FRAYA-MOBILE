import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/models/places_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/map/fraya_map.dart';

class AddressPinPickerScreen extends StatefulWidget {
  const AddressPinPickerScreen({super.key, required this.initialPlace});

  final PlaceDetails initialPlace;

  @override
  State<AddressPinPickerScreen> createState() => _AddressPinPickerScreenState();
}

class _AddressPinPickerScreenState extends State<AddressPinPickerScreen> {
  late LatLng _pinPosition;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _pinPosition = LatLng(
      widget.initialPlace.latitude,
      widget.initialPlace.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Position precise'),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: FrayaMap(
              initialTarget: _pinPosition,
              initialZoom: 17,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              autoCenterOnUser: false,
              onCameraMoveStarted: () {
                if (!_isDragging) setState(() => _isDragging = true);
              },
              onCameraMove: (position) {
                _pinPosition = position.target;
              },
              onCameraIdle: () {
                if (_isDragging) setState(() => _isDragging = false);
              },
            ),
          ),
          IgnorePointer(
            child: Center(
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                offset: _isDragging ? const Offset(0, -0.12) : Offset.zero,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: AppColors.shadowMd,
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    Container(
                      width: 6,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: AppTheme.spacingLg,
            right: AppTheme.spacingLg,
            bottom: AppTheme.spacingLg,
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                boxShadow: AppColors.shadowLg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Deplace la carte pour ajuster l\'adresse',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Text(
                    'Lat: ${_pinPosition.latitude.toStringAsFixed(6)} - Lng: ${_pinPosition.longitude.toStringAsFixed(6)}',
                    style: AppTextStyles.xs.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _confirmPosition,
                      child: const Text('Confirmer cette position'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmPosition() {
    final updatedPlace = widget.initialPlace.copyWith(
      latitude: _pinPosition.latitude,
      longitude: _pinPosition.longitude,
    );
    Navigator.of(context).pop(updatedPlace);
  }
}

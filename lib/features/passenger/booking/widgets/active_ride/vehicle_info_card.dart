import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/extensions.dart';
import '../../../../../core/utils/vehicle_ui_utils.dart';
import '../../../../../domain/models/active_ride.dart';
import '../../../../../domain/models/ride_status.dart';

class VehicleInfoCard extends StatefulWidget {
  const VehicleInfoCard({super.key, required this.ride});

  final ActiveRide ride;

  @override
  State<VehicleInfoCard> createState() => _VehicleInfoCardState();
}

class _VehicleInfoCardState extends State<VehicleInfoCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.ride.status == RideStatus.arrived) _startTick();
  }

  @override
  void didUpdateWidget(VehicleInfoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ride.status == RideStatus.arrived &&
        oldWidget.ride.status != RideStatus.arrived) {
      _startTick();
    } else if (widget.ride.status != RideStatus.arrived) {
      _stopTick();
    }
  }

  void _startTick() {
    _stopTick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _stopTick() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTick();
    super.dispose();
  }

  int get _delayMinutes {
    if (widget.ride.status != RideStatus.arrived) return 0;
    if (widget.ride.arrivedAt == null) return 0;
    final elapsed = DateTime.now().difference(widget.ride.arrivedAt!).inSeconds;
    if (elapsed <= 300) return 0;
    return ((elapsed - 300) / 60).ceil();
  }

  @override
  Widget build(BuildContext context) {
    final carColor = VehicleUiUtils.colorFromVehicleName(widget.ride.carColor);
    final rangeLabel = VehicleUiUtils.rangeLabel(widget.ride.vehicleRange);
    final rangeIcon = VehicleUiUtils.rangeIcon(widget.ride.vehicleRange);
    final rangeCategoryColor = VehicleUiUtils.rangeColor(
      widget.ride.vehicleRange,
    );
    final delayMinutes = _delayMinutes;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: context.colors.greyExtraLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Véhicule',
                  style: AppTextStyles.xs.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.ride.carModel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    RotatedBox(
                      quarterTurns: 1,
                      child: SvgPicture.asset(
                        'assets/images/FRAYA_TAXI_Icone_couleur_voiture.svg',
                        theme: SvgTheme(currentColor: carColor),
                        width: 28,
                        height: 32,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.ride.carColor,
                      style: AppTextStyles.small.copyWith(
                        color: context.colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(rangeIcon, size: 16, color: rangeCategoryColor),
                    const SizedBox(width: 6),
                    Text(
                      rangeLabel,
                      style: AppTextStyles.xs.copyWith(
                        color: context.colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Plaque',
                style: AppTextStyles.xs.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
              Text(
                widget.ride.carPlate,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                'Prix estimé',
                style: AppTextStyles.xs.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
              Text(
                widget.ride.estimatedPrice.toCFA,
                style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
              ),
              if (delayMinutes > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'frais d\'attente $delayMinutes min +${delayMinutes * 100}',
                    style: AppTextStyles.xs.copyWith(
                      color: const Color(0xFFEF4444),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

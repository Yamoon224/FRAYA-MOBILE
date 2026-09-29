import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:fraya_mobile/core/models/directions_models.dart';
import 'package:fraya_mobile/core/models/ride_model.dart';
import 'package:fraya_mobile/core/theme/app_colors.dart';
import 'package:fraya_mobile/core/theme/app_text_styles.dart';
import 'package:fraya_mobile/shared/providers/map_icons_provider.dart';
import 'package:fraya_mobile/shared/widgets/map/fraya_map.dart';
import '../providers/ride_details_directions_provider.dart';

class RideDetailsMap extends ConsumerWidget {
  const RideDetailsMap({super.key, required this.ride});

  final Ride ride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final departure = LatLng(ride.departureLat, ride.departureLng);
    final arrival = LatLng(ride.arrivalLat, ride.arrivalLng);
    final departureIcon = ref.watch(pickupMarkerIconProvider).asData?.value;
    final arrivalIcon = ref.watch(destinationMarkerIconProvider).asData?.value;

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('departure'),
        position: departure,
        icon:
            departureIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        anchor: const Offset(0.5, 1),
        infoWindow: const InfoWindow(title: 'Prise en charge'),
      ),
      Marker(
        markerId: const MarkerId('arrival'),
        position: arrival,
        icon:
            arrivalIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        anchor: const Offset(0.5, 1),
        infoWindow: const InfoWindow(title: 'Destination'),
      ),
    };

    final directionsAsync = ref.watch(rideDetailsDirectionsProvider(ride));
    final routePoints =
        directionsAsync.asData?.value?.mainRoute.getPolylinePoints() ??
        const <LatLng>[];
    final hasRoutedPolyline = routePoints.length > 1;
    final polylinePoints = hasRoutedPolyline
        ? routePoints
        : [departure, arrival];
    final routeLabel = hasRoutedPolyline
        ? 'Course terminée'
        : 'Course terminée • Itinéraire approximatif';

    final polylines = <Polyline>{
      Polyline(
        polylineId: const PolylineId('route'),
        points: polylinePoints,
        color: hasRoutedPolyline
            ? const Color(0xFF4285F4)
            : const Color(0xFFD4A843),
        width: hasRoutedPolyline ? 6 : 4,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    };

    return SizedBox(
      height: 280,
      child: Stack(
        children: [
          FrayaMap(
            initialTarget: departure,
            initialZoom: 13,
            markers: markers,
            polylines: polylines,
            autoCenterOnUser: false,
            myLocationEnabled: false,
            padding: const EdgeInsets.only(top: 60),
          ),
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: AppColors.shadowSm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      routeLabel,
                      style: AppTextStyles.body.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

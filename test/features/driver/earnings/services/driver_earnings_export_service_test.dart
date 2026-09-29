import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/domain/models/driver_ride.dart';
import 'package:fraya_mobile/domain/models/ride_status.dart';
import 'package:fraya_mobile/features/driver/earnings/models/driver_earnings_summary.dart';
import 'package:fraya_mobile/features/driver/earnings/services/driver_earnings_export_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  final period = DriverEarningsExportPeriod(
    label: 'Du 01 juil. 2026 au 07 juil. 2026',
    start: DateTime(2026, 7),
    end: DateTime(2026, 7, 7),
  );

  test('builds csv with disclaimer, period totals and ride rows', () {
    final service = DriverEarningsExportService();
    final csv = service.buildCsv(
      DriverEarningsExportRequest(
        period: period,
        summary: const DriverEarningsSummary(
          completedRideCount: 2,
          totalEarnings: 7500,
          totalCommission: 1000,
          totalNetEarnings: 6500,
          totalTripMinutes: 45,
          averagePerRide: 3750,
          earningsPerTripHour: 10000,
        ),
        rides: [
          _ride(
            id: 'ride-1',
            finalPrice: 4500,
            commissionPrice: 600,
            estimatedDurationMin: 30,
          ),
          _ride(
            id: 'ride-2',
            finalPrice: 3000,
            commissionPrice: 400,
            estimatedDurationMin: 15,
          ),
        ],
      ),
    );

    expect(csv, contains(DriverEarningsExportService.disclaimer));
    expect(csv, contains('Période,Du 01 juil. 2026 au 07 juil. 2026'));
    expect(csv, contains('Courses terminées,2'));
    expect(csv, contains('Total brut FCFA,7500'));
    expect(csv, contains('Commission Fraya FCFA,1000'));
    expect(csv, contains('Gain net FCFA,6500'));
    expect(csv, contains('Temps total en course,45'));
    expect(
      csv,
      contains(
        'Date,Course,Passager,Départ,Destination,Gamme,'
        'Prix final FCFA,Commission Fraya FCFA,Gain net FCFA,Durée min',
      ),
    );
    expect(csv, contains('ride-1'));
    expect(csv, contains('4500,600,3900,30'));
  });

  test('escapes csv fields containing commas, quotes and new lines', () {
    final service = DriverEarningsExportService();
    final csv = service.buildCsv(
      DriverEarningsExportRequest(
        period: period,
        summary: const DriverEarningsSummary(
          completedRideCount: 1,
          totalEarnings: 4500,
          totalCommission: 500,
          totalNetEarnings: 4000,
          totalTripMinutes: 20,
          averagePerRide: 4500,
          earningsPerTripHour: 13500,
        ),
        rides: [
          _ride(
            id: 'ride, "special"',
            passengerName: 'Alice\nKouassi',
            pickupAddress: 'Cocody, "Deux Plateaux"',
          ),
        ],
      ),
    );

    expect(csv, contains('"ride, ""special"""'));
    expect(csv, contains('"Alice\nKouassi"'));
    expect(csv, contains('"Cocody, ""Deux Plateaux"""'));
  });

  test('builds expected file name and writes csv file', () async {
    final tempDir = Directory.systemTemp.createTempSync(
      'driver_earnings_export_test_',
    );
    addTearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });
    final service = DriverEarningsExportService(
      directoryProvider: () async => tempDir,
    );

    final result = await service.exportCsv(
      DriverEarningsExportRequest(
        period: period,
        summary: const DriverEarningsSummary(
          completedRideCount: 1,
          totalEarnings: 4500,
          totalCommission: 500,
          totalNetEarnings: 4000,
          totalTripMinutes: 20,
          averagePerRide: 4500,
          earningsPerTripHour: 13500,
        ),
        rides: [_ride()],
      ),
    );

    expect(result.fileName, 'fraya_recettes_2026-07-01_2026-07-07.csv');
    expect(File(result.path).existsSync(), isTrue);
    expect(
      File(result.path).readAsStringSync(),
      contains(DriverEarningsExportService.disclaimer),
    );
  });
}

DriverRide _ride({
  String id = 'ride-1',
  String passengerName = 'Alice Kouassi',
  String pickupAddress = 'Cocody Angre',
  double finalPrice = 4500,
  double commissionPrice = 500,
  int estimatedDurationMin = 20,
}) {
  return DriverRide(
    rideId: id,
    status: RideStatus.completed,
    passengerName: passengerName,
    pickupAddress: pickupAddress,
    destinationAddress: 'Plateau Centre',
    pickupLocation: const LatLng(5.4, -3.9),
    destinationLocation: const LatLng(5.32, -4.01),
    requestedRange: 'MAGIC',
    estimatedPrice: 3200,
    finalPrice: finalPrice,
    commissionPrice: commissionPrice,
    estimatedDurationMin: estimatedDurationMin,
    completedAt: DateTime(2026, 7, 7, 12, 30),
  );
}

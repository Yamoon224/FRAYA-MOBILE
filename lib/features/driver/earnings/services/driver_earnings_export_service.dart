library;

import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../domain/models/driver_ride.dart';
import '../../../../domain/models/driver_ride_earnings.dart';
import '../models/driver_earnings_summary.dart';

typedef DriverEarningsExportDirectoryProvider = Future<Directory> Function();

class DriverEarningsExportPeriod {
  const DriverEarningsExportPeriod({
    required this.label,
    required this.start,
    required this.end,
  });

  final String label;
  final DateTime start;
  final DateTime end;
}

class DriverEarningsExportRequest {
  const DriverEarningsExportRequest({
    required this.rides,
    required this.summary,
    required this.period,
  });

  final List<DriverRide> rides;
  final DriverEarningsSummary summary;
  final DriverEarningsExportPeriod period;
}

class DriverEarningsExportResult {
  const DriverEarningsExportResult({
    required this.path,
    required this.fileName,
  });

  final String path;
  final String fileName;
}

class DriverEarningsExportService {
  DriverEarningsExportService({
    DriverEarningsExportDirectoryProvider? directoryProvider,
  }) : _directoryProvider = directoryProvider ?? getTemporaryDirectory;

  static const disclaimer =
      'Ce fichier est un récapitulatif informatif de vos recettes Fraya. '
      'Il ne constitue pas un document comptable, fiscal ou officiel. '
      'Pour un justificatif certifié, contactez le support Fraya.';

  final DriverEarningsExportDirectoryProvider _directoryProvider;

  Future<DriverEarningsExportResult> exportCsv(
    DriverEarningsExportRequest request,
  ) async {
    final directory = await _directoryProvider();
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final fileName = buildFileName(request.period);
    final file = File('${directory.path}${Platform.pathSeparator}$fileName');
    await file.writeAsString(buildCsv(request), encoding: utf8);

    return DriverEarningsExportResult(path: file.path, fileName: fileName);
  }

  String buildCsv(DriverEarningsExportRequest request) {
    final rows = <List<Object?>>[
      ['Avertissement', disclaimer],
      ['Période', request.period.label],
      ['Courses terminées', request.summary.completedRideCount],
      ['Total brut FCFA', _formatAmount(request.summary.totalEarnings)],
      ['Commission Fraya FCFA', _formatAmount(request.summary.totalCommission)],
      ['Gain net FCFA', _formatAmount(request.summary.totalNetEarnings)],
      ['Temps total en course', request.summary.totalTripMinutes],
      const [],
      const [
        'Date',
        'Course',
        'Passager',
        'Départ',
        'Destination',
        'Gamme',
        'Prix final FCFA',
        'Commission Fraya FCFA',
        'Gain net FCFA',
        'Durée min',
      ],
    ];

    for (final ride in request.rides) {
      rows.add([
        _formatDateTime(ride.historyDate),
        ride.rideId,
        ride.passengerName,
        ride.pickupAddress,
        ride.destinationAddress,
        ride.requestedRange,
        _formatAmount(ride.driverEarningsAmount),
        _formatAmount(ride.driverCommissionAmount),
        _formatAmount(ride.driverNetEarnings),
        ride.tripDurationMinutes,
      ]);
    }

    return rows.map(_csvRow).join('\n');
  }

  String buildFileName(DriverEarningsExportPeriod period) {
    final formatter = DateFormat('yyyy-MM-dd');
    return 'fraya_recettes_${formatter.format(period.start)}_'
        '${formatter.format(period.end)}.csv';
  }

  String _csvRow(List<Object?> values) {
    return values.map(_csvCell).join(',');
  }

  String _csvCell(Object? value) {
    final text = value?.toString() ?? '';
    final mustQuote =
        text.contains(',') ||
        text.contains('"') ||
        text.contains('\n') ||
        text.contains('\r');
    final escaped = text.replaceAll('"', '""');
    return mustQuote ? '"$escaped"' : escaped;
  }

  String _formatAmount(num amount) {
    return amount.round().toString();
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return '';
    return DateFormat('yyyy-MM-dd HH:mm').format(date.toLocal());
  }
}

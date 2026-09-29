import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/utils/measurement_formatter.dart';

void main() {
  group('MeasurementFormatter.formatDistanceMeters', () {
    test('formats distances under 1 km in meters', () {
      expect(MeasurementFormatter.formatDistanceMeters(0), '0 m');
      expect(MeasurementFormatter.formatDistanceMeters(850), '850 m');
      expect(MeasurementFormatter.formatDistanceMeters(999), '999 m');
    });

    test('formats distances of 1 km and above in km with a comma', () {
      expect(MeasurementFormatter.formatDistanceMeters(1000), '1,0 km');
      expect(MeasurementFormatter.formatDistanceMeters(2400), '2,4 km');
      expect(MeasurementFormatter.formatDistanceMeters(15200), '15,2 km');
    });
  });
}

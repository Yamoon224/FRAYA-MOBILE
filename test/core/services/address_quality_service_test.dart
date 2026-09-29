import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/services/address_quality_service.dart';

void main() {
  const service = AddressQualityService();

  test('classifies detail and specific commune as complete', () {
    expect(service.assess('Avenue Aka, Cocody'), AddressQuality.complete);
  });

  test('classifies a specific commune alone as partial', () {
    expect(service.assess('Cocody'), AddressQuality.partial);
  });

  test('accepts a precise commune outside the historical list', () {
    expect(service.assess('Rue Principale, Dabou'), AddressQuality.complete);
  });

  test('classifies generic Abidjan alone as poor', () {
    expect(service.assess('Abidjan'), AddressQuality.poor);
  });

  test('removes plus code and generic locality', () {
    expect(service.sanitize('8XJV+77P, Abidjan'), isEmpty);
  });

  test('removes decimal coordinates and generic locality', () {
    expect(service.sanitize('5.345678, -4.012345, Abidjan'), isEmpty);
  });
}

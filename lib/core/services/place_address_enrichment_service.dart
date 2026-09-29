import '../models/places_models.dart';
import 'address_formatter_service.dart';
import 'address_quality_service.dart';
import 'geocoding_service.dart';

class PlaceAddressEnrichmentService {
  PlaceAddressEnrichmentService({
    GeocodingService? geocodingService,
    this.formatter = const AddressFormatterService(),
    this.qualityService = const AddressQualityService(),
  }) : _geocodingService = geocodingService ?? GeocodingService();

  final GeocodingService _geocodingService;
  final AddressFormatterService formatter;
  final AddressQualityService qualityService;

  Future<PlaceDetails> enrichIfNeeded(PlaceDetails details) async {
    final currentLabel = qualityService.subtitleFor(
      localityLabel: details.localityLabel,
      address: details.address,
      name: details.name,
    );
    if (qualityService.assess(currentLabel) == AddressQuality.complete) {
      return _withCleanLabel(details, currentLabel);
    }
    if (!details.hasValidCoordinates) {
      return _withCleanLabel(details, currentLabel);
    }

    final geocoded = await _geocodingService.resolveAddress(
      details.latitude,
      details.longitude,
    );
    if (geocoded == null) return _withCleanLabel(details, currentLabel);

    final currentParts = formatter.parse(currentLabel);
    final merged = formatter.formatLocalityLabel(
      raw: currentLabel,
      commune: geocoded.commune,
      detailCandidates: [
        currentParts.streetOrQuarter,
        geocoded.streetOrQuarter,
      ],
    );
    final mergedLabel = qualityService.sanitize(merged);
    final bestLabel = _bestLabel(currentLabel, mergedLabel);
    return _withCleanLabel(details, bestLabel);
  }

  String _bestLabel(String current, String candidate) {
    final currentScore = _qualityScore(qualityService.assess(current));
    final candidateScore = _qualityScore(qualityService.assess(candidate));
    return candidateScore >= currentScore ? candidate : current;
  }

  int _qualityScore(AddressQuality quality) => switch (quality) {
    AddressQuality.complete => 2,
    AddressQuality.partial => 1,
    AddressQuality.poor => 0,
  };

  PlaceDetails _withCleanLabel(PlaceDetails details, String label) {
    return details.copyWith(
      address: label.isNotEmpty ? label : details.name,
      localityLabel: label.isEmpty ? null : label,
      clearLocalityLabel: label.isEmpty,
    );
  }
}

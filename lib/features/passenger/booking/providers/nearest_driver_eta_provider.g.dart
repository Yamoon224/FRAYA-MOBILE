// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nearest_driver_eta_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(nearestDriverEtaMinutes)
final nearestDriverEtaMinutesProvider = NearestDriverEtaMinutesProvider._();

final class NearestDriverEtaMinutesProvider
    extends $FunctionalProvider<int?, int?, int?>
    with $Provider<int?> {
  NearestDriverEtaMinutesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nearestDriverEtaMinutesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nearestDriverEtaMinutesHash();

  @$internal
  @override
  $ProviderElement<int?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int? create(Ref ref) {
    return nearestDriverEtaMinutes(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int?>(value),
    );
  }
}

String _$nearestDriverEtaMinutesHash() =>
    r'90ea11d0358209f8231eac6589eb8771c138fff2';

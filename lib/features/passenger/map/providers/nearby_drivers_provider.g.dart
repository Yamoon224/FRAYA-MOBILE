// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nearby_drivers_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(NearbyDrivers)
final nearbyDriversProvider = NearbyDriversProvider._();

final class NearbyDriversProvider
    extends $NotifierProvider<NearbyDrivers, List<NearbyDriver>> {
  NearbyDriversProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nearbyDriversProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nearbyDriversHash();

  @$internal
  @override
  NearbyDrivers create() => NearbyDrivers();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<NearbyDriver> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<NearbyDriver>>(value),
    );
  }
}

String _$nearbyDriversHash() => r'04e9b1f73254c1a43a6fea38192ca0cd12b75f03';

abstract class _$NearbyDrivers extends $Notifier<List<NearbyDriver>> {
  List<NearbyDriver> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<NearbyDriver>, List<NearbyDriver>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<NearbyDriver>, List<NearbyDriver>>,
              List<NearbyDriver>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

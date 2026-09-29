// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RideHistory)
final rideHistoryProvider = RideHistoryProvider._();

final class RideHistoryProvider
    extends $AsyncNotifierProvider<RideHistory, List<Ride>> {
  RideHistoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'rideHistoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$rideHistoryHash();

  @$internal
  @override
  RideHistory create() => RideHistory();
}

String _$rideHistoryHash() => r'5082d256cf7ef0e886685790cbb955a684fefaea';

abstract class _$RideHistory extends $AsyncNotifier<List<Ride>> {
  FutureOr<List<Ride>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Ride>>, List<Ride>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Ride>>, List<Ride>>,
              AsyncValue<List<Ride>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(historyStats)
final historyStatsProvider = HistoryStatsProvider._();

final class HistoryStatsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, dynamic>>,
          Map<String, dynamic>,
          FutureOr<Map<String, dynamic>>
        >
    with
        $FutureModifier<Map<String, dynamic>>,
        $FutureProvider<Map<String, dynamic>> {
  HistoryStatsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'historyStatsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$historyStatsHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, dynamic>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, dynamic>> create(Ref ref) {
    return historyStats(ref);
  }
}

String _$historyStatsHash() => r'b5924dcecc85b55fe590a2407d569deec1132001';

@ProviderFor(recentRides)
final recentRidesProvider = RecentRidesProvider._();

final class RecentRidesProvider
    extends $FunctionalProvider<List<Ride>, List<Ride>, List<Ride>>
    with $Provider<List<Ride>> {
  RecentRidesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentRidesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentRidesHash();

  @$internal
  @override
  $ProviderElement<List<Ride>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Ride> create(Ref ref) {
    return recentRides(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Ride> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Ride>>(value),
    );
  }
}

String _$recentRidesHash() => r'16400e222a3eda41b45f361a8a634ce1119a7607';

@ProviderFor(allRides)
final allRidesProvider = AllRidesProvider._();

final class AllRidesProvider
    extends $FunctionalProvider<List<Ride>, List<Ride>, List<Ride>>
    with $Provider<List<Ride>> {
  AllRidesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allRidesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allRidesHash();

  @$internal
  @override
  $ProviderElement<List<Ride>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Ride> create(Ref ref) {
    return allRides(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Ride> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Ride>>(value),
    );
  }
}

String _$allRidesHash() => r'66838be40ec90a8d98005978bb7e92493df2829a';

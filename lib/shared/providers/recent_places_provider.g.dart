// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recent_places_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(recentPlacesService)
final recentPlacesServiceProvider = RecentPlacesServiceProvider._();

final class RecentPlacesServiceProvider
    extends
        $FunctionalProvider<
          RecentPlacesService,
          RecentPlacesService,
          RecentPlacesService
        >
    with $Provider<RecentPlacesService> {
  RecentPlacesServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentPlacesServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentPlacesServiceHash();

  @$internal
  @override
  $ProviderElement<RecentPlacesService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RecentPlacesService create(Ref ref) {
    return recentPlacesService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecentPlacesService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecentPlacesService>(value),
    );
  }
}

String _$recentPlacesServiceHash() =>
    r'6d6705689f1e17b40dd26cae656c7dcfc8aa0108';

/// Provider des lieux récents — lit depuis SharedPreferences.
/// keepAlive: false → se recharge à chaque ouverture du sheet.

@ProviderFor(recentPlacesList)
final recentPlacesListProvider = RecentPlacesListProvider._();

/// Provider des lieux récents — lit depuis SharedPreferences.
/// keepAlive: false → se recharge à chaque ouverture du sheet.

final class RecentPlacesListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PlaceDetails>>,
          List<PlaceDetails>,
          FutureOr<List<PlaceDetails>>
        >
    with
        $FutureModifier<List<PlaceDetails>>,
        $FutureProvider<List<PlaceDetails>> {
  /// Provider des lieux récents — lit depuis SharedPreferences.
  /// keepAlive: false → se recharge à chaque ouverture du sheet.
  RecentPlacesListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentPlacesListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentPlacesListHash();

  @$internal
  @override
  $FutureProviderElement<List<PlaceDetails>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PlaceDetails>> create(Ref ref) {
    return recentPlacesList(ref);
  }
}

String _$recentPlacesListHash() => r'a7b4b3d3dee2e6f845c4de558a693d9cf4c151ed';

/// Notifier pour ajouter/supprimer des lieux récents et invalider le cache.

@ProviderFor(RecentPlacesNotifier)
final recentPlacesProvider = RecentPlacesNotifierProvider._();

/// Notifier pour ajouter/supprimer des lieux récents et invalider le cache.
final class RecentPlacesNotifierProvider
    extends $NotifierProvider<RecentPlacesNotifier, void> {
  /// Notifier pour ajouter/supprimer des lieux récents et invalider le cache.
  RecentPlacesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentPlacesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentPlacesNotifierHash();

  @$internal
  @override
  RecentPlacesNotifier create() => RecentPlacesNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$recentPlacesNotifierHash() =>
    r'e737a5de16acb5b2b1d2b50a696bd7943ae0237a';

/// Notifier pour ajouter/supprimer des lieux récents et invalider le cache.

abstract class _$RecentPlacesNotifier extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

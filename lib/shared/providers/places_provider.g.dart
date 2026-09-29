// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'places_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(placesService)
final placesServiceProvider = PlacesServiceProvider._();

final class PlacesServiceProvider
    extends $FunctionalProvider<PlacesService, PlacesService, PlacesService>
    with $Provider<PlacesService> {
  PlacesServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'placesServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$placesServiceHash();

  @$internal
  @override
  $ProviderElement<PlacesService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PlacesService create(Ref ref) {
    return placesService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlacesService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlacesService>(value),
    );
  }
}

String _$placesServiceHash() => r'6d2c26ca6d7f50f2ab7ab7b5f1b760d5bff17309';

@ProviderFor(ActiveSearchType)
final activeSearchTypeProvider = ActiveSearchTypeProvider._();

final class ActiveSearchTypeProvider
    extends $NotifierProvider<ActiveSearchType, SearchType> {
  ActiveSearchTypeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeSearchTypeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeSearchTypeHash();

  @$internal
  @override
  ActiveSearchType create() => ActiveSearchType();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SearchType value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SearchType>(value),
    );
  }
}

String _$activeSearchTypeHash() => r'13478d50f5bdab7607558c633921acfab6e43b07';

abstract class _$ActiveSearchType extends $Notifier<SearchType> {
  SearchType build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SearchType, SearchType>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SearchType, SearchType>,
              SearchType,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(SearchQuery)
final searchQueryProvider = SearchQueryProvider._();

final class SearchQueryProvider extends $NotifierProvider<SearchQuery, String> {
  SearchQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchQueryHash();

  @$internal
  @override
  SearchQuery create() => SearchQuery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$searchQueryHash() => r'3f91faa092260f206f98c0239a174a1f32273eab';

abstract class _$SearchQuery extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(placeSuggestions)
final placeSuggestionsProvider = PlaceSuggestionsProvider._();

final class PlaceSuggestionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PlaceSuggestion>>,
          List<PlaceSuggestion>,
          Stream<List<PlaceSuggestion>>
        >
    with
        $FutureModifier<List<PlaceSuggestion>>,
        $StreamProvider<List<PlaceSuggestion>> {
  PlaceSuggestionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'placeSuggestionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$placeSuggestionsHash();

  @$internal
  @override
  $StreamProviderElement<List<PlaceSuggestion>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<PlaceSuggestion>> create(Ref ref) {
    return placeSuggestions(ref);
  }
}

String _$placeSuggestionsHash() => r'0f8c0f16dc2c6e6c0109de52104d1321a36fddbd';

@ProviderFor(SelectedPickup)
final selectedPickupProvider = SelectedPickupProvider._();

final class SelectedPickupProvider
    extends $NotifierProvider<SelectedPickup, PlaceDetails?> {
  SelectedPickupProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedPickupProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedPickupHash();

  @$internal
  @override
  SelectedPickup create() => SelectedPickup();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlaceDetails? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlaceDetails?>(value),
    );
  }
}

String _$selectedPickupHash() => r'751c794bea3367078fb158c1ba2e5e422ea0316e';

abstract class _$SelectedPickup extends $Notifier<PlaceDetails?> {
  PlaceDetails? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<PlaceDetails?, PlaceDetails?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PlaceDetails?, PlaceDetails?>,
              PlaceDetails?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(SelectedDestination)
final selectedDestinationProvider = SelectedDestinationProvider._();

final class SelectedDestinationProvider
    extends $NotifierProvider<SelectedDestination, PlaceDetails?> {
  SelectedDestinationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedDestinationProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedDestinationHash();

  @$internal
  @override
  SelectedDestination create() => SelectedDestination();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlaceDetails? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlaceDetails?>(value),
    );
  }
}

String _$selectedDestinationHash() =>
    r'e872fe566ac44a6df297450b8cc84c2514afadbd';

abstract class _$SelectedDestination extends $Notifier<PlaceDetails?> {
  PlaceDetails? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<PlaceDetails?, PlaceDetails?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PlaceDetails?, PlaceDetails?>,
              PlaceDetails?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(nearbyLandmarks)
final nearbyLandmarksProvider = NearbyLandmarksProvider._();

final class NearbyLandmarksProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PlaceDetails>>,
          List<PlaceDetails>,
          FutureOr<List<PlaceDetails>>
        >
    with
        $FutureModifier<List<PlaceDetails>>,
        $FutureProvider<List<PlaceDetails>> {
  NearbyLandmarksProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nearbyLandmarksProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nearbyLandmarksHash();

  @$internal
  @override
  $FutureProviderElement<List<PlaceDetails>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PlaceDetails>> create(Ref ref) {
    return nearbyLandmarks(ref);
  }
}

String _$nearbyLandmarksHash() => r'649bb4184c10345e721b9ca39e33bd8a6892df16';

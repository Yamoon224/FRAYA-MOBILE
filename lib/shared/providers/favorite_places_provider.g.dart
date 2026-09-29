// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_places_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(favoritePlacesService)
final favoritePlacesServiceProvider = FavoritePlacesServiceProvider._();

final class FavoritePlacesServiceProvider
    extends
        $FunctionalProvider<
          FavoritePlacesService,
          FavoritePlacesService,
          FavoritePlacesService
        >
    with $Provider<FavoritePlacesService> {
  FavoritePlacesServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favoritePlacesServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favoritePlacesServiceHash();

  @$internal
  @override
  $ProviderElement<FavoritePlacesService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FavoritePlacesService create(Ref ref) {
    return favoritePlacesService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FavoritePlacesService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FavoritePlacesService>(value),
    );
  }
}

String _$favoritePlacesServiceHash() =>
    r'78ef94387208702c653c6998c6d22b4f2bf28bb8';

@ProviderFor(favoritePlacesList)
final favoritePlacesListProvider = FavoritePlacesListProvider._();

final class FavoritePlacesListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<FavoritePlace>>,
          List<FavoritePlace>,
          FutureOr<List<FavoritePlace>>
        >
    with
        $FutureModifier<List<FavoritePlace>>,
        $FutureProvider<List<FavoritePlace>> {
  FavoritePlacesListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favoritePlacesListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favoritePlacesListHash();

  @$internal
  @override
  $FutureProviderElement<List<FavoritePlace>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<FavoritePlace>> create(Ref ref) {
    return favoritePlacesList(ref);
  }
}

String _$favoritePlacesListHash() =>
    r'779c3ca1da0cff6e42463b1f810f26a816d3bd2f';

@ProviderFor(frequentDestinations)
final frequentDestinationsProvider = FrequentDestinationsProvider._();

final class FrequentDestinationsProvider
    extends
        $FunctionalProvider<
          List<FavoritePlace>,
          List<FavoritePlace>,
          List<FavoritePlace>
        >
    with $Provider<List<FavoritePlace>> {
  FrequentDestinationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'frequentDestinationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$frequentDestinationsHash();

  @$internal
  @override
  $ProviderElement<List<FavoritePlace>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<FavoritePlace> create(Ref ref) {
    return frequentDestinations(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<FavoritePlace> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<FavoritePlace>>(value),
    );
  }
}

String _$frequentDestinationsHash() =>
    r'a617873ed6013af8ce1d7a6290066836d0cd340b';

@ProviderFor(FavoritePlacesNotifier)
final favoritePlacesProvider = FavoritePlacesNotifierProvider._();

final class FavoritePlacesNotifierProvider
    extends $NotifierProvider<FavoritePlacesNotifier, void> {
  FavoritePlacesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favoritePlacesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favoritePlacesNotifierHash();

  @$internal
  @override
  FavoritePlacesNotifier create() => FavoritePlacesNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$favoritePlacesNotifierHash() =>
    r'24280abde473316bde004d55c86c62e6594bf701';

abstract class _$FavoritePlacesNotifier extends $Notifier<void> {
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

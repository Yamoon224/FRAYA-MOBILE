// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_places_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(savedPlacesService)
final savedPlacesServiceProvider = SavedPlacesServiceProvider._();

final class SavedPlacesServiceProvider
    extends
        $FunctionalProvider<
          SavedPlacesService,
          SavedPlacesService,
          SavedPlacesService
        >
    with $Provider<SavedPlacesService> {
  SavedPlacesServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'savedPlacesServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savedPlacesServiceHash();

  @$internal
  @override
  $ProviderElement<SavedPlacesService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SavedPlacesService create(Ref ref) {
    return savedPlacesService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SavedPlacesService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SavedPlacesService>(value),
    );
  }
}

String _$savedPlacesServiceHash() =>
    r'ce58acde061c946feecd004f9dc950f6194af642';

@ProviderFor(SavedPlacesNotifier)
final savedPlacesNotifierProvider = SavedPlacesNotifierProvider._();

final class SavedPlacesNotifierProvider
    extends $AsyncNotifierProvider<SavedPlacesNotifier, List<SavedAddress>> {
  SavedPlacesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'savedPlacesNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savedPlacesNotifierHash();

  @$internal
  @override
  SavedPlacesNotifier create() => SavedPlacesNotifier();
}

String _$savedPlacesNotifierHash() =>
    r'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0';

abstract class _$SavedPlacesNotifier
    extends $AsyncNotifier<List<SavedAddress>> {
  FutureOr<List<SavedAddress>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<SavedAddress>>, List<SavedAddress>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<SavedAddress>>, List<SavedAddress>>,
              AsyncValue<List<SavedAddress>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

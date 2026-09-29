// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ride_categories_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SelectedCategory)
final selectedCategoryProvider = SelectedCategoryProvider._();

final class SelectedCategoryProvider
    extends $NotifierProvider<SelectedCategory, RideCategory?> {
  SelectedCategoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedCategoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedCategoryHash();

  @$internal
  @override
  SelectedCategory create() => SelectedCategory();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RideCategory? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RideCategory?>(value),
    );
  }
}

String _$selectedCategoryHash() => r'd59d97629eab96c54f5454f67a57eb6924fa6408';

abstract class _$SelectedCategory extends $Notifier<RideCategory?> {
  RideCategory? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<RideCategory?, RideCategory?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RideCategory?, RideCategory?>,
              RideCategory?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(rideCategories)
final rideCategoriesProvider = RideCategoriesProvider._();

final class RideCategoriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<RideCategory>>,
          List<RideCategory>,
          FutureOr<List<RideCategory>>
        >
    with
        $FutureModifier<List<RideCategory>>,
        $FutureProvider<List<RideCategory>> {
  RideCategoriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'rideCategoriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$rideCategoriesHash();

  @$internal
  @override
  $FutureProviderElement<List<RideCategory>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<RideCategory>> create(Ref ref) {
    return rideCategories(ref);
  }
}

String _$rideCategoriesHash() => r'd26c2fa50b7ab146a59bf678691ca32aec3e3a0a';

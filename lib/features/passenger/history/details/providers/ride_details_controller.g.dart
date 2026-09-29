// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ride_details_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RideDetailsController)
final rideDetailsControllerProvider = RideDetailsControllerProvider._();

final class RideDetailsControllerProvider
    extends $NotifierProvider<RideDetailsController, void> {
  RideDetailsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'rideDetailsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$rideDetailsControllerHash();

  @$internal
  @override
  RideDetailsController create() => RideDetailsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$rideDetailsControllerHash() =>
    r'fedc789294ae3f8d812d2ec015dc257c2edd1a78';

abstract class _$RideDetailsController extends $Notifier<void> {
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

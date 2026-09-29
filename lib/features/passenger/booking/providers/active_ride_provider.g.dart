// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_ride_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ActiveRideController)
final activeRideControllerProvider = ActiveRideControllerProvider._();

final class ActiveRideControllerProvider
    extends $NotifierProvider<ActiveRideController, ActiveRide?> {
  ActiveRideControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeRideControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeRideControllerHash();

  @$internal
  @override
  ActiveRideController create() => ActiveRideController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ActiveRide? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ActiveRide?>(value),
    );
  }
}

String _$activeRideControllerHash() =>
    r'f02488960f8ca6e255ab62e989fbf3ffe9245b12';

abstract class _$ActiveRideController extends $Notifier<ActiveRide?> {
  ActiveRide? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ActiveRide?, ActiveRide?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ActiveRide?, ActiveRide?>,
              ActiveRide?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

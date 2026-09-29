// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PassengerHome)
final passengerHomeProvider = PassengerHomeProvider._();

final class PassengerHomeProvider
    extends $NotifierProvider<PassengerHome, void> {
  PassengerHomeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'passengerHomeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$passengerHomeHash();

  @$internal
  @override
  PassengerHome create() => PassengerHome();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$passengerHomeHash() => r'6332c83aa723f3320a5473d48f9e46f1670a334d';

abstract class _$PassengerHome extends $Notifier<void> {
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

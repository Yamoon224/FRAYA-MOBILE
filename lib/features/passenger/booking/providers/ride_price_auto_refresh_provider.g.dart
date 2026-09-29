// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ride_price_auto_refresh_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RidePriceAutoRefresh)
final ridePriceAutoRefreshProvider = RidePriceAutoRefreshProvider._();

final class RidePriceAutoRefreshProvider
    extends $NotifierProvider<RidePriceAutoRefresh, void> {
  RidePriceAutoRefreshProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ridePriceAutoRefreshProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ridePriceAutoRefreshHash();

  @$internal
  @override
  RidePriceAutoRefresh create() => RidePriceAutoRefresh();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$ridePriceAutoRefreshHash() =>
    r'6dcf89e6f963eb97eba1483d7e20cf8fc4bee0e0';

abstract class _$RidePriceAutoRefresh extends $Notifier<void> {
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

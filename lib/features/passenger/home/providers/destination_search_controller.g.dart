// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'destination_search_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DestinationSearchController)
final destinationSearchControllerProvider =
    DestinationSearchControllerProvider._();

final class DestinationSearchControllerProvider
    extends $NotifierProvider<DestinationSearchController, void> {
  DestinationSearchControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'destinationSearchControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$destinationSearchControllerHash();

  @$internal
  @override
  DestinationSearchController create() => DestinationSearchController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$destinationSearchControllerHash() =>
    r'c24ba32a424e7b6bc1d3076f98fcd5587f9d2c4a';

abstract class _$DestinationSearchController extends $Notifier<void> {
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

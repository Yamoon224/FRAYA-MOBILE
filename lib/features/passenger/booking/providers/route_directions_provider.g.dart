// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route_directions_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(routeDirections)
final routeDirectionsProvider = RouteDirectionsProvider._();

final class RouteDirectionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<DirectionsResult?>,
          DirectionsResult?,
          FutureOr<DirectionsResult?>
        >
    with
        $FutureModifier<DirectionsResult?>,
        $FutureProvider<DirectionsResult?> {
  RouteDirectionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'routeDirectionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$routeDirectionsHash();

  @$internal
  @override
  $FutureProviderElement<DirectionsResult?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DirectionsResult?> create(Ref ref) {
    return routeDirections(ref);
  }
}

String _$routeDirectionsHash() => r'853a4c3208264bd2ab1b7512792e739273af9bf6';

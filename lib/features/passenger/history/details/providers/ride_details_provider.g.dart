// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ride_details_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(rideDetails)
final rideDetailsProvider = RideDetailsFamily._();

final class RideDetailsProvider
    extends $FunctionalProvider<AsyncValue<Ride>, Ride, FutureOr<Ride>>
    with $FutureModifier<Ride>, $FutureProvider<Ride> {
  RideDetailsProvider._({
    required RideDetailsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'rideDetailsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$rideDetailsHash();

  @override
  String toString() {
    return r'rideDetailsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Ride> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Ride> create(Ref ref) {
    final argument = this.argument as String;
    return rideDetails(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RideDetailsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$rideDetailsHash() => r'f69c77fbe9a17c89b4c5e4aa551723d9bf809778';

final class RideDetailsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Ride>, String> {
  RideDetailsFamily._()
    : super(
        retry: null,
        name: r'rideDetailsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RideDetailsProvider call(String rideId) =>
      RideDetailsProvider._(argument: rideId, from: this);

  @override
  String toString() => r'rideDetailsProvider';
}

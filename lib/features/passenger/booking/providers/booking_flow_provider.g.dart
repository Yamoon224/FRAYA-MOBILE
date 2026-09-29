// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_flow_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(bookingRepository)
final bookingRepositoryProvider = BookingRepositoryProvider._();

final class BookingRepositoryProvider
    extends
        $FunctionalProvider<
          BookingRepository,
          BookingRepository,
          BookingRepository
        >
    with $Provider<BookingRepository> {
  BookingRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bookingRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bookingRepositoryHash();

  @$internal
  @override
  $ProviderElement<BookingRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BookingRepository create(Ref ref) {
    return bookingRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BookingRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BookingRepository>(value),
    );
  }
}

String _$bookingRepositoryHash() => r'76579fe84206c79bcbdc2401bc8f5d5cf6dba080';

@ProviderFor(BookingFlow)
final bookingFlowProvider = BookingFlowProvider._();

final class BookingFlowProvider
    extends $NotifierProvider<BookingFlow, BookingFlowState> {
  BookingFlowProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bookingFlowProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bookingFlowHash();

  @$internal
  @override
  BookingFlow create() => BookingFlow();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BookingFlowState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BookingFlowState>(value),
    );
  }
}

String _$bookingFlowHash() => r'3f110c167970857ae28b7f90e81f6679aff76fe6';

abstract class _$BookingFlow extends $Notifier<BookingFlowState> {
  BookingFlowState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<BookingFlowState, BookingFlowState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BookingFlowState, BookingFlowState>,
              BookingFlowState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/features/passenger/history/details/providers/ride_details_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('throws a state error when ride details are not available', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await expectLater(
      container.read(rideDetailsProvider('missing_ride').future),
      throwsA(isA<StateError>()),
    );
  });
}

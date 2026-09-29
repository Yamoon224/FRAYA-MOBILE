import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/utils/constants.dart';
import 'package:fraya_mobile/data/sources/local_storage.dart';
import 'package:fraya_mobile/domain/usecases/passenger/auth/logout_passenger_usecase.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LogoutPassengerUsecase', () {
    test(
      'removes only passenger auth keys and keeps non-auth local data',
      () async {
        FlutterSecureStorage.setMockInitialValues({
          AppConstants.accessTokenKey: 'passenger-token',
          AppConstants.authUserDataKey: '{"id":1}',
          AppConstants.refreshTokenKey: 'refresh-token',
          AppConstants.driverAccessTokenKey: 'driver-token',
        });
        SharedPreferences.setMockInitialValues({
          AppConstants.onboardingCompleteKey: true,
        });
        await LocalStorage.instance.init();

        final usecase = LogoutPassengerUsecase();
        final result = await usecase();

        expect(result.isRight(), isTrue);
        expect(
          await LocalStorage.instance.getSecure(AppConstants.accessTokenKey),
          isNull,
        );
        expect(
          await LocalStorage.instance.getSecure(AppConstants.authUserDataKey),
          isNull,
        );
        expect(
          await LocalStorage.instance.getSecure(AppConstants.refreshTokenKey),
          isNull,
        );
        expect(
          await LocalStorage.instance.getSecure(
            AppConstants.driverAccessTokenKey,
          ),
          'driver-token',
        );
        expect(
          LocalStorage.instance.getBool(AppConstants.onboardingCompleteKey),
          isTrue,
        );
      },
    );
  });
}

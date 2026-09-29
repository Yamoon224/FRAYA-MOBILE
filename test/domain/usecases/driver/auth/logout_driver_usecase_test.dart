import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/utils/constants.dart';
import 'package:fraya_mobile/data/sources/local_storage.dart';
import 'package:fraya_mobile/domain/usecases/driver/auth/logout_driver_usecase.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LogoutDriverUseCase', () {
    test('removes only driver auth keys', () async {
      FlutterSecureStorage.setMockInitialValues({
        AppConstants.driverAccessTokenKey: 'driver-token',
        AppConstants.driverAuthUserDataKey: '{"driverId":14}',
        AppConstants.refreshTokenKey: 'refresh-token',
        AppConstants.accessTokenKey: 'passenger-token',
      });

      final usecase = LogoutDriverUseCase();
      final result = await usecase();

      expect(result.isRight(), isTrue);
      expect(
        await LocalStorage.instance.getSecure(
          AppConstants.driverAccessTokenKey,
        ),
        isNull,
      );
      expect(
        await LocalStorage.instance.getSecure(
          AppConstants.driverAuthUserDataKey,
        ),
        isNull,
      );
      expect(
        await LocalStorage.instance.getSecure(AppConstants.refreshTokenKey),
        isNull,
      );
      expect(
        await LocalStorage.instance.getSecure(AppConstants.accessTokenKey),
        'passenger-token',
      );
    });
  });
}

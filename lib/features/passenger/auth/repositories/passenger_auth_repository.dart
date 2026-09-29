import '../../../../data/sources/api_client.dart';
import '../../../../data/sources/remote/passenger_auth_remote_data_source.dart';

class PassengerAuthRepository {
  PassengerAuthRepository({
    ApiClient? apiClient,
    PassengerAuthRemoteDataSource? remoteDataSource,
  }) : _remoteDataSource =
           remoteDataSource ??
           PassengerAuthRemoteDataSource(apiClient: apiClient);

  final PassengerAuthRemoteDataSource _remoteDataSource;

  Future<Map<String, dynamic>> login(String phoneNumber, String password) {
    return _remoteDataSource.login(phoneNumber, password);
  }

  Future<void> registerStep1(String phoneNumber, {String? email}) {
    return _remoteDataSource.registerStep1(phoneNumber, email: email);
  }

  Future<void> registerStep2(String phoneNumber, String verificationCode) {
    return _remoteDataSource.registerStep2(phoneNumber, verificationCode);
  }

  Future<Map<String, dynamic>> registerStep3(Map<String, dynamic> userData) {
    return _remoteDataSource.registerStep3(userData);
  }
}

library;

import '../../domain/repositories/driver_auth_repository.dart';
import '../sources/remote/driver_auth_remote_data_source.dart';

class DriverAuthRepositoryImpl implements DriverAuthRepository {
  DriverAuthRepositoryImpl({
    required DriverAuthRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final DriverAuthRemoteDataSource _remoteDataSource;

  @override
  Future<Map<String, dynamic>> login(String phoneNumber, String password) {
    return _remoteDataSource.login(phoneNumber, password);
  }

  @override
  Future<void> registerStep1(String phoneNumber, {String? email}) {
    return _remoteDataSource.registerStep1(phoneNumber, email: email);
  }

  @override
  Future<void> registerStep2(String phoneNumber, String verificationCode) {
    return _remoteDataSource.registerStep2(phoneNumber, verificationCode);
  }

  @override
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) {
    return _remoteDataSource.register(userData);
  }

  @override
  Future<Map<String, dynamic>> fetchProfile() {
    return _remoteDataSource.fetchProfile();
  }
}

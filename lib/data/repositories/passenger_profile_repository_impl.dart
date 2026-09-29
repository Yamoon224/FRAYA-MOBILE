library;

import '../../domain/repositories/passenger_profile_repository.dart';
import '../sources/remote/passenger_profile_remote_data_source.dart';

class PassengerProfileRepositoryImpl implements PassengerProfileRepository {
  PassengerProfileRepositoryImpl({
    required PassengerProfileRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final PassengerProfileRemoteDataSource _remoteDataSource;

  @override
  Future<Map<String, dynamic>> getProfile() {
    return _remoteDataSource.getProfile();
  }

  @override
  Future<Map<String, dynamic>> updateProfile({
    required int userId,
    required Map<String, dynamic> data,
  }) {
    return _remoteDataSource.updateProfile(userId: userId, data: data);
  }

  @override
  Future<Map<String, dynamic>> updateProfilePhoto({
    required int userId,
    required String filePath,
    required String fileName,
  }) {
    return _remoteDataSource.updateProfilePhoto(
      userId: userId,
      filePath: filePath,
      fileName: fileName,
    );
  }

  @override
  Future<void> requestPhoneChange(String newPhoneNumber) {
    return _remoteDataSource.requestPhoneChange(newPhoneNumber);
  }

  @override
  Future<void> confirmPhoneChange(String verificationCode) {
    return _remoteDataSource.confirmPhoneChange(verificationCode);
  }
}

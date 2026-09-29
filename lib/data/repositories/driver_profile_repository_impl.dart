library;

import '../../domain/repositories/driver_profile_repository.dart';
import '../sources/remote/driver_profile_remote_data_source.dart';

class DriverProfileRepositoryImpl implements DriverProfileRepository {
  DriverProfileRepositoryImpl({
    required DriverProfileRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final DriverProfileRemoteDataSource _remoteDataSource;

  @override
  Future<Map<String, dynamic>> updateProfile({
    required int userId,
    required Map<String, dynamic> data,
  }) => _remoteDataSource.updateProfile(userId: userId, data: data);

  @override
  Future<Map<String, dynamic>> updateProfilePhoto({
    required int userId,
    required String filePath,
    required String fileName,
  }) => _remoteDataSource.updateProfilePhoto(
    userId: userId,
    filePath: filePath,
    fileName: fileName,
  );

  @override
  Future<void> requestPhoneChange(String newPhoneNumber) =>
      _remoteDataSource.requestPhoneChange(newPhoneNumber);

  @override
  Future<void> confirmPhoneChange(String verificationCode) =>
      _remoteDataSource.confirmPhoneChange(verificationCode);
}

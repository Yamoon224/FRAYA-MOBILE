library;

abstract class DriverProfileRepository {
  Future<Map<String, dynamic>> updateProfile({
    required int userId,
    required Map<String, dynamic> data,
  });

  Future<Map<String, dynamic>> updateProfilePhoto({
    required int userId,
    required String filePath,
    required String fileName,
  });

  Future<void> requestPhoneChange(String newPhoneNumber);

  Future<void> confirmPhoneChange(String verificationCode);
}

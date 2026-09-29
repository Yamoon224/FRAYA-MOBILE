library;

abstract class DriverAuthRepository {
  Future<Map<String, dynamic>> login(String phoneNumber, String password);

  Future<void> registerStep1(String phoneNumber, {String? email});

  Future<void> registerStep2(String phoneNumber, String verificationCode);

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData);

  Future<Map<String, dynamic>> fetchProfile();
}

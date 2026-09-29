import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/data/repositories/passenger_profile_repository_impl.dart';
import 'package:fraya_mobile/data/sources/remote/passenger_profile_remote_data_source.dart';

class FakePassengerProfileRemoteDataSource
    extends PassengerProfileRemoteDataSource {
  FakePassengerProfileRemoteDataSource({
    this.profile = const {'id': 8},
    this.updatedProfile = const {'firstNames': 'Jean'},
    this.updatedPhoto = const {'profilePhoto': '/uploads/profile.jpg'},
  }) : super(dio: Dio());

  final Map<String, dynamic> profile;
  final Map<String, dynamic> updatedProfile;
  final Map<String, dynamic> updatedPhoto;

  @override
  Future<Map<String, dynamic>> getProfile() async => profile;

  @override
  Future<Map<String, dynamic>> updateProfile({
    required int userId,
    required Map<String, dynamic> data,
  }) async => updatedProfile;

  @override
  Future<Map<String, dynamic>> updateProfilePhoto({
    required int userId,
    required String filePath,
    required String fileName,
  }) async => updatedPhoto;
}

void main() {
  group('PassengerProfileRepositoryImpl', () {
    test('delegates get profile to remote data source', () async {
      final repository = PassengerProfileRepositoryImpl(
        remoteDataSource: FakePassengerProfileRemoteDataSource(
          profile: const {'id': 99, 'firstNames': 'Awa'},
        ),
      );

      final profile = await repository.getProfile();

      expect(profile['id'], 99);
      expect(profile['firstNames'], 'Awa');
    });

    test('delegates photo update to remote data source', () async {
      final repository = PassengerProfileRepositoryImpl(
        remoteDataSource: FakePassengerProfileRemoteDataSource(),
      );

      final response = await repository.updateProfilePhoto(
        userId: 8,
        filePath: '/tmp/profile.jpg',
        fileName: 'profile.jpg',
      );

      expect(response['profilePhoto'], '/uploads/profile.jpg');
    });
  });
}

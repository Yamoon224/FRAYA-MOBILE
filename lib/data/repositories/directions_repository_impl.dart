import '../../core/models/directions_models.dart';
import '../../domain/repositories/directions_repository.dart';
import '../sources/remote/directions_remote_data_source.dart';

class DirectionsRepositoryImpl implements DirectionsRepository {
  DirectionsRepositoryImpl({
    required DirectionsRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final DirectionsRemoteDataSource _remoteDataSource;

  @override
  Future<DirectionsResult?> getRouteDirections(
    GetRouteDirectionsParams params,
  ) {
    return _remoteDataSource.getDirections(
      origin: params.origin,
      destination: params.destination,
      language: params.language,
      includeAlternativeRoutes: params.includeAlternativeRoutes,
    );
  }
}

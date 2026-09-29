import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/repositories/directions_repository_impl.dart';
import '../../../../data/sources/remote/directions_remote_data_source.dart';
import '../../../../domain/repositories/directions_repository.dart';
import '../../../../domain/usecases/passenger/get_route_directions.dart';

final directionsRemoteDataSourceProvider = Provider<DirectionsRemoteDataSource>(
  (ref) => DirectionsRemoteDataSource(),
);

final directionsRepositoryProvider = Provider<DirectionsRepository>((ref) {
  final remoteDataSource = ref.watch(directionsRemoteDataSourceProvider);
  return DirectionsRepositoryImpl(remoteDataSource: remoteDataSource);
});

final getRouteDirectionsUseCaseProvider = Provider<GetRouteDirectionsUseCase>((
  ref,
) {
  final repository = ref.watch(directionsRepositoryProvider);
  return GetRouteDirectionsUseCase(repository);
});

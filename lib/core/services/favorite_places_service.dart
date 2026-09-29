import '../../data/sources/local/passenger_favorites_local_data_source.dart';
import '../models/favorite_place.dart';

class FavoritePlacesService {
  FavoritePlacesService({required String userId})
    : _local = PassengerFavoritesLocalDataSource(userId);

  final PassengerFavoritesLocalDataSource _local;

  Future<List<FavoritePlace>> getAll() => _local.getAll();

  Future<void> save(FavoritePlace place) => _local.save(place);

  Future<void> remove(String id) => _local.remove(id);

  Future<bool> isFavorite(String placeId) async {
    return (await getAll()).any((e) => e.placeId == placeId);
  }
}

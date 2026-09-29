import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/models/places_models.dart';
import '../../core/services/saved_places_service.dart';
import '../../features/passenger/auth/providers/passenger_auth_provider.dart';
import '../../features/passenger/auth/providers/passenger_auth_user_id.dart';

export '../../core/models/places_models.dart' show SavedAddress, SavedAddressType;

part 'saved_places_provider.g.dart';

@riverpod
SavedPlacesService savedPlacesService(Ref ref) {
  final userData = ref.watch(passengerAuthProvider).userData;
  final userId = passengerAuthUserIdFromData(userData)?.toString() ?? 'guest';
  return SavedPlacesService(userId);
}

@riverpod
class SavedPlacesNotifier extends _$SavedPlacesNotifier {
  @override
  Future<List<SavedAddress>> build() async {
    final service = ref.read(savedPlacesServiceProvider);
    return service.getAll();
  }

  Future<void> save(SavedAddress address) async {
    final service = ref.read(savedPlacesServiceProvider);
    // Mise à jour optimiste : affichage immédiat avant la réponse backend
    final current = state.asData?.value ?? [];
    state = AsyncData(_merge(current, address));
    // Persistance (remote + cache)
    await service.save(address);
    // Rafraîchit depuis le cache local (contient l'id backend réel)
    state = AsyncData(await service.getCachedAddresses());
  }

  Future<void> remove(String id) async {
    final service = ref.read(savedPlacesServiceProvider);
    // Mise à jour optimiste
    final current = state.asData?.value ?? [];
    state = AsyncData(current.where((a) => a.id != id).toList());
    await service.remove(id);
  }

  List<SavedAddress> _merge(List<SavedAddress> current, SavedAddress address) {
    final updated = List<SavedAddress>.from(current);
    if (address.type == SavedAddressType.home ||
        address.type == SavedAddressType.work) {
      updated.removeWhere((a) => a.type == address.type);
    } else {
      updated.removeWhere((a) => a.id == address.id);
    }
    updated.add(address);
    return updated;
  }
}

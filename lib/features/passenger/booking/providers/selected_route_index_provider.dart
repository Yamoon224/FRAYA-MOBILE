import 'package:flutter_riverpod/legacy.dart';

final selectedRouteIndexProvider = StateProvider<int>((ref) => 0);

extension SelectedRouteIndexX on StateController<int> {
  void setIndex(int index) => state = index;
}

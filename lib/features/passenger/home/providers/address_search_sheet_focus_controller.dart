import 'package:flutter_riverpod/legacy.dart';

import '../../../../shared/providers/places_provider.dart';

class AddressSearchSheetFocusRequest {
  const AddressSearchSheetFocusRequest({
    required this.requestId,
    required this.target,
    required this.selectAllOnFocus,
  });

  final int requestId;
  final SearchType target;
  final bool selectAllOnFocus;
}

final addressSearchSheetFocusControllerProvider = StateNotifierProvider<
  AddressSearchSheetFocusController,
  AddressSearchSheetFocusRequest?
>((ref) => AddressSearchSheetFocusController());

class AddressSearchSheetFocusController
    extends StateNotifier<AddressSearchSheetFocusRequest?> {
  AddressSearchSheetFocusController() : super(null);

  int _nextRequestId = 0;

  void requestFocus(
    SearchType target, {
    bool selectAllOnFocus = true,
  }) {
    _nextRequestId++;
    state = AddressSearchSheetFocusRequest(
      requestId: _nextRequestId,
      target: target,
      selectAllOnFocus: selectAllOnFocus,
    );
  }

  void clear() {
    state = null;
  }
}

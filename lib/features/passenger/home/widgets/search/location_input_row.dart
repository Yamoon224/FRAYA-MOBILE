import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '/../../../../core/theme/app_colors.dart';
import '/../../../../core/theme/app_text_styles.dart';
import '/../../../../shared/providers/places_provider.dart';
import 'package:fraya_mobile/core/utils/extensions.dart';
import 'package:fraya_mobile/shared/widgets/fraya_skeleton.dart';
import '../../providers/address_search_sheet_focus_controller.dart';
import 'location_input_row_parts.dart';

class LocationInputRow extends ConsumerStatefulWidget {
  const LocationInputRow({
    super.key,
    required this.label,
    required this.color,
    required this.type,
    required this.hint,
    this.value,
    this.isCircle = false,
    this.isLoading = false,
    this.isCustom = false,
  });

  final String label;
  final String? value;
  final Color color;
  final bool isCircle;
  final SearchType type;
  final String hint;
  final bool isLoading;
  final bool isCustom;

  @override
  ConsumerState<LocationInputRow> createState() => _LocationInputRowState();
}

class _LocationInputRowState extends ConsumerState<LocationInputRow> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  ProviderSubscription<AddressSearchSheetFocusRequest?>? _focusSubscription;
  int? _handledRequestId;
  bool _showClearIcon = false;
  bool _suppressExternalValueSync = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode()..addListener(_handleFocusChange);
    _focusSubscription = ref.listenManual(
      addressSearchSheetFocusControllerProvider,
      (_, next) => _applyFocusRequest(next),
    );
    _applyFocusRequest(ref.read(addressSearchSheetFocusControllerProvider));
  }

  @override
  void didUpdateWidget(covariant LocationInputRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_shouldKeepClearedPickupText()) {
      return;
    }
    _suppressExternalValueSync = false;
    if (widget.value != oldWidget.value && widget.value != _controller.text) {
      _controller.text = widget.value ?? '';
    }
  }

  @override
  void dispose() {
    _focusSubscription?.close();
    _focusNode.removeListener(_handleFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    final hasFocus = _focusNode.hasFocus;
    if (!hasFocus && widget.type == SearchType.pickup) {
      _restoreBaselineTextIfEmpty();
    }
    setState(() {
      _showClearIcon = hasFocus && _controller.text.isNotEmpty;
    });
  }

  void _applyFocusRequest(AddressSearchSheetFocusRequest? request) {
    if (request == null || request.target != widget.type) return;
    if (_handledRequestId == request.requestId) return;
    _handledRequestId = request.requestId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
      final text = _controller.text;
      if (!request.selectAllOnFocus || text.isEmpty) return;
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: text.length,
      );
    });
  }

  void _setActiveType() {
    ref.read(activeSearchTypeProvider.notifier).setType(widget.type);
  }

  bool _shouldKeepClearedPickupText() {
    return _suppressExternalValueSync &&
        widget.type == SearchType.pickup &&
        !widget.isCustom &&
        _controller.text.isEmpty;
  }

  bool get _isPickupEdited {
    if (widget.type != SearchType.pickup) return false;
    final baseline = (widget.value ?? '').trim();
    final current = _controller.text.trim();
    return current.isNotEmpty && current != baseline;
  }

  void _clearField() {
    setState(() {
      _showClearIcon = false;
      _suppressExternalValueSync = widget.type == SearchType.pickup;
    });
    _controller.clear();
    ref.read(searchQueryProvider.notifier).clear();
    if (widget.type == SearchType.pickup) {
      ref.read(selectedPickupProvider.notifier).clear();
    } else {
      ref.read(selectedDestinationProvider.notifier).clear();
    }
    _setActiveType();
    _focusNode.requestFocus();
  }

  void _restoreBaselineTextIfEmpty() {
    if (widget.isCustom) return;
    if (_controller.text.trim().isNotEmpty) return;
    _controller.text = widget.value ?? '';
    _suppressExternalValueSync = false;
  }

  void _restorePickupFromCurrentLocation() {
    ref.read(selectedPickupProvider.notifier).clear();
    ref.read(searchQueryProvider.notifier).clear();
    ref.read(activeSearchTypeProvider.notifier).setType(SearchType.destination);
    if (!widget.isCustom) {
      _controller.text = widget.value ?? '';
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDestination = ref.watch(selectedDestinationProvider);
    final currentQuery = ref.watch(searchQueryProvider);
    final showDestinationConfirm =
        widget.type == SearchType.destination &&
        selectedDestination != null &&
        currentQuery.isEmpty;
    final showPickupEmptyFocus =
        widget.type == SearchType.pickup &&
        _controller.text.trim().isEmpty &&
        _focusNode.hasFocus;
    final showPickupRestore =
        widget.type == SearchType.pickup &&
        (widget.isCustom || _isPickupEdited || showPickupEmptyFocus);
    final showClearIcon =
        _showClearIcon &&
        !showDestinationConfirm &&
        !showPickupRestore &&
        _controller.text.isNotEmpty;
    final trailingAction = buildLocationInputTrailingAction(
      context: context,
      ref: ref,
      showClearIcon: showClearIcon,
      showDestinationConfirm: showDestinationConfirm,
      showPickupRestore: showPickupRestore,
      selectedDestination: selectedDestination,
      searchType: SearchType.destination,
      onClear: _clearField,
      onPickupRestore: _restorePickupFromCurrentLocation,
    );

    return Row(
      children: [
        LocationInputIndicator(color: widget.color, isCircle: widget.isCircle),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.label,
                style: AppTextStyles.xs.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
              widget.isLoading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: SkeletonText(width: 200, height: 16),
                    )
                  : TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      textAlignVertical: TextAlignVertical.center,
                      onTap: _setActiveType,
                      onChanged: (val) {
                        _setActiveType();
                        if (_showClearIcon ||
                            widget.type == SearchType.pickup) {
                          setState(() {
                            _showClearIcon = false;
                            _suppressExternalValueSync = false;
                          });
                        }
                        ref.read(searchQueryProvider.notifier).updateQuery(val);
                      },
                      decoration: InputDecoration(
                        hintText: widget.hint,
                        hintStyle: AppTextStyles.body.copyWith(
                          color: context.colors.textTertiary,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                        suffixIconConstraints: const BoxConstraints.tightFor(
                          width: kLocationInputTrailingSlotSize,
                          height: kLocationInputTrailingSlotSize,
                        ),
                        suffixIcon: trailingAction,
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }
}

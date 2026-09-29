import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

abstract final class AppSnackBar {
  static OverlayEntry? _topEntry;

  static void dismissCurrentTopOverlay() {
    if (_topEntry?.mounted ?? false) {
      _topEntry?.remove();
    }
    _topEntry = null;
  }

  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 10),
    bool atTop = true,
  }) {
    _show(
      context,
      message: message,
      icon: Icons.error_outline_rounded,
      backgroundColor: AppColors.error,
      duration: duration,
      atTop: atTop,
    );
  }

  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    bool atTop = false,
  }) {
    _show(
      context,
      message: message,
      icon: Icons.check_circle_outline_rounded,
      backgroundColor: AppColors.success,
      duration: duration,
      atTop: atTop,
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    bool atTop = false,
  }) {
    _show(
      context,
      message: message,
      icon: Icons.info_outline_rounded,
      backgroundColor: AppColors.info,
      duration: duration,
      atTop: atTop,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Duration duration,
    required bool atTop,
  }) {
    if (atTop) {
      _showTopOverlay(
        context,
        message: message,
        icon: icon,
        backgroundColor: backgroundColor,
        duration: duration,
      );
      return;
    }

    final margin = atTop
        ? EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 12, 16, 0)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 12);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: duration,
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: margin,
          dismissDirection: atTop ? DismissDirection.up : DismissDirection.down,
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  static void _showTopOverlay(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Duration duration,
  }) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    dismissCurrentTopOverlay();

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: MediaQuery.paddingOf(context).top + 12,
          left: 16,
          right: 16,
          child: _TopSnackBar(
            message: message,
            icon: icon,
            backgroundColor: backgroundColor,
            onDismiss: () {
              if (entry.mounted) entry.remove();
              if (_topEntry == entry) _topEntry = null;
            },
          ),
        );
      },
    );

    _topEntry = entry;
    overlay.insert(entry);
    Future<void>.delayed(duration, () {
      if (entry.mounted) entry.remove();
      if (_topEntry == entry) _topEntry = null;
    });
  }
}

class _TopSnackBar extends StatelessWidget {
  const _TopSnackBar({
    required this.message,
    required this.icon,
    required this.backgroundColor,
    required this.onDismiss,
  });

  final String message;
  final IconData icon;
  final Color backgroundColor;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.up,
      onDismissed: (_) => onDismiss(),
      child: Material(
        color: Colors.transparent,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

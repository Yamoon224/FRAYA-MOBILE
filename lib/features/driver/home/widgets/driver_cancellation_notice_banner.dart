import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/cancellation_reason_note.dart';
import '../providers/driver_cancellation_notice_provider.dart';

/// Rappelle au chauffeur qu'une course a été annulée par le passager, avec le motif.
class DriverCancellationNoticeBanner extends ConsumerWidget {
  const DriverCancellationNoticeBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notice = ref.watch(driverCancellationNoticeProvider);
    if (notice == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        key: const Key('driver_cancellation_notice'),
        color: Theme.of(context).colorScheme.surface,
        elevation: 3,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 0, 8),
                child: CancellationReasonNote(
                  cancelledBy: 'PASSENGER',
                  reason: notice.reason,
                  viewer: CancellationViewer.driver,
                ),
              ),
            ),
            IconButton(
              key: const Key('driver_cancellation_notice_close'),
              tooltip: 'Fermer',
              onPressed: () =>
                  ref.read(driverCancellationNoticeProvider.notifier).state =
                      null,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

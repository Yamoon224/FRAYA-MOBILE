part of 'driver_home_active_ride_card_parts.dart';

class DriverHomeActiveRideSummaryPanel extends StatelessWidget {
  const DriverHomeActiveRideSummaryPanel({
    super.key,
    required this.distance,
    required this.duration,
    required this.amount,
  });

  final String distance;
  final String duration;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _MetricItem(label: 'Distance', value: distance),
          ),
          const _MetricDivider(),
          Expanded(
            child: _MetricItem(label: 'Temps', value: duration),
          ),
          const _MetricDivider(),
          Expanded(
            child: _MetricItem(
              label: 'Montant',
              value: amount,
              valueColor: const Color(0xFFBE8A10),
            ),
          ),
        ],
      ),
    );
  }
}

class DriverHomeActiveRideWaitingTimePanel extends StatefulWidget {
  const DriverHomeActiveRideWaitingTimePanel({
    super.key,
    required this.arrivedAt,
  });

  final DateTime? arrivedAt;

  @override
  State<DriverHomeActiveRideWaitingTimePanel> createState() =>
      _DriverHomeActiveRideWaitingTimePanelState();
}

class _DriverHomeActiveRideWaitingTimePanelState
    extends State<DriverHomeActiveRideWaitingTimePanel> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int get _secondsElapsed {
    if (widget.arrivedAt == null) return 0;
    final elapsed = DateTime.now().difference(widget.arrivedAt!).inSeconds;
    return elapsed < 0 ? 0 : elapsed;
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  _WaitPhase get _phase {
    final s = _secondsElapsed;
    if (s <= 180) return _WaitPhase.green;
    if (s <= 285) return _WaitPhase.yellow;
    return _WaitPhase.red;
  }

  _WaitPalette get _palette {
    switch (_phase) {
      case _WaitPhase.green:
        return const _WaitPalette(
          background: Color(0xFFCFF3DA),
          border: Color(0xFF16A34A),
          iconBackground: Color(0xFFDCFCE7),
          icon: Color(0xFF16A34A),
          timer: Color(0xFF15803D),
        );
      case _WaitPhase.yellow:
        return const _WaitPalette(
          background: Color(0xFFF3F2E8),
          border: Color(0xFFE5CE73),
          iconBackground: Color(0xFFFFF3CD),
          icon: Color(0xFFBE8A10),
          timer: Color(0xFFBE8A10),
        );
      case _WaitPhase.red:
        return const _WaitPalette(
          background: Color(0xFFFFE4E4),
          border: Color(0xFFEF4444),
          iconBackground: Color(0xFFFEE2E2),
          icon: Color(0xFFDC2626),
          timer: Color(0xFFDC2626),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = _palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Container(
            height: 28,
            width: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.iconBackground,
            ),
            child: Icon(
              Icons.access_time_rounded,
              size: 17,
              color: palette.icon,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Temps d attente',
                  style: AppTextStyles.h4.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  '5 min gratuites, puis 100 FCFA/min',
                  style: AppTextStyles.small.copyWith(
                    color: const Color(0xFF676767),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatDuration(_secondsElapsed),
            style: AppTextStyles.h1.copyWith(
              fontSize: context.responsiveValue<double>(
                compact: 20,
                phone: 26,
                largePhone: 26,
                tablet: 30,
              ),
              color: palette.timer,
            ),
          ),
        ],
      ),
    );
  }
}

enum _WaitPhase { green, yellow, red }

class _WaitPalette {
  const _WaitPalette({
    required this.background,
    required this.border,
    required this.iconBackground,
    required this.icon,
    required this.timer,
  });

  final Color background;
  final Color border;
  final Color iconBackground;
  final Color icon;
  final Color timer;
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.label,
    required this.value,
    this.valueColor = const Color(0xFF202020),
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTextStyles.small.copyWith(
            color: const Color(0xFF818181),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.h1.copyWith(fontSize: 13.5, color: valueColor),
        ),
      ],
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      color: const Color(0xFFE2E2E2),
      margin: const EdgeInsets.symmetric(horizontal: 6),
    );
  }
}

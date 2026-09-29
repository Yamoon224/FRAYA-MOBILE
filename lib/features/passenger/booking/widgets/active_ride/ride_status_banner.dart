import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fraya_mobile/domain/models/ride_status.dart';

import '/../../../../core/theme/app_colors.dart';
import '/../../../../core/theme/app_text_styles.dart';
import '/../../../../core/theme/app_theme.dart';
import '/../../../../core/utils/extensions.dart';

class RideStatusBanner extends StatefulWidget {
  const RideStatusBanner({
    super.key,
    required this.status,
    this.arrivedAt,
    this.distance,
    this.onClose,
  });

  final RideStatus status;
  final DateTime? arrivedAt;
  final String? distance;
  final VoidCallback? onClose;

  @override
  State<RideStatusBanner> createState() => _RideStatusBannerState();
}

class _RideStatusBannerState extends State<RideStatusBanner> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.status == RideStatus.arrived) _startTick();
  }

  @override
  void didUpdateWidget(RideStatusBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status == RideStatus.arrived &&
        oldWidget.status != RideStatus.arrived) {
      _startTick();
    } else if (widget.status != RideStatus.arrived) {
      _stopTick();
    }
  }

  void _startTick() {
    _stopTick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _stopTick() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTick();
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

  LinearGradient get _timerGradient {
    switch (_phase) {
      case _WaitPhase.green:
        return AppColors.successGradient;
      case _WaitPhase.yellow:
        return const LinearGradient(
          colors: [Color(0xFFF5C842), Color(0xFFE5A800)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case _WaitPhase.red:
        return const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.status != RideStatus.accepted &&
        widget.status != RideStatus.arrived) {
      return const SizedBox.shrink();
    }

    final isArrived = widget.status == RideStatus.arrived;
    final gradient = isArrived ? _timerGradient : AppColors.goldGradient;
    final icon = isArrived
        ? Icons.check_circle_outline
        : Icons.location_on_outlined;
    final title = isArrived
        ? 'Votre chauffeur est arrivé !'
        : 'Le chauffeur approche !';
    final subtitle = isArrived ? 'Il vous attend' : _approachSubtitle();
    final titleColor = isArrived ? Colors.white : context.colors.textPrimary;
    final subtitleColor = isArrived
        ? Colors.white.withValues(alpha: 0.9)
        : context.colors.textPrimary.withValues(alpha: 0.86);
    final iconBackground = isArrived
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.white.withValues(alpha: 0.45);
    final iconColor = isArrived ? Colors.white : context.colors.textPrimary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppColors.shadowMd,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.small.copyWith(color: subtitleColor),
                    ),
                  ],
                ),
              ),
              if (widget.onClose != null)
                IconButton(
                  icon: Icon(Icons.close, color: titleColor, size: 20),
                  onPressed: widget.onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          if (isArrived) ...[
            const SizedBox(height: AppTheme.spacingLg),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Temps d\'attente',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.small.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _formatDuration(_secondsElapsed),
                        style: AppTextStyles.body.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: Colors.white70,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _freeWaitText(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.xs.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _freeWaitText() {
    const freePeriod = 300;
    final remaining = max(0, freePeriod - _secondsElapsed);
    if (remaining <= 0) return 'Attente facturée : 100 FCFA/min';
    final m = (remaining / 60).floor();
    final s = remaining % 60;
    final label = m > 0 ? '${m}min ${s.toString().padLeft(2, '0')}s' : '${s}s';
    return 'Attente gratuite : $label restantes';
  }

  String _approachSubtitle() {
    final distance = widget.distance?.trim();
    if (distance == null || distance.isEmpty || distance == '--') {
      return 'Distance en cours de calcul';
    }
    return 'A environ $distance de vous';
  }
}

enum _WaitPhase { green, yellow, red }

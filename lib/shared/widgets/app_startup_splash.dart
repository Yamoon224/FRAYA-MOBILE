import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

class AppStartupSplash extends StatefulWidget {
  const AppStartupSplash({
    required this.child,
    this.assetPath = defaultAssetPath,
    super.key,
  });

  static const String defaultAssetPath = 'assets/images/Fraya_Taxi_splash.json';
  static const Duration fadeDuration = Duration(milliseconds: 250);

  final Widget child;
  final String assetPath;

  @override
  State<AppStartupSplash> createState() => _AppStartupSplashState();
}

class _AppStartupSplashState extends State<AppStartupSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  bool _isOverlayVisible = true;
  bool _isOverlayOpaque = true;
  bool _hasStarted = false;
  bool _dismissalScheduled = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this)
      ..addStatusListener(_handleAnimationStatus);
  }

  @override
  void dispose() {
    _animationController
      ..removeStatusListener(_handleAnimationStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_isOverlayVisible)
          AnimatedOpacity(
            key: const ValueKey('app-startup-splash-overlay'),
            opacity: _isOverlayOpaque ? 1 : 0,
            duration: AppStartupSplash.fadeDuration,
            onEnd: _removeFadedOverlay,
            child: AbsorbPointer(
              child: AnnotatedRegion<SystemUiOverlayStyle>(
                value: _splashSystemUiStyle,
                child: ColoredBox(
                  color: Colors.black,
                  child: Lottie.asset(
                    widget.assetPath,
                    key: const ValueKey('app-startup-splash-animation'),
                    controller: _animationController,
                    fit: BoxFit.cover,
                    repeat: false,
                    onLoaded: _startAnimation,
                    errorBuilder: _buildAnimationError,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _startAnimation(LottieComposition composition) {
    if (_hasStarted) return;
    _hasStarted = true;
    _animationController
      ..duration = composition.duration
      ..forward();
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    setState(() => _isOverlayOpaque = false);
  }

  Widget _buildAnimationError(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    _scheduleImmediateDismissal();
    return const SizedBox.expand();
  }

  void _scheduleImmediateDismissal() {
    if (_dismissalScheduled) return;
    _dismissalScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _isOverlayVisible = false);
    });
  }

  void _removeFadedOverlay() {
    if (_isOverlayOpaque || !mounted) return;
    setState(() => _isOverlayVisible = false);
  }
}

const SystemUiOverlayStyle _splashSystemUiStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.black,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
  systemNavigationBarColor: Colors.black,
  systemNavigationBarIconBrightness: Brightness.light,
);

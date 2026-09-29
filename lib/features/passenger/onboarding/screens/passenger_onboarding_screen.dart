import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/push_notification_service.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/constants.dart';
import '../../../../data/sources/local_storage.dart';
import '../../../../shared/widgets/fraya_button.dart';
import '../widgets/onboarding_page.dart';

class PassengerOnboardingScreen extends StatefulWidget {
  const PassengerOnboardingScreen({super.key});

  @override
  State<PassengerOnboardingScreen> createState() =>
      _PassengerOnboardingScreenState();
}

class _PassengerOnboardingScreenState extends State<PassengerOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'icon': Icons.directions_car_filled_outlined,
      'title': 'Déplacements simples et rapides',
      'description':
          'Réservez une course en quelques secondes et arrivez à destination confortablement',
      'color': const Color(0xFFBF953F),
    },
    {
      'icon': Icons.shield_outlined,
      'title': 'Sécurité garantie',
      'description':
          'Chauffeurs vérifiés, partage de trajet en temps réel avec vos proches',
      'color': const Color(0xFF22C55E),
    },
    {
      'icon': Icons.access_time,
      'title': 'Disponible 24h/24',
      'description':
          'Des chauffeurs disponibles à tout moment, où que vous soyez à Abidjan',
      'color': const Color(0xFF3B82F6),
    },
    {
      'icon': Icons.credit_card,
      'title': 'Paiement flexible',
      'description':
          'Cash, Orange Money, MTN Money, Wave - payez comme vous voulez',
      'color': const Color(0xFFA855F7),
    },
  ];

  Future<void> _completeOnboarding() async {
    await LocalStorage.instance.setBool(
      AppConstants.onboardingCompleteKey,
      true,
    );
    unawaited(PushNotificationService.instance.requestPermission());
    if (mounted) {
      context.goNamed(RouteNames.login);
    }
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFFCFBF8,
      ), // Couleur de fond légèrement crème comme sur la maquette
      body: SafeArea(
        child: Column(
          children: [
            // ── En-tête (Logo & Bouton Passer) ──
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    'assets/images/logo_fraya.png',
                    height: 40,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox(height: 40, width: 100),
                  ),
                  TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(
                      'Passer',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Contenu du PageView ──
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return OnboardingPage(
                    icon: slide['icon'] as IconData,
                    title: slide['title'] as String,
                    description: slide['description'] as String,
                    iconBackgroundColor: slide['color'] as Color,
                  );
                },
              ),
            ),

            // ── Pied de page (Indicateurs & Bouton) ──
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Indicateurs de page
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppColors
                                    .primaryDark // Utilisé primaryDark pour correspondre au design
                              : const Color(0xFFE5E7EB), // grey-200
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Bouton Suivant / Commencer
                  FrayaButton(
                    label: _currentPage == _slides.length - 1
                        ? 'Commencer'
                        : 'Suivant',
                    onPressed: _nextPage,
                    isFullWidth: true,
                    variant: FrayaButtonVariant.primary,
                    size: FrayaButtonSize.lg,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

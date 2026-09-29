import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/theme/app_colors.dart';
import 'package:fraya_mobile/domain/models/ride_status.dart';
import 'package:fraya_mobile/features/passenger/booking/widgets/active_ride/ride_status_banner.dart';

void main() {
  testWidgets('accepted banner uses dark text on gold background', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RideStatusBanner(status: RideStatus.accepted, distance: '250m'),
        ),
      ),
    );

    final title = tester.widget<Text>(find.text('Le chauffeur approche !'));
    final subtitle = tester.widget<Text>(find.text('A environ 250m de vous'));
    final icon = tester.widget<Icon>(find.byIcon(Icons.location_on_outlined));

    expect(title.style?.color, AppColors.textPrimary);
    expect(
      subtitle.style?.color,
      AppColors.textPrimary.withValues(alpha: 0.86),
    );
    expect(icon.color, AppColors.textPrimary);
  });

  testWidgets('arrived banner keeps white text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: RideStatusBanner(status: RideStatus.arrived)),
      ),
    );

    final title = tester.widget<Text>(
      find.text('Votre chauffeur est arrivé !'),
    );
    expect(title.style?.color, Colors.white);
  });

  testWidgets('arrived banner does not overflow on narrow screens', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RideStatusBanner(
            status: RideStatus.arrived,
            arrivedAt: DateTime.now().subtract(const Duration(seconds: 37)),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}

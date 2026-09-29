import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/config/app_config.dart';
import 'package:fraya_mobile/core/config/app_flavor.dart';
import 'package:fraya_mobile/core/services/passenger_contact_launcher_service.dart';
import 'package:fraya_mobile/domain/models/active_ride.dart';
import 'package:fraya_mobile/features/passenger/booking/providers/passenger_contact_provider.dart';
import 'package:fraya_mobile/features/passenger/booking/widgets/active_ride/driver_info_card.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void main() {
  setUpAll(() {
    AppConfig.instance.init(flavor: AppFlavor.dev);
  });

  testWidgets('resolves relative driver profile photo url', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DriverInfoCard(
            ride: ActiveRide.mock.copyWith(
              driverPhoto: '/uploads/drivers/awa.jpg',
            ),
          ),
        ),
      ),
    );

    final image = tester.widget<Image>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is NetworkImage &&
            (widget.image as NetworkImage).url ==
                'http://83.228.247.227/profiles/awa.jpg',
      ),
    );

    expect(image.image, isA<NetworkImage>());
  });

  testWidgets('uses driver placeholder when photo is missing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DriverInfoCard(
            ride: ActiveRide.mock.copyWith(
              driverPhoto: 'assets/images/driver_placeholder.png',
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
  });

  testWidgets('opens WhatsApp with active ride driver phone', (tester) async {
    final contactLauncher = _FakePassengerContactLauncherService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          passengerContactLauncherServiceProvider.overrideWithValue(
            contactLauncher,
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: DriverInfoCard(
              ride: ActiveRide.mock.copyWith(driverPhone: '+2250700112233'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is FaIcon && widget.icon == FontAwesomeIcons.whatsapp,
      ),
    );
    await tester.pumpAndSettle();

    expect(contactLauncher.lastWhatsAppNumber, '+2250700112233');
    expect(contactLauncher.whatsAppAttempts, 1);
  });
}

class _FakePassengerContactLauncherService
    extends PassengerContactLauncherService {
  int whatsAppAttempts = 0;
  String? lastWhatsAppNumber;

  @override
  Future<bool> launchWhatsApp(String? rawPhoneNumber) async {
    whatsAppAttempts++;
    lastWhatsAppNumber = rawPhoneNumber;
    return rawPhoneNumber != null && rawPhoneNumber.trim().isNotEmpty;
  }
}

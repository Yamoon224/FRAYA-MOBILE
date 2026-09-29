import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/utils/responsive.dart';

void main() {
  testWidgets('maps breakpoints to expected layout tiers', (tester) async {
    LayoutTier? currentTier;

    Future<void> pumpForWidth(double width) async {
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: Size(width, 800)),
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                currentTier = context.layoutTier;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      await tester.pump();
    }

    await pumpForWidth(320);
    expect(currentTier, LayoutTier.compact);

    await pumpForWidth(393);
    expect(currentTier, LayoutTier.phone);

    await pumpForWidth(600);
    expect(currentTier, LayoutTier.largePhone);

    await pumpForWidth(1024);
    expect(currentTier, LayoutTier.tablet);
  });
}

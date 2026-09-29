import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/features/driver/kyc/widgets/driver_document_source_sheet.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('shows camera image and pdf options', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: DriverDocumentSourceSheet()),
      ),
    );

    expect(find.text('Prendre une photo'), findsOneWidget);
    expect(find.text('Choisir une image'), findsOneWidget);
    expect(find.text('Choisir un PDF'), findsOneWidget);
  });
}

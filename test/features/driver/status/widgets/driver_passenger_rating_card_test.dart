import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/features/driver/status/widgets/driver_passenger_rating_card.dart';

void main() {
  testWidgets('shows reset hint when a rating exists', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DriverPassengerRatingCard(
            passengerName: 'Ali',
            rating: 4,
            comment: '',
            onRatingChanged: _noopRating,
            onCommentChanged: _noopComment,
            enabled: true,
          ),
        ),
      ),
    );

    expect(find.text('Bien'), findsOneWidget);
    expect(
      find.text('Touchez la meme etoile pour annuler la note'),
      findsOneWidget,
    );
  });

  testWidgets('hides reset hint when no rating is selected', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DriverPassengerRatingCard(
            passengerName: 'Ali',
            rating: 0,
            comment: '',
            onRatingChanged: _noopRating,
            onCommentChanged: _noopComment,
            enabled: true,
          ),
        ),
      ),
    );

    expect(find.text('Bien'), findsNothing);
    expect(
      find.text('Touchez la meme etoile pour annuler la note'),
      findsNothing,
    );
  });
}

void _noopRating(int _) {}

void _noopComment(String _) {}

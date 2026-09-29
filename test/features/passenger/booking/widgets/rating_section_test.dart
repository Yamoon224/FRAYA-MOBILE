import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/features/passenger/booking/widgets/ride_summary/rating_section.dart';

void main() {
  testWidgets(
    'stays stable on narrow screens and truncates long driver names',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RatingSection(
              driverName:
                  'Jean Baptiste Konan Kouadio Tres Long Nom Conducteur',
              driverRating: 4.8,
              currentRating: 0,
              currentComment: '',
              onRatingChanged: _noopRating,
              onCommentChanged: _noopComment,
            ),
          ),
        ),
      );

      expect(find.byType(IconButton), findsNWidgets(5));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('shows rating label and comment field when a rating exists', (
    tester,
  ) async {
    var comment = '';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RatingSection(
            driverName: 'Jean',
            driverRating: 4.8,
            currentRating: 4,
            currentComment: '',
            onRatingChanged: (_) {},
            onCommentChanged: (value) => comment = value,
          ),
        ),
      ),
    );

    expect(find.text('Bien'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'Trajet fluide');
    expect(comment, 'Trajet fluide');
  });

  testWidgets('tapping the same star does not clear the selected rating', (
    tester,
  ) async {
    var rating = 4;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: RatingSection(
              driverName: 'Jean',
              driverRating: 4.8,
              currentRating: rating,
              currentComment: '',
              onRatingChanged: (value) => setState(() => rating = value),
              onCommentChanged: _noopComment,
            ),
          ),
        ),
      ),
    );

    // Tapping the same star (index 3 = 4th star, value 4) keeps the rating
    // unchanged because allowClear is false.
    await tester.tap(find.byType(IconButton).at(3));
    await tester.pump();

    expect(rating, 4);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('Bien'), findsOneWidget);
  });

  testWidgets('hides comment field until a rating is selected', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RatingSection(
            driverName: 'Jean',
            driverRating: 4.8,
            currentRating: 0,
            currentComment: '',
            onRatingChanged: _noopRating,
            onCommentChanged: _noopComment,
          ),
        ),
      ),
    );

    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('Bien'), findsNothing);
  });
}

void _noopRating(int _) {}

void _noopComment(String _) {}

import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/data/sources/remote/support_ticket_payload_builder.dart';

void main() {
  group('SupportTicketPayloadBuilder', () {
    test('maps categories to backend type and priority', () {
      final draft = SupportTicketPayloadBuilder.fromReportProblem(
        category: 'Prix incorrect',
        description: 'Montant trop eleve',
      );

      expect(draft.type, 'PRICE');
      expect(draft.priority, 'MEDIUM');
      expect(
        draft.description,
        'Cat\u00e9gorie signal\u00e9e: Prix incorrect. Details: Montant trop eleve',
      );
    });

    test('enriches missing description with the selected UI category', () {
      final draft = SupportTicketPayloadBuilder.fromReportProblem(
        category: 'Autre',
        description: '  ',
      );

      expect(draft.type, 'OTHER');
      expect(draft.priority, 'MEDIUM');
      expect(draft.description, 'Cat\u00e9gorie signal\u00e9e: Autre');
    });

    test(
      'supports forcing the fallback backend type without changing priority',
      () {
        final draft = SupportTicketPayloadBuilder.fromReportProblem(
          category: 'Probl\u00e8me de s\u00e9curit\u00e9',
          description: null,
          overrideType: SupportTicketPayloadBuilder.fallbackType,
        );

        expect(draft.type, 'PRICE');
        expect(draft.priority, 'HIGH');
        expect(
          draft.description,
          'Cat\u00e9gorie signal\u00e9e: Probl\u00e8me de s\u00e9curit\u00e9',
        );
      },
    );
  });
}

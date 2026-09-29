import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/services/home_navigation_notifier.dart';

void main() {
  test('open destination search home intent is one-shot', () {
    final notifier = HomeNavigationNotifier.instance;
    notifier.consumeOpenDestinationSearchOnHomePending();

    notifier.requestOpenDestinationSearchOnHome();

    expect(notifier.consumeOpenDestinationSearchOnHomePending(), isTrue);
    expect(notifier.consumeOpenDestinationSearchOnHomePending(), isFalse);
  });

  test('reset search state home intent is one-shot', () {
    final notifier = HomeNavigationNotifier.instance;
    notifier.consumeResetSearchStateOnHomePending();

    notifier.requestResetSearchState();

    expect(notifier.consumeResetSearchStateOnHomePending(), isTrue);
    expect(notifier.consumeResetSearchStateOnHomePending(), isFalse);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/services/push_notification_service.dart';

void main() {
  group('PushNotificationService', () {
    test('parsePushPayload parses valid string tabIndex and scheduleId', () {
      final parsed = PushNotificationService.parsePushPayload({
        'tabIndex': '2',
        'scheduleId': '15',
      });
      expect(parsed.tabIndex, 2);
      expect(parsed.scheduleId, 15);
    });

    test(
      'parsePushPayload defaults tabIndex to 2 and ignores invalid scheduleId',
      () {
        final parsed = PushNotificationService.parsePushPayload({
          'tab_index': 'invalid',
          'schedule_id': '0',
        });
        expect(parsed.tabIndex, 2);
        expect(parsed.scheduleId, isNull);
      },
    );

    test('parsePushPayload handles empty map safely', () {
      final parsed = PushNotificationService.parsePushPayload(const {});
      expect(parsed.tabIndex, 2);
      expect(parsed.scheduleId, isNull);
    });
  });
}

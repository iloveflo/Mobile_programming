import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/models/notification_model.dart';
import 'package:my_first_app/models/payment_schedule_model.dart';
import 'package:my_first_app/services/local_notification_service.dart';
import 'package:my_first_app/services/push_notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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

  group('LocalNotificationService', () {
    test(
      'notifyOverdueOrUrgent không bắn thông báo OVERDUE_ALERT cũ khi không còn khoản vay hiệu lực',
      () async {
        final methodCalls = <MethodCall>[];
        const channel = MethodChannel('fincredit/local_notifications');
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              methodCalls.add(call);
              return true;
            });
        addTearDown(() {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(channel, null);
        });

        await LocalNotificationService.notifyOverdueOrUrgent(
          notifications: [
            NotificationModel(
              id: 99,
              userId: 1,
              title: 'Cảnh báo kỳ thanh toán quá hạn',
              message:
                  'Kỳ 4 khoản vay "Vay mua xe VinFast VF8" (9.940.625 đ) đã quá hạn.',
              type: 'OVERDUE_ALERT',
              channel: 'PUSH',
              status: 'SENT',
              createdAt: DateTime(2026, 11, 15),
              scheduleId: 404,
            ),
          ],
          schedules: [
            PaymentScheduleModel(
              id: 404,
              loanId: 101,
              installmentNumber: 4,
              dueDate: DateTime(2026, 11, 15),
              principalAmount: 8000000,
              interestAmount: 1940625,
              feeAmount: 0,
              totalAmount: 9940625,
              remainingBalance: 20000000,
              status: 'OVERDUE',
            ),
          ],
          loans: const [],
        );

        expect(
          methodCalls.where((c) => c.method == 'showNotification'),
          isEmpty,
        );
      },
    );
  });
}

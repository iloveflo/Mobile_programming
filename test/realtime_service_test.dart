import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/services/realtime_service.dart';

class _FakeSocketDriver implements RealtimeSocketDriver {
  String? lastOrigin;
  String? lastToken;
  int connectCount = 0;
  int disconnectCount = 0;
  void Function(String event, dynamic data)? onEventCallback;

  @override
  void connect({
    required String origin,
    required String token,
    required void Function(String event, dynamic data) onEvent,
  }) {
    connectCount++;
    lastOrigin = origin;
    lastToken = token;
    onEventCallback = onEvent;
  }

  @override
  void disconnect() {
    disconnectCount++;
  }
}

void main() {
  group('RealtimeService Tests', () {
    test('resolveSocketOrigin chuẩn hóa URL bỏ suffix /api/v1', () {
      expect(
        RealtimeService.resolveSocketOrigin('http://10.0.2.2:3000/api/v1'),
        'http://10.0.2.2:3000',
      );
      expect(
        RealtimeService.resolveSocketOrigin('https://api.fincredit.vn/api/'),
        'https://api.fincredit.vn',
      );
    });

    test(
      'Gộp burst credit_health_update trên payment_schedules (debounce)',
      () async {
        final driver = _FakeSocketDriver();
        int loanRefreshCount = 0;
        int scheduleRefreshCount = 0;
        int creditRefreshCount = 0;

        final service =
            RealtimeService(
                driver: driver,
                debounceDuration: const Duration(milliseconds: 30),
              )
              ..onRefreshLoans = () async {
                loanRefreshCount++;
              }
              ..onRefreshSchedules = () async {
                scheduleRefreshCount++;
              }
              ..onRefreshCreditProfile = () async {
                creditRefreshCount++;
              };

        service.connect(
          accessToken: 'jwt_token_1',
          baseUrl: 'http://10.0.2.2:3000/api/v1',
        );
        expect(service.isConnected, isTrue);
        expect(driver.lastOrigin, 'http://10.0.2.2:3000');

        // Mô phỏng tạo khoản vay 12 kỳ bắn 12 sự kiện liên tiếp
        for (int i = 0; i < 12; i++) {
          service.handleEvent('credit_health_update', {
            'table': 'payment_schedules',
            'action': 'INSERT',
          });
        }

        await Future.delayed(const Duration(milliseconds: 80));
        expect(scheduleRefreshCount, 1);
        expect(loanRefreshCount, 1);
        expect(creditRefreshCount, 1);

        service.disconnect();
      },
    );

    test(
      'Nhận notification kích hoạt làm mới thông báo và callback UI',
      () async {
        final driver = _FakeSocketDriver();
        int notifRefreshCount = 0;
        String? receivedTitle;
        String? receivedMessage;

        final service =
            RealtimeService(
                driver: driver,
                debounceDuration: const Duration(milliseconds: 20),
              )
              ..onRefreshNotifications = () async {
                notifRefreshCount++;
              }
              ..onNotificationReceived = (title, message) {
                receivedTitle = title;
                receivedMessage = message;
              };

        service.connect(accessToken: 'jwt_token_2');
        service.handleEvent('notification', {
          'title': 'Biến động dư nợ',
          'message': 'Đã thanh toán kỳ 1',
        });

        await Future.delayed(const Duration(milliseconds: 50));
        expect(receivedTitle, 'Biến động dư nợ');
        expect(receivedMessage, 'Đã thanh toán kỳ 1');
        expect(notifRefreshCount, 1);

        service.disconnect();
      },
    );

    test('Nhận session_revoked ngắt kết nối ngay lập tức và gọi callback', () {
      final driver = _FakeSocketDriver();
      bool revokedCalled = false;
      final service = RealtimeService(driver: driver)
        ..onSessionRevoked = () {
          revokedCalled = true;
        };

      service.connect(accessToken: 'jwt_token_3');
      expect(service.isConnected, isTrue);

      service.handleEvent('session_revoked', {'session_id': '99'});
      expect(service.isConnected, isFalse);
      expect(driver.disconnectCount, 1);
      expect(revokedCalled, isTrue);
    });
  });
}

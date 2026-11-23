import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/controllers/payment_schedule_controller.dart';
import 'package:my_first_app/core/network/api_client.dart';
import 'package:my_first_app/models/payment_schedule_model.dart';
import 'package:my_first_app/repositories/mock/mock_payment_schedule_repository.dart';

class _CountingScheduleRepository extends MockPaymentScheduleRepository {
  int markAsPaidCalls = 0;
  final Completer<void> _gate = Completer<void>();

  void releasePayment() {
    if (!_gate.isCompleted) {
      _gate.complete();
    }
  }

  @override
  Future<PaymentScheduleModel> markScheduleAsPaid(
    int scheduleId, {
    int? userId,
  }) async {
    markAsPaidCalls++;
    await _gate.future;
    return super.markScheduleAsPaid(scheduleId, userId: userId);
  }
}

void main() {
  group('Idempotency & Double-Submit Guards', () {
    test(
      'ApiClient attaches Idempotency-Key and reuses same key across 401 refresh retry',
      () async {
        final capturedKeys = <String>[];
        var attempt = 0;

        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(() => server.close(force: true));

        server.listen((req) async {
          final key = req.headers.value('idempotency-key') ?? '';
          capturedKeys.add(key);
          attempt++;

          if (attempt == 1) {
            req.response.statusCode = 401;
            req.response.write(jsonEncode({'message': 'Expired'}));
          } else {
            req.response.statusCode = 201;
            req.response.write(
              jsonEncode({
                'success': true,
                'data': {'id': 1},
              }),
            );
          }
          await req.response.close();
        });

        final client = ApiClient(baseUrl: 'http://127.0.0.1:${server.port}')
          ..onRefreshToken = () async => true;
        client.setAuthToken('old-token');

        final res = await client.post(
          '/api/loans',
          body: {'loan_name': 'Test'},
        );
        expect(res['success'], isTrue);
        expect(capturedKeys.length, 2);
        expect(capturedKeys[0], startsWith('fc-'));
        expect(capturedKeys[0].length, greaterThanOrEqualTo(8));
        expect(capturedKeys[1], equals(capturedKeys[0]));
      },
    );

    test(
      'PaymentScheduleController.markAsPaid blocks concurrent duplicate taps',
      () async {
        final repo = _CountingScheduleRepository();
        final controller = PaymentScheduleController(repo);
        await controller.loadSchedules();
        final targetId = controller.schedules
            .firstWhere((s) => s.status != 'PAID')
            .id;

        final f1 = controller.markAsPaid(targetId);
        final f2 = controller.markAsPaid(targetId);

        expect(controller.isPaying, isTrue);
        repo.releasePayment();

        final results = await Future.wait([f1, f2]);
        expect(results[0], isTrue);
        expect(results[1], isFalse);
        expect(repo.markAsPaidCalls, 1);
        expect(controller.isPaying, isFalse);
      },
    );
  });
}

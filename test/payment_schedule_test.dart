import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/controllers/auth_controller.dart';
import 'package:my_first_app/controllers/loan_controller.dart';
import 'package:my_first_app/controllers/payment_schedule_controller.dart';
import 'package:my_first_app/mock_data/notification_mock_data.dart';
import 'package:my_first_app/mock_data/notification_preference_mock_data.dart';
import 'package:my_first_app/mock_data/payment_schedule_mock_data.dart';
import 'package:my_first_app/models/notification_model.dart';
import 'package:my_first_app/models/notification_preference_model.dart';
import 'package:my_first_app/models/payment_schedule_model.dart';
import 'package:my_first_app/repositories/interfaces/auth_repository.dart';
import 'package:my_first_app/repositories/interfaces/loan_repository.dart';
import 'package:my_first_app/repositories/interfaces/payment_schedule_repository.dart';
import 'package:my_first_app/repositories/mock/mock_auth_repository.dart';
import 'package:my_first_app/repositories/mock/mock_loan_repository.dart';
import 'package:my_first_app/repositories/mock/mock_payment_schedule_repository.dart';
import 'package:my_first_app/screens/schedule/payment_schedule_screen.dart';
import 'package:my_first_app/service_locator.dart';
import 'package:my_first_app/widgets/schedule/notification_list_sheet.dart';
import 'package:my_first_app/widgets/schedule/notification_preference_sheet.dart';
import 'package:my_first_app/widgets/schedule/payment_schedule_card.dart';
import 'package:my_first_app/widgets/schedule/schedule_detail_sheet.dart';
import 'package:my_first_app/widgets/schedule/schedule_empty_state.dart';
import 'package:my_first_app/widgets/schedule/schedule_summary_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockPaymentScheduleRepository mockRepo;
  late PaymentScheduleController controller;

  setUp(() async {
    await resetServiceLocator(dispose: false);

    // Chuẩn hóa dữ liệu mock test với loanId: 101 thuộc user 1
    PaymentScheduleMockData.paymentSchedulesDatabase.clear();
    PaymentScheduleMockData.paymentSchedulesDatabase.addAll([
      PaymentScheduleModel(
        id: 1,
        loanId: 101,
        installmentNumber: 1,
        dueDate: DateTime(2026, 9, 15),
        principalAmount: 2000000.0,
        interestAmount: 250000.0,
        feeAmount: 0.0,
        totalAmount: 2250000.0,
        remainingBalance: 0.0,
        status: 'PAID',
      ),
      PaymentScheduleModel(
        id: 2,
        loanId: 101,
        installmentNumber: 2,
        dueDate: DateTime(2026, 10, 15),
        principalAmount: 2000000.0,
        interestAmount: 235000.0,
        feeAmount: 50000.0,
        totalAmount: 2285000.0,
        remainingBalance: 2285000.0,
        status: 'OVERDUE',
      ),
      PaymentScheduleModel(
        id: 3,
        loanId: 101,
        installmentNumber: 3,
        dueDate: DateTime(2026, 11, 15),
        principalAmount: 2000000.0,
        interestAmount: 220000.0,
        feeAmount: 0.0,
        totalAmount: 2220000.0,
        remainingBalance: 2220000.0,
        status: 'PENDING',
      ),
    ]);

    NotificationPreferenceMockData.notificationPreferencesDatabase.clear();
    NotificationPreferenceMockData.notificationPreferencesDatabase.addAll([
      const NotificationPreferenceModel(
        id: 1,
        userId: 1,
        pushEnabled: true,
        emailEnabled: true,
        reminderDays: 3,
      ),
    ]);

    NotificationMockData.notificationsDatabase.clear();
    NotificationMockData.notificationsDatabase.addAll([
      NotificationModel(
        id: 1,
        userId: 1,
        scheduleId: 2,
        type: 'OVERDUE_ALERT',
        channel: 'PUSH',
        title: 'Nhắc quá hạn thanh toán kỳ 2',
        message: 'Kỳ thanh toán 2.285.000 đ đã quá hạn.',
        status: 'SENT',
        scheduledAt: DateTime(2026, 10, 15, 8, 0),
        sentAt: DateTime(2026, 10, 15, 8, 0),
      ),
      NotificationModel(
        id: 2,
        userId: 1,
        scheduleId: 2,
        type: 'PAYMENT_REMINDER',
        channel: 'EMAIL',
        title: 'Gửi Email nhắc quá hạn kỳ 2',
        message: 'Thông tin nhắc nợ gửi đến email.',
        status: 'FAILED',
        scheduledAt: DateTime(2026, 10, 15, 8, 0),
      ),
    ]);

    mockRepo = MockPaymentScheduleRepository();
    controller = PaymentScheduleController(mockRepo);
  });

  group('Luồng nghiệp vụ Nhắc nợ & Lịch (PaymentScheduleController)', () {
    test(
      '1. Luồng 5: Truy xuất lịch trả nợ sắp xếp theo due_date tăng dần',
      () async {
        await controller.loadSchedules(userId: 1);

        expect(controller.schedules.length, 3);
        expect(controller.schedules[0].id, 1);
        expect(controller.schedules[1].id, 2);
        expect(controller.schedules[2].id, 3);
        expect(
          controller.schedules[0].dueDate.isBefore(
            controller.schedules[1].dueDate,
          ),
          isTrue,
        );
        expect(
          controller.schedules[1].dueDate.isBefore(
            controller.schedules[2].dueDate,
          ),
          isTrue,
        );

        // Bóc tách số tiền
        final schedule2 = controller.schedules[1];
        expect(schedule2.principalAmount, 2000000.0);
        expect(schedule2.interestAmount, 235000.0);
        expect(schedule2.feeAmount, 50000.0);
        expect(schedule2.totalAmount, 2285000.0);
        expect(schedule2.status, 'OVERDUE');
      },
    );

    test('2. Luồng 5.2: Lọc danh sách kỳ thanh toán theo trạng thái', () async {
      await controller.loadSchedules(userId: 1);

      controller.setFilter('ALL');
      expect(controller.filteredSchedules.length, 3);

      controller.setFilter('OVERDUE');
      expect(controller.filteredSchedules.length, 1);
      expect(controller.filteredSchedules.first.status, 'OVERDUE');

      controller.setFilter('PAID');
      expect(controller.filteredSchedules.length, 1);
      expect(controller.filteredSchedules.first.status, 'PAID');
    });

    test(
      '3. Luồng 7: Thanh toán kỳ quá hạn (markAsPaid) và cập nhật số lượng',
      () async {
        await controller.loadSchedules(userId: 1);
        expect(controller.overdueCount, 1);

        final success = await controller.markAsPaid(2, userId: 1);
        expect(success, isTrue);

        final updated = controller.schedules.firstWhere((s) => s.id == 2);
        expect(updated.status, 'PAID');
        expect(updated.remainingBalance, 0.0);
        expect(controller.overdueCount, 0);
        expect(controller.paidCount, 2);
      },
    );

    test(
      '4. Luồng 8: Cập nhật cấu hình thông báo (NotificationPreference)',
      () async {
        await controller.loadNotificationPreference(userId: 1);
        expect(controller.preference?.pushEnabled, isTrue);

        final newPref = controller.preference!.copyWith(reminderDays: 5);

        final success = await controller.updatePreference(
          newPref,
          userEmail: 'dev@gmail.com',
          userPhone: '0901234567',
        );
        expect(success, isTrue);
        expect(controller.preference?.reminderDays, 5);
      },
    );

    test(
      '5. Luồng 8 & Ngoại lệ EX-04: Thiếu thông tin liên hệ khi bật kênh',
      () async {
        const invalidPref = NotificationPreferenceModel(
          id: 99,
          userId: 99,
          pushEnabled: false,
          emailEnabled: true,
          reminderDays: 3,
        );

        final success = await controller.updatePreference(
          invalidPref,
          userEmail: null,
          userPhone: null,
        );
        expect(success, isFalse);
        expect(controller.exceptionCode, 'EX-04');
        expect(controller.errorMessage, contains('Thiếu thông tin'));
      },
    );

    test(
      '6. Luồng 9: Tải danh sách thông báo và nhận diện trạng thái FAILED (EX-05)',
      () async {
        await controller.loadNotifications(userId: 1);
        expect(controller.notifications.length, 2);

        final failedNotifs = controller.notifications
            .where((n) => n.status == 'FAILED')
            .toList();
        expect(failedNotifs.length, 1);
        expect(failedNotifs.first.channel, 'EMAIL');

        final sentNotifs = controller.notifications
            .where((n) => n.status == 'SENT')
            .toList();
        expect(sentNotifs.length, 1);
        expect(sentNotifs.first.channel, 'PUSH');
      },
    );

    test(
      '7. Luồng 10: Đồng bộ và làm mới lịch nhắc nợ khi kỳ phân kỳ thay đổi',
      () async {
        final syncedCount = await controller.syncSchedules(userId: 1);
        expect(syncedCount, greaterThanOrEqualTo(0));
        expect(controller.schedules.isNotEmpty, isTrue);
      },
    );

    test('8. Ngoại lệ EX-01: Chưa có lịch phân kỳ (Empty State)', () async {
      PaymentScheduleMockData.paymentSchedulesDatabase.clear();
      await controller.loadSchedules(userId: 1);

      expect(controller.schedules.isEmpty, isTrue);
      expect(controller.isEmptyState, isTrue);
      expect(controller.exceptionCode, 'EX-01');
    });

    test(
      '9. Ngoại lệ EX-02: Truy xuất lịch của người dùng khác (403 Forbidden)',
      () async {
        mockRepo.shouldSimulateUnauthorized = true;
        await controller.loadSchedules(userId: 999);

        expect(controller.exceptionCode, 'EX-02');
        expect(controller.errorMessage, contains('quyền'));
      },
    );

    test(
      '10. Ngoại lệ EX-06: Sự cố kết nối hoặc lỗi cơ sở dữ liệu Backend',
      () async {
        mockRepo.shouldSimulateDatabaseError = true;
        await controller.loadSchedules(userId: 1);

        expect(controller.exceptionCode, 'EX-06');
        expect(controller.errorMessage, contains('cơ sở dữ liệu'));
      },
    );
  });

  group('Kiểm thử giao diện Widget Nhắc nợ & Lịch', () {
    testWidgets('PaymentScheduleCard hiển thị đúng thông tin và tương tác', (
      WidgetTester tester,
    ) async {
      final schedule = PaymentScheduleModel(
        id: 2,
        loanId: 101,
        installmentNumber: 2,
        dueDate: DateTime(2026, 10, 15),
        principalAmount: 2000000.0,
        interestAmount: 235000.0,
        feeAmount: 50000.0,
        totalAmount: 2285000.0,
        remainingBalance: 2285000.0,
        status: 'OVERDUE',
      );

      bool tapped = false;
      bool paid = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaymentScheduleCard(
              schedule: schedule,
              loanName: 'Vay tiêu dùng FE',
              onTap: () => tapped = true,
              onPay: () => paid = true,
            ),
          ),
        ),
      );

      expect(find.text('Kỳ 2'), findsOneWidget);
      expect(find.text('Vay tiêu dùng FE'), findsOneWidget);
      expect(find.text('Quá hạn'), findsOneWidget);
      expect(find.text('2.285.000 đ'), findsOneWidget);
      expect(find.text('Ghi nhận thanh toán'), findsOneWidget);

      await tester.tap(find.text('Ghi nhận thanh toán'));
      await tester.pump();
      expect(paid, isTrue);

      await tester.tap(find.text('Vay tiêu dùng FE'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets(
      'ScheduleSummaryCard hiển thị tổng nghĩa vụ tài chính và các nút tắt',
      (WidgetTester tester) async {
        bool openPref = false;
        bool openNotif = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ScheduleSummaryCard(
                currentMonthDueAmount: 4505000.0,
                upcomingCount: 1,
                overdueCount: 1,
                paidCount: 1,
                onOpenPreferences: () => openPref = true,
                onOpenNotifications: () => openNotif = true,
              ),
            ),
          ),
        );

        expect(find.text('4.505.000 đ'), findsOneWidget);
        expect(find.text('Nghĩa vụ thanh toán tháng này'), findsOneWidget);
        expect(find.byTooltip('Cài đặt nhắc nợ'), findsOneWidget);
        expect(find.byTooltip('Hộp thư nhắc nợ'), findsOneWidget);

        await tester.tap(find.byTooltip('Cài đặt nhắc nợ'));
        await tester.pump();
        expect(openPref, isTrue);

        await tester.tap(find.byTooltip('Hộp thư nhắc nợ'));
        await tester.pump();
        expect(openNotif, isTrue);
      },
    );

    testWidgets(
      'ScheduleDetailSheet hiển thị bóc tách gốc, lãi, phí và không lộ tên bảng kỹ thuật',
      (WidgetTester tester) async {
        final schedule = PaymentScheduleModel(
          id: 2,
          loanId: 101,
          installmentNumber: 2,
          dueDate: DateTime(2026, 10, 15),
          principalAmount: 2000000.0,
          interestAmount: 235000.0,
          feeAmount: 50000.0,
          totalAmount: 2285000.0,
          remainingBalance: 2285000.0,
          status: 'OVERDUE',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ScheduleDetailSheet(
                schedule: schedule,
                loanName: 'Vay tiêu dùng FE',
                onPay: () {},
              ),
            ),
          ),
        );

        expect(find.text('Chi tiết Kỳ 2'), findsOneWidget);
        expect(find.text('Tiền nợ gốc trong kỳ'), findsOneWidget);
        expect(find.text('2.000.000 đ'), findsOneWidget);
        expect(find.text('Tiền lãi phát sinh'), findsOneWidget);
        expect(find.text('235.000 đ'), findsOneWidget);
        expect(find.text('Phí dịch vụ phát sinh'), findsOneWidget);
        expect(find.text('50.000 đ'), findsOneWidget);
        expect(find.text('Tổng nghĩa vụ phải trả'), findsOneWidget);
        expect(find.text('2.285.000 đ'), findsNWidgets(2));

        // Đảm bảo không lộ tên bảng hay trường dữ liệu DB nội bộ
        expect(find.textContaining('due_date'), findsNothing);
        expect(find.textContaining('PaymentSchedule'), findsNothing);
        expect(find.textContaining('EX-'), findsNothing);
      },
    );

    testWidgets('NotificationPreferenceSheet cho phép lưu cấu hình nhắc nợ', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const pref = NotificationPreferenceModel(
        id: 1,
        userId: 1,
        pushEnabled: true,
        emailEnabled: false,
        reminderDays: 3,
      );

      NotificationPreferenceModel? savedPref;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationPreferenceSheet(
              currentPreference: pref,
              userEmail: 'dev@gmail.com',
              userPhone: '0901234567',
              onSave: (newPref) async {
                savedPref = newPref;
                return true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Cài đặt nhắc nợ định kỳ'), findsOneWidget);
      expect(find.text('Thông báo ứng dụng (Push)'), findsOneWidget);
      expect(find.text('Hộp thư điện tử (Email)'), findsOneWidget);

      // Bấm Lưu thiết lập nhắc nợ
      await tester.tap(find.text('Lưu thiết lập nhắc nợ'));
      await tester.pump();

      expect(savedPref, isNotNull);
      expect(savedPref?.reminderDays, 3);
      expect(savedPref?.pushEnabled, isTrue);
    });

    testWidgets(
      'NotificationListSheet hiển thị danh sách thông báo và điều hướng kỳ',
      (WidgetTester tester) async {
        final notifs = [
          NotificationModel(
            id: 1,
            userId: 1,
            scheduleId: 2,
            type: 'OVERDUE_ALERT',
            channel: 'PUSH',
            title: 'Nhắc quá hạn kỳ 2',
            message: 'Số tiền 2.285.000 đ',
            status: 'SENT',
            scheduledAt: DateTime(2026, 10, 15),
          ),
        ];

        int? selectedScheduleId;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NotificationListSheet(
                notifications: notifs,
                onSelectSchedule: (id) => selectedScheduleId = id,
              ),
            ),
          ),
        );

        expect(find.text('Thông báo nhắc nợ'), findsOneWidget);
        expect(find.text('Nhắc quá hạn kỳ 2'), findsOneWidget);
        expect(find.text('Xem kỳ hạn'), findsOneWidget);

        await tester.tap(find.text('Xem kỳ hạn'));
        await tester.pump();

        expect(selectedScheduleId, 2);
      },
    );

    testWidgets(
      'NotificationListSheet không bị overflow với tiêu đề dài trên màn hình nhỏ',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        FlutterErrorDetails? caughtDetails;
        final oldHandler = FlutterError.onError;
        FlutterError.onError = (details) {
          caughtDetails = details;
        };
        addTearDown(() => FlutterError.onError = oldHandler);

        final longTitleNotifs = [
          NotificationModel(
            id: 1,
            userId: 1,
            scheduleId: 4,
            type: 'PAYMENT_REMINDER',
            channel: 'EMAIL',
            title: 'Thông báo nghĩa vụ thanh toán kỳ 4 với tiêu đề rất dài',
            message:
                'Kỳ 4 hợp đồng Vay mua xe VinFast VF8 số tiền 2.630.208 đ sẽ đến hạn vào 10/11/2026.',
            status: 'PENDING',
            scheduledAt: DateTime(2026, 11, 7, 8, 0),
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NotificationListSheet(
                notifications: longTitleNotifs,
                onSelectSchedule: (_) {},
              ),
            ),
          ),
        );

        FlutterError.onError = oldHandler;
        expect(caughtDetails, isNull);
        expect(
          find.text('Thông báo nghĩa vụ thanh toán kỳ 4 với tiêu đề rất dài'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'ScheduleEmptyState hiển thị đúng nút hành động khi chưa có lịch',
      (WidgetTester tester) async {
        bool addLoanClicked = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ScheduleEmptyState(onAddLoan: () => addLoanClicked = true),
            ),
          ),
        );

        expect(find.text('Chưa có lịch phân kỳ trả nợ'), findsOneWidget);
        expect(find.text('Thêm khoản vay mới'), findsOneWidget);

        await tester.tap(find.text('Thêm khoản vay mới'));
        await tester.pump();
        expect(addLoanClicked, isTrue);
      },
    );

    testWidgets(
      'PaymentScheduleScreen render toàn màn hình với ServiceLocator và dữ liệu',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        // Setup auth controller và service locator
        final authRepo = MockAuthRepository();
        final authController = AuthController(authRepo);
        await authController.login('0900000001', '123456');

        sl.registerLazySingleton<AuthRepository>(() => authRepo);
        sl.registerLazySingleton<AuthController>(() => authController);
        sl.registerLazySingleton<LoanRepository>(() => MockLoanRepository());
        sl.registerLazySingleton<LoanController>(
          () => LoanController(sl<LoanRepository>()),
        );
        sl.registerLazySingleton<PaymentScheduleRepository>(() => mockRepo);
        sl.registerLazySingleton<PaymentScheduleController>(() => controller);

        await tester.pumpWidget(
          const MaterialApp(home: PaymentScheduleScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.text('Lịch thanh toán định kỳ'), findsOneWidget);
        expect(find.text('KẾ HOẠCH TRẢ NỢ CHI TIẾT'), findsOneWidget);
        expect(find.byTooltip('Cài đặt nhắc nợ'), findsOneWidget);
        expect(find.byTooltip('Hộp thư nhắc nợ'), findsOneWidget);

        // Thấy các thẻ kỳ
        expect(find.textContaining('Kỳ 1'), findsOneWidget);
        expect(find.textContaining('Kỳ 2'), findsOneWidget);
        expect(find.textContaining('Kỳ 3'), findsOneWidget);
      },
    );
  });
}

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/screens/main_shell_screen.dart';
import 'package:my_first_app/screens/settings/app_settings_screen.dart';
import 'package:my_first_app/service_locator.dart';
import 'package:my_first_app/widgets/widget.dart';

void main() {
  setUpAll(setupServiceLocator);

  group('CustomBottomNavBar Widget Tests', () {
    testWidgets('Hiển thị đầy đủ 6 tabs với nhãn tương ứng', (
      WidgetTester tester,
    ) async {
      int selectedIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: CustomBottomNavBar(
              currentIndex: selectedIndex,
              onTap: (index) => selectedIndex = index,
            ),
          ),
        ),
      );

      expect(find.text('Trang chủ'), findsOneWidget);
      expect(find.text('Khoản vay'), findsOneWidget);
      expect(find.text('Lịch trả nợ'), findsOneWidget);
      expect(find.text('Tín dụng'), findsOneWidget);
      expect(find.text('Cá nhân'), findsOneWidget);
      expect(find.text('Cài đặt'), findsOneWidget);
    });

    testWidgets('Tương tác chuyển tab khi chạm vào tab mục tiêu', (
      WidgetTester tester,
    ) async {
      int tappedIndex = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: CustomBottomNavBar(
              currentIndex: 0,
              onTap: (index) {
                tappedIndex = index;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Cài đặt'));
      await tester.pumpAndSettle();

      expect(tappedIndex, equals(5));
    });

    testWidgets('Hiệu ứng ẩn / hiện phản hồi theo thuộc tính isVisible', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: CustomBottomNavBar(
              currentIndex: 0,
              isVisible: false,
              onTap: (_) {},
            ),
          ),
        ),
      );

      final animatedSlideFinder = find.byType(AnimatedSlide);
      expect(animatedSlideFinder, findsOneWidget);

      final AnimatedSlide slideWidget = tester.widget(animatedSlideFinder);
      expect(slideWidget.offset, equals(const Offset(0.0, 1.0)));
    });
  });

  group('MainShellScreen Root Shell Navigation Tests', () {
    testWidgets(
      'Khởi tạo hiển thị tab Trang chủ mặc định và chuyển tab mượt mà',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: MainShellScreen()));
        await tester.pumpAndSettle();

        // Kiểm tra có IndexedStack lưu giữ các tab
        expect(find.byType(IndexedStack), findsOneWidget);

        // Chuyển sang Tab Khoản vay (Index 1)
        await tester.tap(find.text('Khoản vay'));
        await tester.pumpAndSettle();

        final indexedStackFinder = find.byType(IndexedStack);
        final IndexedStack stack = tester.widget(indexedStackFinder);
        expect(stack.index, equals(1));
      },
    );

    testWidgets(
      'Tự động ẩn thanh BottomNav khi cuộn xuống và hiện lại khi cuộn lên',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: MainShellScreen()));
        await tester.pumpAndSettle();

        // Giả lập cuộn nội dung xuống (Scroll down -> direction reverse)
        final BuildContext context = tester.element(find.byType(IndexedStack));
        final reverseNotification = UserScrollNotification(
          metrics: FixedScrollMetrics(
            minScrollExtent: 0,
            maxScrollExtent: 1000,
            pixels: 100,
            viewportDimension: 600,
            axisDirection: AxisDirection.down,
            devicePixelRatio: 1.0,
          ),
          context: context,
          direction: ScrollDirection.reverse,
        );

        reverseNotification.dispatch(context);
        await tester.pumpAndSettle();

        // Thanh BottomNav phải trượt xuống ẩn đi
        AnimatedSlide slideWidget = tester.widget(find.byType(AnimatedSlide));
        expect(slideWidget.offset, equals(const Offset(0.0, 1.0)));

        // Giả lập cuộn nội dung lên lại (Scroll up -> direction forward)
        final forwardNotification = UserScrollNotification(
          metrics: FixedScrollMetrics(
            minScrollExtent: 0,
            maxScrollExtent: 1000,
            pixels: 50,
            viewportDimension: 600,
            axisDirection: AxisDirection.down,
            devicePixelRatio: 1.0,
          ),
          context: context,
          direction: ScrollDirection.forward,
        );

        forwardNotification.dispatch(context);
        await tester.pumpAndSettle();

        // Thanh BottomNav trượt lên hiện lại
        slideWidget = tester.widget(find.byType(AnimatedSlide));
        expect(slideWidget.offset, equals(Offset.zero));
      },
    );

    testWidgets(
      'AppSnackBar tự động đánh thức Bottom Navigation Bar hiện lại và hiển thị thông báo nổi',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: MainShellScreen(initialIndex: 5)),
        );
        await tester.pumpAndSettle();

        final BuildContext context = tester.element(
          find.byType(AppSettingsScreen),
        );

        // 1. Giả lập cuộn xuống ẩn thanh nav bar
        final reverseNotification = UserScrollNotification(
          metrics: FixedScrollMetrics(
            minScrollExtent: 0,
            maxScrollExtent: 1000,
            pixels: 100,
            viewportDimension: 600,
            axisDirection: AxisDirection.down,
            devicePixelRatio: 1.0,
          ),
          context: context,
          direction: ScrollDirection.reverse,
        );
        reverseNotification.dispatch(context);
        await tester.pumpAndSettle();

        AnimatedSlide slideWidget = tester.widget(find.byType(AnimatedSlide));
        expect(slideWidget.offset, equals(const Offset(0.0, 1.0)));

        // 2. Kích hoạt AppSnackBar
        AppSnackBar.showSuccess(context, 'Dọn dẹp cache thành công');
        await tester.pumpAndSettle();

        // 3. Thanh Nav Bar phải tự động trượt hiện trở lại làm điểm tựa
        slideWidget = tester.widget(find.byType(AnimatedSlide));
        expect(slideWidget.offset, equals(Offset.zero));

        // 4. SnackBar phải xuất hiện với nội dung và kiểu floating
        expect(find.text('Dọn dẹp cache thành công'), findsOneWidget);
        final SnackBar snackBar = tester.widget(find.byType(SnackBar));
        expect(snackBar.behavior, equals(SnackBarBehavior.floating));
        expect(snackBar.backgroundColor, equals(const Color(0xFF16A34A)));
      },
    );
  });
}

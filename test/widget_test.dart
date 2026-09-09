import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/main.dart';
import 'package:my_first_app/service_locator.dart';

void main() {
  setUpAll(setupServiceLocator);

  testWidgets('Ứng dụng khởi động tại màn hình đăng nhập', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.byType(ElevatedButton), findsOneWidget);
    expect(find.byType(TextButton), findsOneWidget);
  });
}

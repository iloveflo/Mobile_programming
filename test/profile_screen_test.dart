import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/controllers/auth_controller.dart';
import 'package:my_first_app/mock_data/user_mock_data.dart';
import 'package:my_first_app/models/user_model.dart';
import 'package:my_first_app/screens/profile/profile_screen.dart';
import 'package:my_first_app/service_locator.dart';

void main() {
  setUpAll(() async {
    setupServiceLocator();
  });

  setUp(() {
    // Reset về user mặc định trước mỗi bài test
    final authController = sl<AuthController>();
    authController.setCurrentUser(UserMockData.usersDatabase.first);
  });

  group('ProfileScreen Widget Tests', () {
    testWidgets(
      'Hiển thị đầy đủ các phân hệ hồ sơ tài chính cá nhân cho user có sẵn dữ liệu',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
        await tester.pumpAndSettle();

        // Kiểm tra tiêu đề và thông tin định danh eKYC
        expect(find.text('Hồ sơ cá nhân'), findsOneWidget);
        expect(find.text('Nguyen Van Dev'), findsWidgets);
        expect(find.text('Đã xác thực eKYC C06'), findsOneWidget);
        expect(find.text('Gold Member'), findsOneWidget);

        // Kiểm tra 3 chỉ số tài chính quan trọng
        expect(find.text('Điểm tín dụng'), findsOneWidget);
        expect(find.text('Gánh nặng nợ (DTI)'), findsOneWidget);
        expect(find.text('Thu nhập/tháng'), findsOneWidget);

        // Kiểm tra các phân hệ dossier
        expect(find.text('Thông tin định danh pháp lý'), findsOneWidget);
        expect(
          find.text('Hồ sơ năng lực tài chính & Thu nhập'),
          findsOneWidget,
        );
        expect(
          find.text('Tài khoản thụ hưởng & Nhận giải ngân'),
          findsOneWidget,
        );
        expect(find.text('Hồ sơ tín nhiệm tín dụng CIC'), findsOneWidget);
        expect(find.text('Hành động & Bảo mật hồ sơ'), findsOneWidget);

        // Đảm bảo TUYỆT ĐỐI KHÔNG có nút Đăng xuất trên màn hình Cá nhân
        expect(find.text('Đăng xuất tài khoản'), findsNothing);
        expect(find.text('Đăng xuất'), findsNothing);
      },
    );

    testWidgets(
      'Tài khoản người dùng mới: hiển thị đúng dữ liệu động, không hardcode mock data',
      (WidgetTester tester) async {
        final authController = sl<AuthController>();
        // Giả lập người dùng mới đăng ký tài khoản
        authController.setCurrentUser(
          const UserModel(
            userId: 9999,
            fullName: 'Trần Thị Mới',
            email: 'newuser@fincredit.vn',
            phone: '0933112233',
            passwordHash: 'secured_pass',
            monthlyIncome: null,
            dateOfBirth: null,
            idCardNumber: null,
            address: null,
            occupation: null,
            workplace: null,
            contractType: null,
            isEkycVerified: false,
            ekycTier: null,
            membershipTier: 'STANDARD',
            cicScore: null,
            bankAccounts: [],
          ),
        );

        await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
        await tester.pumpAndSettle();

        // Phản ánh đúng tên người dùng mới và trạng thái eKYC chưa xác thực
        expect(find.text('Trần Thị Mới'), findsWidgets);
        expect(find.text('Chưa xác thực eKYC'), findsOneWidget);
        expect(find.text('Thành viên mới'), findsOneWidget);

        // Thước đo tài chính động
        expect(find.text('Chưa có'), findsOneWidget); // Điểm tín dụng chưa có
        expect(
          find.text('Chưa cập nhật'),
          findsWidgets,
        ); // Thu nhập chưa cập nhật

        // Thẻ định danh pháp lý & hồ sơ chưa điền
        expect(find.text('Chưa cập nhật CCCD'), findsOneWidget);
        expect(find.text('Chưa cập nhật địa chỉ'), findsOneWidget);
        expect(
          find.text('Chưa liên kết tài khoản nhận giải ngân'),
          findsOneWidget,
        );
        expect(find.text('Chưa có báo cáo'), findsOneWidget);

        // Không còn sót bất kỳ dữ liệu hardcode giả lập nào
        expect(find.text('0792 0100 ****'), findsNothing);
        expect(find.text('Kỹ sư Phần mềm Senior'), findsNothing);
        expect(find.text('Tập đoàn Công nghệ FPT'), findsNothing);
        expect(find.text('HOANG CAO VU THAO'), findsNothing);
      },
    );

    testWidgets('Mở thành công modal Đổi Mật Khẩu bảo mật', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
      await tester.pumpAndSettle();

      final changePasswordFinder = find.text('Đổi mật khẩu tài khoản');
      await tester.scrollUntilVisible(
        changePasswordFinder,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(changePasswordFinder, findsOneWidget);
      await tester.tap(changePasswordFinder);
      await tester.pumpAndSettle();

      // Modal hiện lên với các trường mật khẩu
      expect(find.text('Mật khẩu hiện tại'), findsOneWidget);
      expect(find.text('Mật khẩu mới'), findsOneWidget);
      expect(find.text('Xác nhận mật khẩu mới'), findsOneWidget);
      expect(find.text('Xác nhận đổi mật khẩu'), findsOneWidget);
    });
  });
}

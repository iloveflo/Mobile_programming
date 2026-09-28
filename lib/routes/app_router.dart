import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../models/loan_model.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/otp_verification_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/settings/app_settings_screen.dart';
import '../screens/loans/loan_collateral_ocr_screen.dart';
import '../screens/loans/loan_detail_screen.dart';
import '../screens/loans/loan_form_screen.dart';
import '../screens/loans/loan_list_screen.dart';
import '../screens/main_shell_screen.dart';

/// Hệ thống điều hướng tập trung theo Named Routes cho FinCredit
abstract final class AppRouter {
  AppRouter._();

  /// M01: Màn hình khởi động Splash
  static const String splash = '/';

  /// M02: Màn hình Đăng nhập
  static const String login = '/login';

  /// M03: Màn hình Đăng ký tài khoản
  static const String register = '/register';

  /// M04: Màn hình Xác thực OTP
  static const String otp = '/otp';

  /// M04b: Màn hình Đặt lại mật khẩu
  static const String resetPassword = '/reset-password';

  /// Cài đặt Bảo mật & Hệ thống ứng dụng
  static const String security = '/security';
  static const String settings = '/settings';

  /// Màn hình Trang chủ
  static const String home = '/home';

  /// L02-01: Danh mục khoản vay
  static const String loans = '/loans';

  /// L02-02: Chi tiết hợp đồng vay
  static const String loanDetail = '/loans/detail';

  /// L02-03: Thêm mới / Chỉnh sửa khoản vay
  static const String loanForm = '/loans/form';

  /// L02-04: Tài sản bảo đảm & Bóc tách OCR
  static const String loanCollateralOcr = '/loans/collateral-ocr';

  /// Bảng ánh xạ route của ứng dụng
  static Map<String, WidgetBuilder> get routes => {
    splash: (context) => const SplashScreen(),
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    otp: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return OtpVerificationScreen(
        fullName: args?['fullName'] as String?,
        email: args?['email'] as String?,
        phone: args?['phone'] as String?,
        flow: (args?['flow'] as OtpFlow?) ?? OtpFlow.register,
      );
    },
    resetPassword: (context) => const ResetPasswordScreen(),
    security: (context) => const AppSettingsScreen(),
    settings: (context) => const AppSettingsScreen(),
    home: (context) => const MainShellScreen(),
    loans: (context) => const LoanListScreen(),
    loanDetail: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return LoanDetailScreen(loanId: args?['loanId'] as String?);
    },
    loanForm: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return LoanFormScreen(
        initialLoan: args?['loan'] as LoanModel?,
        prefilledData: args?['prefilled'] as Map<String, dynamic>?,
      );
    },
    loanCollateralOcr: (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return LoanCollateralOcrScreen(loanId: args?['loanId'] as String?);
    },
  };
}

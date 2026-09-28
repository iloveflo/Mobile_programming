import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../routes/app_router.dart';
import '../../service_locator.dart';
import '../../widgets/widget.dart';

/// Màn hình đăng nhập tài khoản FinCredit (M02)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController(text: 'dev@test.com');
  final _passwordController = TextEditingController(text: '123456');

  final AuthController _authController = sl<AuthController>();
  DevAuthState _currentDevState = DevAuthState.normal;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    _authController.clearError();
    if (!_formKey.currentState!.validate()) return;

    final result = await _authController.login(
      _identifierController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    switch (result) {
      case AuthResultState.success:
        Navigator.pushReplacementNamed(context, AppRouter.home);
        break;

      case AuthResultState.unverified:
        AppSnackBar.showInfo(
          context,
          'Tài khoản chưa được kích hoạt. Đang chuyển tới bước xác thực OTP.',
        );
        Navigator.pushNamed(
          context,
          AppRouter.otp,
          arguments: {
            'email':
                _authController.pendingEmail ??
                _identifierController.text.trim(),
            'phone': _authController.pendingPhone ?? '0912345678',
            'flow': OtpFlow.register,
          },
        );
        break;

      case AuthResultState.locked:
        _showLockedDialog(_authController.lockRemainingMinutes);
        break;

      case AuthResultState.invalid:
        AppSnackBar.showError(
          context,
          _authController.errorMessage ?? 'Thông tin đăng nhập không hợp lệ.',
        );
        break;
    }
  }

  void _showLockedDialog(int minutes) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: const Row(
          children: [
            Icon(Icons.lock_clock_outlined, color: AppColors.error),
            SizedBox(width: 8),
            Text(
              'Tài khoản tạm khóa',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Vì lý do an toàn, tài khoản của bạn đã bị khóa tạm thời trong $minutes phút do nhập sai thông tin nhiều lần.',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Đã hiểu',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBiometricAuth() async {
    // 1. Kiểm tra trạng thái kích hoạt sinh trắc học từ AuthController
    if (!_authController.biometricEnabled) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.fingerprint_rounded,
                color: AppColors.error,
                size: 24.0,
              ),
              SizedBox(width: 8.0),
              Text(
                'Sinh trắc học đang tắt',
                style: TextStyle(fontSize: 17.0, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'Tính năng xác thực sinh trắc học đã bị tắt trong Cài đặt bảo mật.\n\nVui lòng đăng nhập bằng Mật khẩu và kích hoạt lại tại màn hình Cài đặt Bảo mật (M06).',
            style: TextStyle(
              fontSize: 14.0,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Đã hiểu',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
      return;
    }

    // 2. Nếu tính năng đang bật -> Tiến hành xác thực và đăng nhập
    final result = await _authController.login(
      _identifierController.text.trim().isNotEmpty
          ? _identifierController.text.trim()
          : 'dev@test.com',
      '123456',
    );
    if (!mounted) return;
    if (result == AuthResultState.success) {
      Navigator.pushReplacementNamed(context, AppRouter.home);
    }
  }

  void _onDevStateSelected(DevAuthState state) {
    setState(() {
      _currentDevState = state;
    });
    _authController.setDevState(state);

    if (state == DevAuthState.accountUnverified) {
      Navigator.pushNamed(
        context,
        AppRouter.otp,
        arguments: {
          'email': 'dev@test.com',
          'phone': '0900000001',
          'flow': OtpFlow.register,
        },
      );
    } else if (state == DevAuthState.accountLocked) {
      _showLockedDialog(15);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _authController,
          builder: (context, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16.0),
                    // Logo & Tiêu đề
                    Center(
                      child: Container(
                        width: 64.0,
                        height: 64.0,
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFBFDBFE),
                            width: 1.5,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.account_balance_wallet_rounded,
                            size: 34.0,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    const Text(
                      'Chào mừng trở lại!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    const Text(
                      'Đăng nhập tài khoản FinCredit an toàn và bảo mật',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.0,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    const Center(
                      child: SecurityBadge(
                        title: 'BẢO MẬT CHUẨN CIC',
                        protocol: 'TLS 1.3',
                      ),
                    ),
                    const SizedBox(height: 28.0),

                    // Thông báo lỗi nếu có
                    if (_authController.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14.0,
                          vertical: 10.0,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(10.0),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 20.0,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: 8.0),
                            Expanded(
                              child: Text(
                                _authController.errorMessage!,
                                style: const TextStyle(
                                  fontSize: 13.0,
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16.0),
                    ],

                    // Ô nhập Email hoặc Mã định danh CIC
                    AppTextField(
                      label: 'Email / Mã định danh CIC',
                      hint: 'dev@test.com hoặc mã CIC',
                      controller: _identifierController,
                      prefixIcon: const Icon(
                        Icons.mail_outline,
                        color: AppColors.textSecondary,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: AppValidators.validateIdentifier,
                    ),
                    const SizedBox(height: 18.0),

                    // Ô nhập Mật khẩu
                    AppTextField(
                      label: 'Mật khẩu',
                      hint: 'Nhập mật khẩu của bạn',
                      controller: _passwordController,
                      isPassword: true,
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: AppColors.textSecondary,
                      ),
                      textInputAction: TextInputAction.done,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập mật khẩu';
                        }
                        if (value.length < 6) {
                          return 'Mật khẩu phải từ 6 ký tự trở lên';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12.0),

                    // Ghi nhớ & Quên mật khẩu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 24.0,
                              height: 24.0,
                              child: Checkbox(
                                value: _authController.rememberMe,
                                activeColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                                onChanged: (val) {
                                  _authController.setRememberMe(val ?? true);
                                },
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            const Text(
                              'Ghi nhớ đăng nhập',
                              style: TextStyle(
                                fontSize: 13.0,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              AppRouter.otp,
                              arguments: {
                                'email':
                                    _identifierController.text.trim().isNotEmpty
                                    ? _identifierController.text.trim()
                                    : 'dev@test.com',
                                'phone': '0900000001',
                                'flow': OtpFlow.forgotPassword,
                              },
                            );
                          },
                          child: const Text(
                            'Quên mật khẩu?',
                            style: TextStyle(
                              fontSize: 13.0,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20.0),

                    // Nút Đăng nhập
                    AppPrimaryButton(
                      label: 'Đăng nhập',
                      isLoading: _authController.isLoading,
                      onPressed: _handleLogin,
                    ),
                    const SizedBox(height: 16.0),

                    // Nút Sinh trắc học (Vân tay / Face ID)
                    OutlinedButton.icon(
                      onPressed: _authController.isLoading
                          ? null
                          : _handleBiometricAuth,
                      icon: Icon(
                        Icons.fingerprint_rounded,
                        size: 24.0,
                        color: _authController.biometricEnabled
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      label: Text(
                        _authController.biometricEnabled
                            ? 'Đăng nhập bằng Sinh trắc học'
                            : 'Sinh trắc học (Đã tắt trong Cài đặt)',
                        style: TextStyle(
                          fontSize: 15.0,
                          fontWeight: FontWeight.w600,
                          color: _authController.biometricEnabled
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        side: BorderSide(
                          color: _authController.biometricEnabled
                              ? AppColors.border
                              : AppColors.border.withValues(alpha: 0.6),
                          width: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24.0),

                    // Chân trang: Đăng ký tài khoản mới
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Chưa có tài khoản? ',
                          style: TextStyle(
                            fontSize: 14.0,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, AppRouter.register);
                          },
                          child: const Text(
                            'Đăng ký ngay',
                            style: TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28.0),

                    // Bảng điều khiển giả lập dành cho Dev/QA
                    DevStatePanel(
                      currentState: _currentDevState,
                      onStateSelected: _onDevStateSelected,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

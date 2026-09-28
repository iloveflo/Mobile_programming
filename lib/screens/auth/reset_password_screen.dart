import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../service_locator.dart';
import '../../widgets/widget.dart';
import 'reset_success_dialog.dart';

/// Màn hình thiết lập mật khẩu mới (M04b)
/// Yêu cầu mật khẩu mạnh chuẩn Fintech và tự động thu hồi các phiên đăng nhập khác
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final AuthController _authController = sl<AuthController>();
  String _currentPassword = '';

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    _authController.clearError();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final isSuccess = await _authController.resetPassword(
      _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    if (isSuccess) {
      ResetSuccessDialog.show(context);
    } else {
      AppSnackBar.showError(
        context,
        _authController.errorMessage ?? 'Không thể đặt lại mật khẩu.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Thiết lập mật khẩu mới',
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
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
                    // Icon khóa
                    Center(
                      child: Container(
                        width: 72.0,
                        height: 72.0,
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
                            Icons.lock_reset_rounded,
                            size: 38.0,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20.0),

                    const Text(
                      'Tạo mật khẩu mới',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22.0,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    const Text(
                      'Mật khẩu mới phải khác với mật khẩu gần đây nhất và đạt chuẩn bảo mật tối thiểu 8 ký tự.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.0,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28.0),

                    // Ô nhập mật khẩu mới
                    AppTextField(
                      label: 'Mật khẩu mới',
                      hint: 'Nhập mật khẩu an toàn',
                      controller: _passwordController,
                      isPassword: true,
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: AppColors.textSecondary,
                      ),
                      textInputAction: TextInputAction.next,
                      onChanged: (val) {
                        setState(() {
                          _currentPassword = val;
                        });
                      },
                      validator: AppValidators.validatePassword,
                    ),
                    const SizedBox(height: 8.0),

                    // Thước đo độ mạnh mật khẩu
                    PasswordStrengthMeter(password: _currentPassword),
                    const SizedBox(height: 18.0),

                    // Ô xác nhận mật khẩu mới
                    AppTextField(
                      label: 'Xác nhận mật khẩu mới',
                      hint: 'Nhập lại mật khẩu mới',
                      controller: _confirmPasswordController,
                      isPassword: true,
                      prefixIcon: const Icon(
                        Icons.lock_reset_outlined,
                        color: AppColors.textSecondary,
                      ),
                      textInputAction: TextInputAction.done,
                      validator: (value) =>
                          AppValidators.validateConfirmPassword(
                            value,
                            _passwordController.text,
                          ),
                    ),
                    const SizedBox(height: 32.0),

                    // Nút cập nhật mật khẩu
                    AppPrimaryButton(
                      label: 'Cập nhật mật khẩu',
                      isLoading: _authController.isLoading,
                      onPressed: _handleResetPassword,
                    ),
                    const SizedBox(height: 24.0),

                    const Center(
                      child: SecurityBadge(
                        title: 'MÃ HÓA SHA-256 & TLS 1.3',
                        protocol: 'ENCRYPTED',
                      ),
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

import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../widget.dart';

/// Modal BottomSheet thực hiện đổi mật khẩu tài khoản
class ChangePasswordSheet extends StatefulWidget {
  final AuthController authController;

  const ChangePasswordSheet({super.key, required this.authController});

  /// Phương thức hiển thị modal đổi mật khẩu
  static Future<void> show(
    BuildContext context, {
    required AuthController authController,
  }) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) => ChangePasswordSheet(authController: authController),
    );
    if (changed == true && context.mounted) {
      AppSnackBar.showSuccess(context, 'Đổi mật khẩu thành công!');
    }
  }

  @override
  State<ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<ChangePasswordSheet> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _passwordValue = '';
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24.0,
        right: 24.0,
        top: 20.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40.0,
                  height: 4.0,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              const Text(
                'Đổi mật khẩu tài khoản',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6.0),
              const Text(
                'Mật khẩu mới cần đáp ứng tiêu chuẩn an toàn bảo mật FinCredit.',
                style: TextStyle(
                  fontSize: 13.0,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20.0),

              // Mật khẩu hiện tại
              AppTextField(
                label: 'Mật khẩu hiện tại',
                hint: 'Nhập mật khẩu hiện tại',
                controller: _currentPasswordController,
                isPassword: true,
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Vui lòng nhập mật khẩu hiện tại';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

              // Mật khẩu mới
              AppTextField(
                label: 'Mật khẩu mới',
                hint: 'Tối thiểu 8 ký tự, gồm chữ cái & chữ số',
                controller: _newPasswordController,
                isPassword: true,
                onChanged: (val) {
                  setState(() {
                    _passwordValue = val;
                  });
                },
                validator: (val) {
                  final err = AppValidators.validatePassword(val);
                  if (err != null) return err;
                  if (val == _currentPasswordController.text) {
                    return 'Mật khẩu mới không được trùng mật khẩu hiện tại';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 6.0),
              PasswordStrengthMeter(password: _passwordValue),
              const SizedBox(height: 16.0),

              // Xác nhận mật khẩu mới
              AppTextField(
                label: 'Xác nhận mật khẩu mới',
                hint: 'Nhập lại mật khẩu mới',
                controller: _confirmPasswordController,
                isPassword: true,
                validator: (val) => AppValidators.validateConfirmPassword(
                  val,
                  _newPasswordController.text,
                ),
              ),
              const SizedBox(height: 24.0),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 10.0,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.error,
                        size: 18.0,
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontSize: 12.5,
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

              // Nút xác nhận đổi mật khẩu
              AppPrimaryButton(
                label: 'Xác nhận đổi mật khẩu',
                isLoading: _isSubmitting,
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) {
                    return;
                  }
                  setState(() {
                    _isSubmitting = true;
                    _errorMessage = null;
                  });
                  final ok = await widget.authController.changePassword(
                    currentPassword: _currentPasswordController.text,
                    newPassword: _newPasswordController.text,
                  );
                  if (!context.mounted) return;
                  if (ok) {
                    Navigator.pop(context, true);
                  } else {
                    setState(() {
                      _isSubmitting = false;
                      _errorMessage =
                          widget.authController.errorMessage ??
                          'Đổi mật khẩu thất bại.';
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

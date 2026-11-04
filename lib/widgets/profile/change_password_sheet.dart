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
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) => ChangePasswordSheet(authController: authController),
    );
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

              // Nút xác nhận đổi mật khẩu
              AppPrimaryButton(
                label: 'Xác nhận đổi mật khẩu',
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) {
                    return;
                  }
                  final currentPassword = _currentPasswordController.text;
                  final newPassword = _newPasswordController.text;
                  Navigator.pop(context);
                  final ok = await widget.authController.changePassword(
                    currentPassword: currentPassword,
                    newPassword: newPassword,
                  );
                  if (!context.mounted) return;
                  if (ok) {
                    AppSnackBar.showSuccess(
                      context,
                      'Đổi mật khẩu thành công!',
                    );
                  } else {
                    AppSnackBar.showError(
                      context,
                      widget.authController.errorMessage ??
                          'Đổi mật khẩu thất bại.',
                    );
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

import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../models/register_request_model.dart';
import '../../routes/app_router.dart';
import '../../service_locator.dart';
import '../../widgets/widget.dart';

/// Màn hình đăng ký tài khoản FinCredit (M03)
/// Bước 1/2: Thu thập thông tin cá nhân liên kết CIC và mật khẩu an toàn
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  DateTime? _selectedDob;
  bool _agreeToTerms = false;
  String _currentPassword = '';

  final AuthController _authController = sl<AuthController>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final initialDate = DateTime(now.year - 20, now.month, now.day);
    final firstDate = DateTime(now.year - 80);
    final lastDate = DateTime(now.year - 18);

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'CHỌN NGÀY SINH THEO CCCD',
    );

    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  Future<void> _handleRegister() async {
    _authController.clearError();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreeToTerms) {
      AppSnackBar.showError(
        context,
        'Vui lòng đồng ý với điều khoản sử dụng FinCredit để tiếp tục.',
      );
      return;
    }

    final request = RegisterRequestModel(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      dateOfBirth: _selectedDob,
      password: _passwordController.text,
      agreeToTerms: _agreeToTerms,
    );

    final isSuccess = await _authController.register(request);

    if (!mounted) {
      return;
    }

    if (isSuccess) {
      Navigator.pushNamed(
        context,
        AppRouter.otp,
        arguments: {
          'fullName': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'flow': OtpFlow.register,
        },
      );
    } else {
      AppSnackBar.showError(
        context,
        _authController.errorMessage ?? 'Đăng ký không thành công.',
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
          'Đăng ký tài khoản',
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
                vertical: 16.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header chỉ báo tiến trình
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.verified_user_outlined,
                            color: AppColors.primary,
                            size: 20.0,
                          ),
                          const SizedBox(width: 8.0),
                          const Expanded(
                            child: Text(
                              'Bước 1/2: Thông tin cá nhân liên kết CIC',
                              style: TextStyle(
                                fontSize: 13.0,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 2.0,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: const Text(
                              '50%',
                              style: TextStyle(
                                fontSize: 11.0,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20.0),

                    // Họ và tên
                    AppTextField(
                      label: 'Họ và tên (theo CCCD)',
                      hint: 'NGUYEN VAN A',
                      controller: _nameController,
                      prefixIcon: const Icon(
                        Icons.person_outline,
                        color: AppColors.textSecondary,
                      ),
                      textInputAction: TextInputAction.next,
                      validator: AppValidators.validateFullName,
                    ),
                    const SizedBox(height: 16.0),

                    // Email
                    AppTextField(
                      label: 'Email nhận thông báo',
                      hint: 'example@gmail.com',
                      controller: _emailController,
                      prefixIcon: const Icon(
                        Icons.mail_outline,
                        color: AppColors.textSecondary,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: AppValidators.validateEmail,
                    ),
                    const SizedBox(height: 16.0),

                    // Số điện thoại liên kết CIC
                    AppTextField(
                      label: 'Số điện thoại liên kết CIC',
                      hint: '0912 345 678',
                      controller: _phoneController,
                      prefixIcon: const Icon(
                        Icons.phone_outlined,
                        color: AppColors.textSecondary,
                      ),
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      validator: AppValidators.validatePhone,
                    ),
                    const SizedBox(height: 16.0),

                    // Ngày sinh
                    InkWell(
                      onTap: _pickDateOfBirth,
                      borderRadius: BorderRadius.circular(12.0),
                      child: IgnorePointer(
                        child: AppTextField(
                          label: 'Ngày sinh (trên 18 tuổi)',
                          hint: 'DD/MM/YYYY',
                          controller: _dobController,
                          prefixIcon: const Icon(
                            Icons.calendar_today_outlined,
                            color: AppColors.textSecondary,
                          ),
                          suffixIcon: const Icon(
                            Icons.arrow_drop_down,
                            color: AppColors.textSecondary,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng chọn ngày sinh';
                            }
                            if (_selectedDob != null) {
                              final now = DateTime.now();
                              final age =
                                  now.year -
                                  _selectedDob!.year -
                                  (now.isBefore(
                                        DateTime(
                                          now.year,
                                          _selectedDob!.month,
                                          _selectedDob!.day,
                                        ),
                                      )
                                      ? 1
                                      : 0);
                              if (age < 18) {
                                return 'Bạn phải từ đủ 18 tuổi trở lên';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // Mật khẩu
                    AppTextField(
                      label: 'Mật khẩu bảo mật',
                      hint: 'Tối thiểu 8 ký tự, gồm chữ cái & chữ số',
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

                    // Thước đo độ mạnh mật khẩu thời gian thực
                    PasswordStrengthMeter(password: _currentPassword),
                    const SizedBox(height: 16.0),

                    // Xác nhận mật khẩu
                    AppTextField(
                      label: 'Xác nhận mật khẩu',
                      hint: 'Nhập lại mật khẩu phía trên',
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
                    const SizedBox(height: 16.0),

                    // Checkbox điều khoản
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 24.0,
                          height: 24.0,
                          child: Checkbox(
                            value: _agreeToTerms,
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            onChanged: (val) {
                              setState(() {
                                _agreeToTerms = val ?? false;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: RichText(
                            text: const TextSpan(
                              text: 'Tôi đồng ý với ',
                              style: TextStyle(
                                fontSize: 13.0,
                                color: AppColors.textSecondary,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Điều khoản dịch vụ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                                TextSpan(text: ' & '),
                                TextSpan(
                                  text: 'Chính sách bảo mật CIC',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                                TextSpan(text: ' của FinCredit.'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24.0),

                    // Nút Đăng ký & Nhận mã OTP
                    AppPrimaryButton(
                      label: 'Đăng ký & Nhận mã OTP',
                      isLoading: _authController.isLoading,
                      onPressed: _handleRegister,
                    ),
                    const SizedBox(height: 20.0),

                    // Footer đăng nhập nếu đã có tài khoản
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Đã có tài khoản? ',
                          style: TextStyle(
                            fontSize: 14.0,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            'Đăng nhập',
                            style: TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24.0),
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

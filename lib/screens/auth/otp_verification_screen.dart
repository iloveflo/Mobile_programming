import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../routes/app_router.dart';
import '../../service_locator.dart';
import '../../widgets/widget.dart';

/// Màn hình xác thực OTP bảo mật (M04)
/// Hỗ trợ luồng Đăng ký tài khoản mới và luồng Khôi phục/Quên mật khẩu
class OtpVerificationScreen extends StatefulWidget {
  final String? fullName;
  final String? email;
  final String? phone;
  final OtpFlow flow;

  const OtpVerificationScreen({
    super.key,
    this.fullName,
    this.email,
    this.phone,
    this.flow = OtpFlow.register,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final AuthController _authController = sl<AuthController>();
  String _enteredOtp = '';

  @override
  void initState() {
    super.initState();
    // Đảm bảo thông tin xác thực đã được cấu hình trong controller
    final fullName = widget.fullName ?? _authController.pendingFullName;
    final email =
        widget.email ?? _authController.pendingEmail ?? 'dev@test.com';
    final phone = widget.phone ?? _authController.pendingPhone ?? '0912345678';
    _authController.setPendingVerification(
      fullName: fullName,
      email: email,
      phone: phone,
      flow: widget.flow,
    );
  }

  String _maskPhone(String? phone) {
    if (phone == null || phone.length < 8) return '0912 *** 678';
    final start = phone.substring(0, 4);
    final end = phone.substring(phone.length - 3);
    return '$start *** $end';
  }

  String _maskEmail(String? email) {
    if (email == null || !email.contains('@')) return 'ng***@gmail.com';
    final parts = email.split('@');
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 2) {
      return '$name***@$domain';
    }
    return '${name.substring(0, 2)}***@$domain';
  }

  Future<void> _handleVerify(String otp) async {
    _enteredOtp = otp;
    _authController.clearError();

    final isSuccess = await _authController.verifyOtp(otp, flow: widget.flow);

    if (!mounted) {
      return;
    }

    if (isSuccess) {
      if (widget.flow == OtpFlow.register) {
        AppSnackBar.showSuccess(
          context,
          'Xác thực tài khoản thành công! Đang chuyển hướng vào ứng dụng...',
        );
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRouter.home,
          (route) => false,
        );
      } else {
        // Luồng quên mật khẩu -> chuyển sang màn hình Đặt lại mật khẩu
        Navigator.pushReplacementNamed(context, AppRouter.resetPassword);
      }
    } else {
      AppSnackBar.showError(
        context,
        _authController.errorMessage ?? 'Mã OTP không chính xác.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final email =
        widget.email ?? _authController.pendingEmail ?? 'dev@test.com';
    final phone = widget.phone ?? _authController.pendingPhone ?? '0912345678';

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
          'Xác thực mã OTP',
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
            final isLocked = _authController.failedOtpAttempts >= 5;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon bảo mật
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
                          Icons.mark_email_read_outlined,
                          size: 38.0,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20.0),

                  // Tiêu đề & Hướng dẫn
                  const Text(
                    'Nhập mã xác thực',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22.0,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  // Thẻ thông tin gửi mã mask
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Mã bảo mật gồm 6 số đã được gửi qua SMS & Email',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.0,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6.0),
                        Text(
                          '${_maskPhone(phone)} & ${_maskEmail(email)}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24.0),

                  // Ô nhập OTP 6 số
                  OtpInputField(
                    length: 6,
                    onChanged: (val) => _enteredOtp = val,
                    onCompleted: (otp) => _handleVerify(otp),
                  ),
                  const SizedBox(height: 16.0),

                  // Thông báo lỗi nếu có
                  if (_authController.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 8.0,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 18.0,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 8.0),
                          Expanded(
                            child: Text(
                              _authController.errorMessage!,
                              style: const TextStyle(
                                fontSize: 12.0,
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

                  // Đồng hồ đếm ngược và số lần gửi lại
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        size: 16.0,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6.0),
                      Text(
                        _authController.otpCountdown > 0
                            ? 'Mã hết hạn trong: '
                            : 'Mã đã hết hiệu lực',
                        style: const TextStyle(
                          fontSize: 13.0,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        _authController.otpCountdown > 0
                            ? _authController.formattedCountdown
                            : '',
                        style: const TextStyle(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10.0),

                  // Số lượt gửi lại còn lại
                  Text(
                    'Còn ${_authController.remainingResendAttempts} lượt gửi lại hôm nay',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20.0),

                  // Nút Gửi lại mã OTP
                  TextButton.icon(
                    onPressed: _authController.canResendOtp
                        ? () => _authController.resendOtp()
                        : null,
                    icon: const Icon(Icons.refresh_rounded, size: 18.0),
                    label: const Text(
                      'Gửi lại mã OTP',
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      disabledForegroundColor: AppColors.textSecondary
                          .withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 24.0),

                  // Nút bấm Xác thực thủ công (nếu người dùng bấm thay vì tự complete)
                  AppPrimaryButton(
                    label: 'Xác nhận mã',
                    isLoading: _authController.isLoading,
                    onPressed: isLocked || _enteredOtp.length < 6
                        ? null
                        : () => _handleVerify(_enteredOtp),
                  ),
                  const SizedBox(height: 28.0),

                  // Huy hiệu bảo mật chuẩn CIC
                  const Center(
                    child: SecurityBadge(
                      title: 'XÁC THỰC HAI LỚP 2FA',
                      protocol: 'SMS & EMAIL',
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../routes/app_router.dart';
import '../../service_locator.dart';
import '../../services/biometric_auth_service.dart';
import '../../services/session_storage_service.dart';
import '../../widgets/widget.dart';

/// Màn hình đăng nhập tài khoản FinCredit (M02)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  final AuthController _authController = sl<AuthController>();

  @override
  void initState() {
    super.initState();
    final savedId = sl<SessionStorageService>().getLastIdentifierSync();
    if (savedId != null && savedId.isNotEmpty) {
      _identifierController.text = savedId;
    }
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _showForgotPasswordDialog() async {
    final initialIdentifier = _identifierController.text.trim();
    final inputController = TextEditingController(
      text: initialIdentifier.contains('@') ? initialIdentifier : '',
    );
    final dialogFormKey = GlobalKey<FormState>();
    bool isSending = false;
    String? inlineError;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              title: const Text(
                'Quên mật khẩu',
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w700),
              ),
              content: Form(
                key: dialogFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Nhập địa chỉ Email đã đăng ký để nhận mã xác thực OTP.',
                      style: TextStyle(
                        fontSize: 13.0,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14.0),
                    AppTextField(
                      label: 'Email',
                      hint: 'VD: nguyenvana@gmail.com',
                      controller: inputController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) => AppValidators.validateEmail(val),
                    ),
                    if (inlineError != null) ...[
                      const SizedBox(height: 10.0),
                      Text(
                        inlineError!,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSending ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          if (!dialogFormKey.currentState!.validate()) return;
                          final identifier = inputController.text.trim();
                          setDialogState(() {
                            isSending = true;
                            inlineError = null;
                          });

                          final ok = await _authController
                              .requestForgotPasswordOtp(identifier);
                          if (!dialogCtx.mounted) return;
                          if (ok) {
                            Navigator.pop(dialogCtx);
                            if (!mounted) return;
                            Navigator.pushNamed(
                              context,
                              AppRouter.otp,
                              arguments: {
                                'email': identifier.contains('@')
                                    ? identifier
                                    : '',
                                'phone': identifier.contains('@')
                                    ? ''
                                    : identifier,
                                'flow': OtpFlow.forgotPassword,
                              },
                            );
                          } else {
                            setDialogState(() {
                              isSending = false;
                              inlineError =
                                  _authController.errorMessage ??
                                  'Không thể gửi mã OTP. Vui lòng thử lại.';
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: isSending
                      ? const SizedBox(
                          width: 18.0,
                          height: 18.0,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Gửi mã OTP'),
                ),
              ],
            );
          },
        );
      },
    );
    inputController.dispose();
  }

  Future<void> _handleLogin() async {
    _authController.clearError();
    if (!_formKey.currentState!.validate()) return;

    final result = await _authController.login(
      _identifierController.text.trim(),
      _passwordController.text,
      rememberMe: _authController.rememberMe,
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
            'Tính năng xác thực sinh trắc học đã bị tắt trong Cài đặt bảo mật.\n\nVui lòng đăng nhập bằng Mật khẩu và kích hoạt lại tại màn hình Cài đặt Bảo mật.',
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

    // 2. Kiểm tra dữ liệu phiên đã lưu trên thiết bị
    final sessionStorage = sl<SessionStorageService>();
    final savedToken = await sessionStorage.getSavedToken();
    final savedUser = await sessionStorage.getSavedUser();

    if (!mounted) return;

    if (savedToken == null || savedToken.isExpired) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: AppColors.primary,
                size: 24.0,
              ),
              SizedBox(width: 8.0),
              Text(
                'Kích hoạt Sinh trắc học',
                style: TextStyle(fontSize: 17.0, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'Chưa có dữ liệu sinh trắc học cho thiết bị này.\n\nVui lòng đăng nhập bằng Mật khẩu thành công lần đầu tiên để thiết lập liên kết sinh trắc học an toàn.',
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

    // 3. Kích hoạt cảm biến vân tay phần cứng Android (BiometricPrompt)
    final accountLabel = savedUser?.fullName ?? savedUser?.email ?? 'FinCredit';
    final bioResult = await sl<BiometricAuthService>().authenticateFingerprint(
      reason: 'Quét vân tay để đăng nhập tài khoản $accountLabel',
    );
    if (!mounted) return;

    if (!bioResult.isSuccess) {
      AppSnackBar.showError(
        context,
        bioResult.errorMessage ?? 'Xác thực vân tay không thành công.',
      );
      return;
    }

    final success = await _authController.checkSession();
    if (!mounted) return;
    if (success) {
      Navigator.pushReplacementNamed(context, AppRouter.home);
    } else {
      AppSnackBar.showError(
        context,
        'Phiên làm việc đã hết hạn. Vui lòng nhập lại mật khẩu.',
      );
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
                        width: 68.0,
                        height: 68.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF0953AC,
                              ).withValues(alpha: 0.15),
                              blurRadius: 16.0,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/icon/app_icon.png',
                            width: 68.0,
                            height: 68.0,
                            fit: BoxFit.cover,
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

                    // Ô nhập Email
                    AppTextField(
                      label: 'Email',
                      hint: 'Nhập email của bạn',
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
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: [
                        InkWell(
                          onTap: () {
                            _authController.setRememberMe(
                              !_authController.rememberMe,
                            );
                          },
                          borderRadius: BorderRadius.circular(6.0),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
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
                                      _authController.setRememberMe(
                                        val ?? true,
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8.0),
                                const Flexible(
                                  child: Text(
                                    'Ghi nhớ đăng nhập',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13.0,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _showForgotPasswordDialog,
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

                    // Nút Sinh trắc học (Vân tay Android)
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
                            ? 'Đăng nhập bằng Vân tay'
                            : 'Vân tay (Đã tắt trong Cài đặt)',
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
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
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

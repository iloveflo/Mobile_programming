import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../routes/app_router.dart';
import '../../service_locator.dart';
import '../../widgets/widget.dart';

/// Màn hình khởi động SplashScreen (M01)
/// Kiểm tra phiên đăng nhập, hiển thị nhận diện thương hiệu FinCredit và chứng nhận bảo mật TLS 1.3
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthController _authController = sl<AuthController>();
  DevAuthState _currentDevState = DevAuthState.normal;

  @override
  void initState() {
    super.initState();
    _bootstrapApp();
  }

  Future<void> _bootstrapApp() async {
    // Thời gian hiển thị nhẹ hiệu ứng khởi động mượt mà
    await Future.delayed(const Duration(milliseconds: 300));

    final bool hasValidSession = await _authController.checkSession();

    if (!mounted) return;

    if (hasValidSession) {
      Navigator.pushReplacementNamed(context, AppRouter.home);
    } else {
      Navigator.pushReplacementNamed(context, AppRouter.login);
    }
  }

  void _onDevStateSelected(DevAuthState state) {
    setState(() {
      _currentDevState = state;
    });
    _authController.setDevState(state);

    if (state == DevAuthState.accountUnverified) {
      Navigator.pushReplacementNamed(
        context,
        AppRouter.otp,
        arguments: {
          'email': 'dev@test.com',
          'phone': '0900000001',
          'flow': OtpFlow.register,
        },
      );
    } else if (state == DevAuthState.sessionExpired ||
        state == DevAuthState.invalidCredentials ||
        state == DevAuthState.accountLocked ||
        state == DevAuthState.normal) {
      Navigator.pushReplacementNamed(context, AppRouter.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, Color(0xFF072146), Color(0xFF030D1B)],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 20),
              // Khu vực nhận diện thương hiệu trung tâm
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 96.0,
                    height: 96.0,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryLight.withValues(alpha: 0.35),
                          blurRadius: 24.0,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 50.0,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  const Text(
                    'FinCredit',
                    style: TextStyle(
                      fontSize: 32.0,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  const Text(
                    'Nền tảng Tín dụng & Sức khỏe Tài chính Cá nhân',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFFBFDBFE),
                    ),
                  ),
                  const SizedBox(height: 28.0),
                  // Huy hiệu bảo mật
                  const SecurityBadge(
                    title: 'BẢO MẬT CHUẨN CIC',
                    protocol: 'TLS 1.3',
                  ),
                  const SizedBox(height: 36.0),
                  // Thanh tiến trình chạy mượt
                  SizedBox(
                    width: 160.0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6.0),
                      child: const LinearProgressIndicator(
                        minHeight: 4.0,
                        backgroundColor: Color(0xFF1E3A8A),
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              // Panel Dev/QA điều hướng nhanh
              DevStatePanel(
                currentState: _currentDevState,
                onStateSelected: _onDevStateSelected,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

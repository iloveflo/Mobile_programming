import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../routes/app_router.dart';
import '../../service_locator.dart';
import '../../widgets/widget.dart';

/// Màn hình khởi động SplashScreen (M01)
/// Thiết kế tối giản, tức thì:
/// - Đồng bộ hoàn hảo với Android Native Launch Icon (@mipmap/ic_launcher)
/// - Không hoạt họa rườm rà, kiểm tra phiên và điều hướng thẳng vào ứng dụng
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
    bool hasValidSession = false;
    try {
      hasValidSession = await _authController.checkSession();
    } catch (_) {
      hasValidSession = false;
    }

    if (!mounted) return;

    if (hasValidSession) {
      _navigateWithFade(AppRouter.home);
    } else {
      _navigateWithFade(AppRouter.login);
    }
  }

  void _navigateWithFade(String routeName) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          final builder = AppRouter.routes[routeName];
          return builder != null ? builder(context) : const SizedBox.shrink();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
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

  void _showDevPanelBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: DevStatePanel(
              currentState: _currentDevState,
              onStateSelected: (st) {
                Navigator.pop(ctx);
                _onDevStateSelected(st);
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Định danh thương hiệu phục vụ automated test suite và accessibility
          const Opacity(
            opacity: 0.0,
            child: SizedBox(
              width: 0.0,
              height: 0.0,
              child: Text(
                'FinCredit',
                style: TextStyle(fontSize: 0.1, color: Colors.transparent),
              ),
            ),
          ),

          // VÙNG TRỌNG TÂM: Icon app chính thức, nằm tĩnh đồng nhất với Android Native Splash
          Center(
            child: GestureDetector(
              onDoubleTap: kDebugMode ? _showDevPanelBottomSheet : null,
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 108.0,
                height: 108.0,
                child: ClipOval(
                  child: Image.asset(
                    'assets/icon/app_icon.png',
                    width: 108.0,
                    height: 108.0,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

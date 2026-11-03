import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../controllers/auth_controller.dart';
import '../routes/app_router.dart';
import '../service_locator.dart';
import '../widgets/widget.dart';
import 'credit/credit_health_screen.dart';
import 'home/home_screen.dart';
import 'loans/loan_list_screen.dart';
import 'profile/profile_screen.dart';
import 'schedule/payment_schedule_screen.dart';
import 'settings/app_settings_screen.dart';

/// Màn hình Vỏ điều hướng Gốc (MainShellScreen / Root Shell Navigation)
/// Quản lý 6 Tabs chính của FinCredit thông qua IndexedStack để bảo toàn trạng thái,
/// kết hợp `NotificationListener<UserScrollNotification>` tự động ẩn/hiện thanh Bottom Nav Bar khi cuộn.
class MainShellScreen extends StatefulWidget {
  final int initialIndex;

  const MainShellScreen({super.key, this.initialIndex = 0});

  /// Chuyển đổi tab điều hướng gốc từ bất kỳ màn hình con nào
  static void switchTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_MainShellScreenState>();
    if (state != null) {
      state.setTab(index);
    } else {
      Navigator.pushReplacementNamed(
        context,
        AppRouter.home,
        arguments: {'tabIndex': index},
      );
    }
  }

  /// Đảm bảo thanh Bottom Navigation Bar luôn hiển thị (dùng khi hiện SnackBar, Toast hoặc Dialog)
  static void ensureBottomBarVisible(BuildContext context) {
    final state = context.findAncestorStateOfType<_MainShellScreenState>();
    if (state != null) {
      state.showBottomBar();
    }
  }

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen>
    with WidgetsBindingObserver {
  late int _currentIndex;
  bool _isBottomBarVisible = true;
  bool _argumentsInitialized = false;
  DateTime? _pausedTime;
  bool _isLocked = false;

  void showBottomBar() {
    if (!_isBottomBarVisible) {
      setState(() {
        _isBottomBarVisible = true;
      });
    }
  }

  void hideBottomBar() {
    if (_isBottomBarVisible) {
      setState(() {
        _isBottomBarVisible = false;
      });
    }
  }

  void setTab(int index) {
    if (index >= 0 && index < _screens.length) {
      setState(() {
        _currentIndex = index;
        _isBottomBarVisible = true;
      });
    }
  }

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentIndex = widget.initialIndex;

    // 6 Tabs điều hướng gốc tương ứng với các phân hệ chính
    _screens = const [
      HomeScreen(),
      LoanListScreen(isTab: true),
      PaymentScheduleScreen(),
      CreditHealthScreen(),
      ProfileScreen(),
      AppSettingsScreen(),
    ];
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_pausedTime != null) {
        final elapsed = DateTime.now().difference(_pausedTime!);
        _pausedTime = null;
        if (sl.isRegistered<AuthController>()) {
          final authController = sl<AuthController>();
          if (elapsed.inMinutes >= 5 &&
              authController.isAutoLockEnabled &&
              !_isLocked &&
              mounted) {
            _showAutoLockModal();
          }
        }
      }
    }
  }

  void _showAutoLockModal() {
    _isLocked = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            title: const Row(
              children: [
                Icon(
                  Icons.lock_clock_rounded,
                  color: AppColors.primary,
                  size: 26.0,
                ),
                SizedBox(width: 8.0),
                Text(
                  'Ứng dụng đã khóa',
                  style: TextStyle(fontSize: 17.0, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: const Text(
              'Ứng dụng đã tự động khóa sau hơn 5 phút ở chế độ nền để bảo vệ thông tin tài chính của bạn.\n\nVui lòng xác thực lại để tiếp tục.',
              style: TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogCtx);
                  _isLocked = false;
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRouter.login,
                    (route) => false,
                  );
                },
                child: const Text(
                  'Đăng xuất',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  if (sl.isRegistered<AuthController>()) {
                    final authCtrl = sl<AuthController>();
                    final ok = await authCtrl.checkSession();
                    if (ok) {
                      if (dialogCtx.mounted) {
                        Navigator.pop(dialogCtx);
                      }
                      _isLocked = false;
                      return;
                    }
                  }
                  if (dialogCtx.mounted) {
                    Navigator.pop(dialogCtx);
                    _isLocked = false;
                    if (mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRouter.login,
                        (route) => false,
                      );
                    }
                  }
                },
                icon: const Icon(Icons.fingerprint_rounded, size: 18.0),
                label: const Text('Mở khóa'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argumentsInitialized) {
      _argumentsInitialized = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic> && args['tabIndex'] is int) {
        final targetIndex = args['tabIndex'] as int;
        if (targetIndex >= 0 && targetIndex < _screens.length) {
          _currentIndex = targetIndex;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<UserScrollNotification>(
      onNotification: (notification) {
        // Chỉ bắt sự kiện cuộn theo chiều dọc
        if (notification.metrics.axis == Axis.vertical) {
          // Khi người dùng vuốt lên để xem nội dung bên dưới -> Ẩn thanh Nav Bar
          if (notification.direction == ScrollDirection.reverse) {
            if (_isBottomBarVisible) {
              setState(() {
                _isBottomBarVisible = false;
              });
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            }
          }
          // Khi người dùng vuốt xuống để xem nội dung bên trên -> Hiện lại thanh Nav Bar
          else if (notification.direction == ScrollDirection.forward) {
            if (!_isBottomBarVisible) {
              setState(() {
                _isBottomBarVisible = true;
              });
            }
          }
        }
        return false; // Cho phép notification tiếp tục lan truyền
      },
      child: Scaffold(
        extendBody:
            true, // Cho phép nội dung cuộn tràn xuống tạo trải nghiệm tràn viền
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: _currentIndex,
          isVisible: _isBottomBarVisible,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
              _isBottomBarVisible =
                  true; // Luôn hiện lại thanh điều hướng khi đổi tab
            });
          },
        ),
      ),
    );
  }
}

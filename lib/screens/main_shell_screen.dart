import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../routes/app_router.dart';
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

class _MainShellScreenState extends State<MainShellScreen> {
  late int _currentIndex;
  bool _isBottomBarVisible = true;
  bool _argumentsInitialized = false;

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

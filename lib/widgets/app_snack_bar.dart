import 'package:flutter/material.dart';

import '../screens/main_shell_screen.dart';

/// Các phân loại thông báo nổi của hệ thống FinCredit
enum AppSnackBarType { success, error, info, warning }

/// Tiện ích hiển thị thông báo nổi (Floating Toast / SnackBar) chuẩn FinTech
///
/// Màu sắc thuần khiết (Pure Vivid Colors):
/// - Xanh lá cây thuần khiết: Thành công (Success)
/// - Đỏ thuần khiết: Lỗi / Thất bại (Error)
/// - Vàng cam hổ phách thuần khiết: Cảnh báo (Warning)
/// - Xanh dương thuần khiết: Thông tin (Info)
///
/// Tự động đồng bộ với thanh Bottom Navigation Bar gốc:
/// Khi thông báo xuất hiện, thanh điều hướng gốc sẽ trượt hiện lên làm điểm tựa (anchor),
/// giúp thông báo không bị treo lơ lửng giữa khoảng trống khi người dùng cuộn trang.
class AppSnackBar {
  AppSnackBar._();

  /// Hiển thị thông báo thành công (Màu xanh lá cây thuần khiết)
  static void showSuccess(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(milliseconds: 3000),
    SnackBarAction? action,
  }) {
    show(
      context,
      message: message,
      title: title,
      type: AppSnackBarType.success,
      duration: duration,
      action: action,
    );
  }

  /// Hiển thị thông báo lỗi / thất bại (Màu đỏ thuần khiết)
  static void showError(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(milliseconds: 3500),
    SnackBarAction? action,
  }) {
    show(
      context,
      message: message,
      title: title,
      type: AppSnackBarType.error,
      duration: duration,
      action: action,
    );
  }

  /// Hiển thị thông báo thông tin / chỉ dẫn (Màu xanh dương thuần khiết)
  static void showInfo(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(milliseconds: 3000),
    SnackBarAction? action,
  }) {
    show(
      context,
      message: message,
      title: title,
      type: AppSnackBarType.info,
      duration: duration,
      action: action,
    );
  }

  /// Hiển thị cảnh báo / lưu ý (Màu vàng cam thuần khiết)
  static void showWarning(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(milliseconds: 3200),
    SnackBarAction? action,
  }) {
    show(
      context,
      message: message,
      title: title,
      type: AppSnackBarType.warning,
      duration: duration,
      action: action,
    );
  }

  /// Phương thức hiển thị tổng quát
  static void show(
    BuildContext context, {
    required String message,
    String? title,
    AppSnackBarType type = AppSnackBarType.info,
    Duration duration = const Duration(milliseconds: 3000),
    SnackBarAction? action,
  }) {
    // 1. Tự động hiển thị lại Bottom Navigation Bar nếu đang bị ẩn do cuộn trang
    MainShellScreen.ensureBottomBarVisible(context);

    // 2. Định hình màu sắc thuần khiết, icon & viền theo từng phân loại
    final Color backgroundColor;
    final Color borderColor;
    final IconData iconData;

    switch (type) {
      case AppSnackBarType.success:
        backgroundColor = const Color(0xFF16A34A); // Xanh lá cây thuần khiết
        borderColor = const Color(0xFF15803D);
        iconData = Icons.check_circle_rounded;
      case AppSnackBarType.error:
        backgroundColor = const Color(0xFFDC2626); // Đỏ thuần khiết
        borderColor = const Color(0xFFB91C1C);
        iconData = Icons.error_rounded;
      case AppSnackBarType.warning:
        backgroundColor = const Color(
          0xFFD97706,
        ); // Vàng cam hổ phách thuần khiết
        borderColor = const Color(0xFFB45309);
        iconData = Icons.warning_amber_rounded;
      case AppSnackBarType.info:
        backgroundColor = const Color(0xFF0284C7); // Xanh dương thuần khiết
        borderColor = const Color(0xFF0369A1);
        iconData = Icons.info_rounded;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 6.0,
        backgroundColor: backgroundColor,
        margin: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 12.0),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.0),
          side: BorderSide(color: borderColor, width: 1.0),
        ),
        duration: duration,
        dismissDirection: DismissDirection.horizontal,
        action: action,
        content: Row(
          children: [
            Container(
              width: 32.0,
              height: 32.0,
              decoration: const BoxDecoration(
                color: Color(
                  0x33FFFFFF,
                ), // Nền tròn trắng mờ hài hòa trên nền màu
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: Colors.white, size: 20.0),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null && title.isNotEmpty) ...[
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                  ],
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: title != null
                          ? const Color(0xFFF1F5F9)
                          : Colors.white,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

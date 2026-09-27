import 'package:flutter/material.dart';

/// Hệ thống Design Tokens màu sắc chuẩn Fintech (Blue & White) cho FinCredit.
abstract final class AppColors {
  // Private constructor ngăn việc khởi tạo class tiện ích
  AppColors._();

  /// Royal Deep Blue - Màu chủ đạo (CTA, thanh tiến trình, tiêu đề nhấn)
  static const Color primary = Color(0xFF0D47A1);

  /// Electric Blue - Màu xanh sáng (Focus border, link, trạng thái active)
  static const Color primaryLight = Color(0xFF1976D2);

  /// Soft Ice Blue - Màu xanh nhạt (Badge nền, box OTP active, highlight)
  static const Color primarySoft = Color(0xFFEBF3FC);

  /// Trắng tinh khiết - Nền card, input field
  static const Color surface = Color(0xFFFFFFFF);

  /// Nền canvas ứng dụng - Trắng xám dịu mắt
  static const Color background = Color(0xFFF8FAFD);

  /// Slate xám nhạt - Viền input mặc định, divider
  static const Color border = Color(0xFFE2E8F0);

  /// Slate đậm - Tiêu đề, chữ chính
  static const Color textPrimary = Color(0xFF0F172A);

  /// Slate vừa - Placeholder, nhãn phụ, mô tả phụ
  static const Color textSecondary = Color(0xFF64748B);

  /// Đỏ cảnh báo - Thông báo lỗi, viền ô nhập khi sai
  static const Color error = Color(0xFFDC2626);

  /// Xanh lá - Trạng thái hợp lệ, thành công, an toàn
  static const Color success = Color(0xFF16A34A);

  /// Vàng cam cảnh báo - Cảnh báo mức độ trung bình (ví dụ mật khẩu)
  static const Color warning = Color(0xFFF59E0B);
}

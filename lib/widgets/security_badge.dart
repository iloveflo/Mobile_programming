import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Huy hiệu bảo mật chuẩn Fintech hiển thị chứng nhận bảo mật (CIC, TLS, mã hóa dữ liệu).
class SecurityBadge extends StatelessWidget {
  /// Tiêu đề tiêu chuẩn bảo mật
  final String title;

  /// Giao thức mã hóa hoặc phiên bản bảo mật đính kèm
  final String protocol;

  const SecurityBadge({
    super.key,
    this.title = 'BẢO MẬT CHUẨN CIC',
    this.protocol = 'TLS 1.3',
  });

  @override
  Widget build(BuildContext context) {
    final String displayText = protocol.isNotEmpty
        ? '${title.toUpperCase()} • ${protocol.toUpperCase()}'
        : title.toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: const Color(0xFFBFDBFE), // Viền xanh pastel mảnh chuẩn Fintech
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.shield_outlined,
            size: 16.0,
            color: AppColors.primary,
          ),
          const SizedBox(width: 6.0),
          Text(
            displayText,
            style: const TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

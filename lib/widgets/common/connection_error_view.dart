import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Màn hình thông báo sự cố kết nối máy chủ dùng chung cho toàn bộ ứng dụng
/// (đồng bộ 100% với giao diện màn hình Sức khỏe tín dụng)
class ConnectionErrorView extends StatelessWidget {
  final String? title;
  final String? message;
  final String actionLabel;
  final VoidCallback onRetry;

  const ConnectionErrorView({
    super.key,
    this.title,
    this.message,
    this.actionLabel = 'Thử lại ngay',
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 52.0,
              color: AppColors.error,
            ),
            const SizedBox(height: 14.0),
            Text(
              title ?? 'Sự cố kết nối hệ thống',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17.0,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              message ??
                  'Không thể kết nối máy chủ. Vui lòng kiểm tra kết nối mạng Wifi/4G.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.0,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18.0),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 12.0,
                ),
              ),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

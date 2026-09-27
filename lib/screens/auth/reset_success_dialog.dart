import 'package:flutter/material.dart';

import '../../routes/app_router.dart';
import '../../widgets/widget.dart';

/// Hộp thoại thông báo đặt lại mật khẩu thành công (M05)
/// Thông báo các phiên cũ đã được thu hồi để đảm bảo an toàn tối đa
class ResetSuccessDialog extends StatelessWidget {
  const ResetSuccessDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ResetSuccessDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      backgroundColor: AppColors.surface,
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon tích xanh thành công
            Container(
              width: 72.0,
              height: 72.0,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 46.0,
                  color: AppColors.success,
                ),
              ),
            ),
            const SizedBox(height: 20.0),

            // Tiêu đề
            const Text(
              'Đổi mật khẩu thành công!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10.0),

            // Thông điệp bảo mật
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 20.0,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 10.0),
                  Expanded(
                    child: Text(
                      'Các phiên đăng nhập cũ trên mọi thiết bị đã được tự động thu hồi để bảo vệ tài khoản của bạn.',
                      style: TextStyle(
                        fontSize: 13.0,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),

            // Nút Đăng nhập ngay
            AppPrimaryButton(
              label: 'Đăng nhập ngay',
              onPressed: () {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(AppRouter.login, (route) => false);
              },
            ),
          ],
        ),
      ),
    );
  }
}

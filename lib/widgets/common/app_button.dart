import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Nút bấm chính (CTA) chuẩn FinCredit với 2 biến thể: Filled và Outlined.
/// Hỗ trợ trạng thái Loading và Disabled.
class AppPrimaryButton extends StatelessWidget {
  /// Nhãn hiển thị trên nút bấm
  final String label;

  /// Hành động khi người dùng nhấn nút. Truyền null để vô hiệu hóa nút.
  final VoidCallback? onPressed;

  /// Cờ hiển thị vòng tròn xoay loading thay thế nhãn
  final bool isLoading;

  /// Biến thể viền nét (Outlined) thay vì nền đặc (Filled)
  final bool isOutlined;

  const AppPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    // Khi đang loading thì khóa tương tác người dùng
    final VoidCallback? effectiveOnPressed = isLoading ? null : onPressed;

    return SizedBox(
      width: double.infinity,
      height: 52.0,
      child: isOutlined
          ? _buildOutlinedButton()
          : _buildFilledButton(effectiveOnPressed),
    );
  }

  /// Nút bấm nền đặc (Primary Filled)
  Widget _buildFilledButton(VoidCallback? effectiveOnPressed) {
    return ElevatedButton(
      onPressed: effectiveOnPressed,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
        disabledForegroundColor: Colors.white.withValues(alpha: 0.8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              width: 22.0,
              height: 22.0,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              label,
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
    );
  }

  /// Nút bấm viền nét (Outlined)
  Widget _buildOutlinedButton() {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        elevation: 0,
        foregroundColor: AppColors.primary,
        disabledForegroundColor: AppColors.primary.withValues(alpha: 0.4),
        side: BorderSide(
          color: (isLoading || onPressed == null)
              ? AppColors.primary.withValues(alpha: 0.4)
              : AppColors.primary,
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              width: 22.0,
              height: 22.0,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : Text(
              label,
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
    );
  }
}

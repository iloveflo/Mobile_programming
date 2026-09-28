import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Các mức độ bảo mật của mật khẩu
enum PasswordStrength {
  none(label: 'Chưa nhập', level: 0, color: AppColors.border),
  weak(label: 'Yếu', level: 1, color: AppColors.error),
  fair(label: 'Trung bình', level: 2, color: AppColors.warning),
  good(label: 'Tốt', level: 3, color: AppColors.primaryLight),
  strong(label: 'Rất mạnh', level: 4, color: AppColors.success);

  final String label;
  final int level;
  final Color color;

  const PasswordStrength({
    required this.label,
    required this.level,
    required this.color,
  });
}

/// Thước đo độ mạnh mật khẩu thời gian thực chuẩn FinCredit,
/// hiển thị qua 4 thanh trạng thái đổi màu và nhãn đánh giá tương ứng.
class PasswordStrengthMeter extends StatelessWidget {
  /// Chuỗi mật khẩu cần kiểm tra
  final String password;

  const PasswordStrengthMeter({super.key, required this.password});

  /// Tính toán mức độ mạnh mật khẩu dựa trên các tiêu chí bảo mật
  PasswordStrength _calculateStrength(String text) {
    if (text.isEmpty) return PasswordStrength.none;

    final bool hasMinLength = text.length >= 8;
    final bool hasUppercase = RegExp(r'[A-Z]').hasMatch(text);
    final bool hasLowercase = RegExp(r'[a-z]').hasMatch(text);
    final bool hasDigit = RegExp(r'[0-9]').hasMatch(text);
    final bool hasSpecialChar = RegExp(
      r'[!@#\$%^&*(),.?":{}|<>]',
    ).hasMatch(text);

    int score = 0;
    if (hasMinLength) score++;
    if (hasUppercase) score++;
    if (hasLowercase) score++;
    if (hasDigit) score++;
    if (hasSpecialChar) score++;

    // Mật khẩu chưa đủ 8 ký tự luôn xem là Yếu
    if (!hasMinLength) {
      return PasswordStrength.weak;
    }

    if (score <= 2) {
      return PasswordStrength.weak;
    } else if (score == 3) {
      return PasswordStrength.fair;
    } else if (score == 4) {
      return PasswordStrength.good;
    } else {
      return PasswordStrength.strong;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strength = _calculateStrength(password);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 4 thanh ngang chỉ báo
        Row(
          children: List.generate(4, (index) {
            final bool isActive = strength.level > index;
            final Color barColor = isActive ? strength.color : AppColors.border;

            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: EdgeInsets.only(right: index < 3 ? 6.0 : 0.0),
                height: 4.5,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(4.0),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6.0),
        // Dòng chữ mô tả trạng thái
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                strength == PasswordStrength.none
                    ? 'Gồm ít nhất 8 ký tự, chữ hoa, số & ký tự đặc biệt'
                    : 'Độ bảo mật: ${strength.label}',
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w500,
                  color: strength == PasswordStrength.none
                      ? AppColors.textSecondary
                      : strength.color,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

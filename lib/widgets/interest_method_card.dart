import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Phương thức tính lãi vay
enum InterestMethod {
  /// Dư nợ giảm dần (Amortized / Reducing balance)
  reducingBalance,

  /// Dư nợ ban đầu / Lãi suất phẳng (Flat rate)
  flatRate,
}

/// Thẻ lựa chọn phương thức tính lãi vay (InterestMethodCard)
/// Hỗ trợ hiển thị "Khuyên dùng" / "Tiết kiệm hơn" cho Dư nợ giảm dần
class InterestMethodCard extends StatelessWidget {
  final InterestMethod method;
  final InterestMethod selectedMethod;
  final ValueChanged<InterestMethod> onChanged;

  const InterestMethodCard({
    super.key,
    required this.method,
    required this.selectedMethod,
    required this.onChanged,
  });

  bool get isSelected => method == selectedMethod;

  @override
  Widget build(BuildContext context) {
    final isReducing = method == InterestMethod.reducingBalance;
    final title = isReducing ? 'Dư nợ giảm dần' : 'Dư nợ ban đầu (Phẳng)';
    final subtitle = isReducing
        ? 'Tiền lãi giảm dần theo số tiền gốc thực tế còn lại qua từng tháng.'
        : 'Tiền lãi cố định hàng tháng tính trên toàn bộ số tiền gốc ban đầu.';

    return InkWell(
      onTap: () => onChanged(method),
      borderRadius: BorderRadius.circular(14.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primarySoft.withValues(alpha: 0.4)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(
            color: isSelected ? AppColors.primaryLight : AppColors.border,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Custom Radio Icon
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Container(
                width: 20.0,
                height: 20.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryLight
                        : AppColors.textSecondary,
                    width: isSelected ? 6.0 : 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12.0),
            // Title & Description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (isReducing) ...[
                        const SizedBox(width: 8.0),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6.0,
                            vertical: 2.0,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: const Text(
                            'Khuyên dùng',
                            style: TextStyle(
                              fontSize: 10.0,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.0,
                      color: AppColors.textSecondary,
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

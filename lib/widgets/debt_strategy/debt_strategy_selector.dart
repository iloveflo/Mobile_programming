import 'package:flutter/material.dart';

import '../../models/debt_strategy_model.dart';
import '../common/app_colors.dart';

/// Bộ chọn chiến lược tối ưu và điều chỉnh ngân sách trả nợ thêm hàng tháng
class DebtStrategySelector extends StatelessWidget {
  final DebtStrategyType selectedType;
  final bool isComparing;
  final ValueChanged<DebtStrategyType> onTypeChanged;
  final VoidCallback onToggleCompare;
  final double extraPayment;
  final ValueChanged<double> onExtraPaymentChanged;

  const DebtStrategySelector({
    super.key,
    required this.selectedType,
    required this.isComparing,
    required this.onTypeChanged,
    required this.onToggleCompare,
    required this.extraPayment,
    required this.onExtraPaymentChanged,
  });

  String _formatCompactCurrency(double amount) {
    if (amount >= 1000000) {
      final millions = (amount / 1000000).toStringAsFixed(
        amount % 1000000 == 0 ? 0 : 1,
      );
      return '$millions triệu';
    }
    return '${amount.round()} đ';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LỰA CHỌN PHƯƠNG ÁN TỐI ƯU',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          // 3 Tabs: Avalanche, Snowball, So sánh
          Row(
            children: [
              Expanded(
                child: _buildStrategyTab(
                  title: 'Avalanche',
                  subtitle: 'Lãi cao trước',
                  isSelected:
                      !isComparing &&
                      selectedType == DebtStrategyType.avalanche,
                  icon: Icons.trending_down_rounded,
                  onTap: () {
                    if (isComparing) onToggleCompare();
                    onTypeChanged(DebtStrategyType.avalanche);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStrategyTab(
                  title: 'Snowball',
                  subtitle: 'Dư nợ nhỏ',
                  isSelected:
                      !isComparing && selectedType == DebtStrategyType.snowball,
                  icon: Icons.ac_unit_rounded,
                  onTap: () {
                    if (isComparing) onToggleCompare();
                    onTypeChanged(DebtStrategyType.snowball);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStrategyTab(
                  title: 'So sánh',
                  subtitle: 'Đối chiếu 2 bên',
                  isSelected: isComparing,
                  icon: Icons.compare_arrows_rounded,
                  onTap: onToggleCompare,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 14),
          // Extra Payment Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Số tiền trả thêm mỗi tháng',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Dồn vào khoản vay ưu tiên số 1',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+ ${_formatCompactCurrency(extraPayment)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primarySoft,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.15),
              trackHeight: 4,
            ),
            child: Slider(
              value: extraPayment.clamp(0.0, 10000000.0),
              min: 0,
              max: 10000000,
              divisions: 20,
              label: _formatCompactCurrency(extraPayment),
              onChanged: onExtraPaymentChanged,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildQuickChip(0, '0 đ'),
              _buildQuickChip(1000000, '1 triệu'),
              _buildQuickChip(2000000, '2 triệu'),
              _buildQuickChip(3000000, '3 triệu'),
              _buildQuickChip(5000000, '5 triệu'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStrategyTab({
    required String title,
    required String subtitle,
    required bool isSelected,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.white70 : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickChip(double amount, String label) {
    final bool isCurrent = (extraPayment - amount).abs() < 1000;
    return InkWell(
      onTap: () => onExtraPaymentChanged(amount),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isCurrent ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCurrent ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
            color: isCurrent ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

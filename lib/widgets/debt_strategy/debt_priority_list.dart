import 'package:flutter/material.dart';

import '../../models/debt_strategy_model.dart';
import '../common/app_colors.dart';

/// Danh sách thể hiện thứ tự ưu tiên xử lý các khoản nợ theo kế hoạch (Mục 7 & 8)
class DebtPriorityList extends StatelessWidget {
  final DebtStrategyPlanResult plan;

  const DebtPriorityList({super.key, required this.plan});

  String _formatCurrency(double amount) {
    final integerPart = amount.round().toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = integerPart.length - 1; i >= 0; i--) {
      buffer.write(integerPart[i]);
      count++;
      if (count % 3 == 0 && i > 0) {
        buffer.write('.');
      }
    }
    return '${buffer.toString().split('').reversed.join()} đ';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Các chỉ số kết quả đầu ra tổng hợp (Mục 7.2 Bước 7 & Mục 8.2 Bước 7)
        _buildMetricSummaryGrid(),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'THỨ TỰ ƯU TIÊN (${plan.items.length} KHOẢN VAY)',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              plan.strategyType == DebtStrategyType.avalanche
                  ? 'Ưu tiên Lãi suất cao trước'
                  : 'Ưu tiên Dư nợ nhỏ trước',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: plan.items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = plan.items[index];
            return _buildPriorityItemCard(item);
          },
        ),
      ],
    );
  }

  Widget _buildMetricSummaryGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Tổng lãi dự kiến',
                  value: _formatCurrency(plan.totalInterest),
                  icon: Icons.payments_outlined,
                  color: AppColors.primary,
                ),
              ),
              Container(width: 1, height: 44, color: AppColors.border),
              Expanded(
                child: _buildMetricTile(
                  label: 'Thời gian tất toán',
                  value: '${plan.totalMonths} tháng',
                  icon: Icons.calendar_month_outlined,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Tiết kiệm tiền lãi',
                  value: plan.interestSaved > 0
                      ? '- ${_formatCurrency(plan.interestSaved)}'
                      : '0 đ',
                  icon: Icons.savings_outlined,
                  color: AppColors.success,
                  isHighlight: true,
                ),
              ),
              Container(width: 1, height: 44, color: AppColors.border),
              Expanded(
                child: _buildMetricTile(
                  label: 'Rút ngắn thời gian',
                  value: plan.monthsSaved > 0
                      ? '${plan.monthsSaved} tháng'
                      : '0 tháng',
                  icon: Icons.speed_rounded,
                  color: AppColors.success,
                  isHighlight: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w700,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityItemCard(DebtPlanItem item) {
    final isTopPriority = item.priorityOrder == 1;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isTopPriority ? const Color(0xFFF0F7FF) : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isTopPriority ? AppColors.primaryLight : AppColors.border,
          width: isTopPriority ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isTopPriority
                      ? AppColors.primary
                      : AppColors.textSecondary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${item.priorityOrder}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isTopPriority ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.loan.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      item.loan.lender ?? 'Ngân hàng / TCTD',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isTopPriority)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'TRẢ TẬP TRUNG',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildItemSubDetail(
                'Dư nợ hiện tại',
                _formatCurrency(item.currentBalance),
              ),
              _buildItemSubDetail(
                'Lãi suất',
                '${(item.interestRate * 100).toStringAsFixed(1)}%/năm',
                isHighlighted: true,
              ),
              _buildItemSubDetail(
                'Tất toán trong',
                '~${item.estimatedMonthsToPayoff} tháng',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemSubDetail(
    String label,
    String value, {
    bool isHighlighted = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w600,
            color: isHighlighted ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

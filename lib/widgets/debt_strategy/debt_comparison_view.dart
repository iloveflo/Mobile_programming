import 'package:flutter/material.dart';

import '../../models/debt_strategy_model.dart';
import '../common/app_colors.dart';

/// Chế độ xem Đối sánh Toàn diện giữa Snowball và Avalanche (Mục 9)
class DebtComparisonView extends StatelessWidget {
  final DebtStrategyPlanResult snowballPlan;
  final DebtStrategyPlanResult avalanchePlan;
  final ValueChanged<DebtStrategyType> onSelectAndApply;

  const DebtComparisonView({
    super.key,
    required this.snowballPlan,
    required this.avalanchePlan,
    required this.onSelectAndApply,
  });

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
    final interestDiff =
        (snowballPlan.totalInterest - avalanchePlan.totalInterest).abs();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Khuyến nghị tài chính thông minh
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7), // warm amber tint
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.lightbulb_rounded,
                color: AppColors.warning,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Góc nhìn tài chính FinCredit',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF92400E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• Avalanche tiết kiệm nhiều hơn ${_formatCurrency(interestDiff)} tiền lãi.\n'
                      '• Snowball giúp dứt điểm khoản nợ đầu tiên nhanh hơn, tạo động lực tâm lý.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF78350F),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 9.3: Bảng đối sánh dữ liệu tổng hợp
        const Text(
          'BẢNG ĐỐI CHIẾU CHỈ SỐ TÀI CHÍNH',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        _buildComparisonTable(),

        const SizedBox(height: 20),

        // 9.4: Biểu đồ thanh so sánh trực quan
        const Text(
          'SO SÁNH TRỰC QUAN (MỤC 9.4)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        _buildVisualBarCharts(),

        const SizedBox(height: 20),

        // So sánh thứ tự ưu tiên
        const Text(
          'SO SÁNH THỨ TỰ ƯU TIÊN XỬ LÝ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        _buildSideBySidePriorities(),
      ],
    );
  }

  Widget _buildComparisonTable() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Header Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Tiêu chí so sánh',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Snowball ❄️',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Avalanche ⚡',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          _buildTableRow(
            'Tiêu chí ưu tiên',
            'Dư nợ nhỏ trước',
            'Lãi suất cao trước',
          ),
          _buildTableRow(
            'Tổng lãi dự kiến',
            _formatCurrency(snowballPlan.totalInterest),
            _formatCurrency(avalanchePlan.totalInterest),
            highlightSecond: true,
          ),
          _buildTableRow(
            'Thời gian tất toán',
            '${snowballPlan.totalMonths} tháng',
            '${avalanchePlan.totalMonths} tháng',
          ),
          _buildTableRow(
            'Tổng chi phí dự kiến',
            _formatCurrency(snowballPlan.totalCost),
            _formatCurrency(avalanchePlan.totalCost),
            highlightSecond: true,
          ),
          _buildTableRow(
            'Tiết kiệm tiền lãi',
            _formatCurrency(snowballPlan.interestSaved),
            _formatCurrency(avalanchePlan.interestSaved),
            isSuccess: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(
    String criterion,
    String col1,
    String col2, {
    bool highlightSecond = false,
    bool isSuccess = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.6)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              criterion,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              col1,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSuccess ? AppColors.success : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              col2,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isSuccess
                    ? AppColors.success
                    : (highlightSecond
                          ? AppColors.primary
                          : AppColors.textPrimary),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualBarCharts() {
    final maxInterest = snowballPlan.totalInterest > avalanchePlan.totalInterest
        ? snowballPlan.totalInterest
        : avalanchePlan.totalInterest;
    final maxMonths = snowballPlan.totalMonths > avalanchePlan.totalMonths
        ? snowballPlan.totalMonths
        : avalanchePlan.totalMonths;

    final snowballInterestRatio = maxInterest > 0
        ? (snowballPlan.totalInterest / maxInterest)
        : 1.0;
    final avalancheInterestRatio = maxInterest > 0
        ? (avalanchePlan.totalInterest / maxInterest)
        : 0.85;

    final snowballMonthsRatio = maxMonths > 0
        ? (snowballPlan.totalMonths / maxMonths)
        : 1.0;
    final avalancheMonthsRatio = maxMonths > 0
        ? (avalanchePlan.totalMonths / maxMonths)
        : 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tổng tiền lãi phải trả',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _buildBarItem(
            'Snowball',
            snowballInterestRatio,
            _formatCurrency(snowballPlan.totalInterest),
            const Color(0xFF60A5FA),
          ),
          const SizedBox(height: 6),
          _buildBarItem(
            'Avalanche',
            avalancheInterestRatio,
            _formatCurrency(avalanchePlan.totalInterest),
            AppColors.primary,
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 14),
          const Text(
            'Thời gian hoàn thành tất toán',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _buildBarItem(
            'Snowball',
            snowballMonthsRatio,
            '${snowballPlan.totalMonths} tháng',
            const Color(0xFF60A5FA),
          ),
          const SizedBox(height: 6),
          _buildBarItem(
            'Avalanche',
            avalancheMonthsRatio,
            '${avalanchePlan.totalMonths} tháng',
            AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildBarItem(
    String label,
    double ratio,
    String valueLabel,
    Color barColor,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              FractionallySizedBox(
                widthFactor: ratio.clamp(0.05, 1.0),
                child: Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 90,
          child: Text(
            valueLabel,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildSideBySidePriorities() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildPriorityColumn(
            title: 'Snowball ❄️',
            items: snowballPlan.items,
            onSelect: () => onSelectAndApply(DebtStrategyType.snowball),
            buttonLabel: 'Chọn Snowball',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildPriorityColumn(
            title: 'Avalanche ⚡',
            items: avalanchePlan.items,
            onSelect: () => onSelectAndApply(DebtStrategyType.avalanche),
            buttonLabel: 'Chọn Avalanche',
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityColumn({
    required String title,
    required List<DebtPlanItem> items,
    required VoidCallback onSelect,
    required String buttonLabel,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          ...items.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final item = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: index == 1
                    ? AppColors.primarySoft
                    : AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    '#$index',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.loan.name,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSelect,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                buttonLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

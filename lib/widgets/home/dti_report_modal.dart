import 'package:flutter/material.dart';

import '../../controllers/loan_controller.dart';
import '../../models/user_model.dart';
import '../../routes/app_router.dart';
import '../widget.dart';

/// Modal BottomSheet Báo cáo tỷ lệ gánh nặng nợ DTI (Debt-to-Income)
class DtiReportModal extends StatelessWidget {
  final UserModel? user;
  final LoanController loanController;

  const DtiReportModal({
    super.key,
    required this.user,
    required this.loanController,
  });

  /// Phương thức hiển thị modal
  static Future<void> show(
    BuildContext context, {
    required UserModel? user,
    required LoanController loanController,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (ctx) =>
          DtiReportModal(user: user, loanController: loanController),
    );
  }

  String _formatCurrency(num amount) {
    final str = amount.round().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return '${buffer.toString()} đ';
  }

  Widget _buildSimulationRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13.0,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdviceBullet(String title, String desc, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontSize: 13.0,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 11.5,
                  color: color.withValues(alpha: 0.95),
                  height: 1.35,
                ),
                children: [
                  TextSpan(
                    text: '$title ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: desc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double income = user?.monthlyIncome ?? 0.0;
    final double commitment = loanController.totalMonthlyCommitment;
    final double dtiRatio = income > 0 ? (commitment / income) * 100 : 0.0;
    final double netCashFlow = income - commitment;
    final activeLoans = loanController.loans.where((l) => l.isActive).toList();

    final String tierTitle;
    final String tierSubtitle;
    final Color themeColor;
    final Color badgeBg;
    final IconData tierIcon;

    if (income <= 0 && commitment <= 0) {
      tierTitle = 'CHƯA GHI NHẬN NỢ & THU NHẬP';
      tierSubtitle =
          'Bạn hiện chưa có khoản nợ nào và chưa thiết lập thu nhập hàng tháng';
      themeColor = const Color(0xFF16A34A);
      badgeBg = const Color(0xFFDCFCE7);
      tierIcon = Icons.verified_user_rounded;
    } else if (income <= 0 && commitment > 0) {
      tierTitle = 'CHƯA CẬP NHẬT THU NHẬP';
      tierSubtitle =
          'Vui lòng cập nhật thu nhập hàng tháng để hệ thống tính toán chính xác tỷ lệ DTI';
      themeColor = const Color(0xFFD97706);
      badgeBg = const Color(0xFFFEF3C7);
      tierIcon = Icons.warning_amber_rounded;
    } else if (dtiRatio <= 30) {
      tierTitle = 'VÙNG AN TOÀN TUYỆT ĐỐI';
      tierSubtitle =
          'Gánh nặng nợ ở mức thấp, khả năng hấp thụ và chịu tải tài chính tối ưu';
      themeColor = const Color(0xFF16A34A);
      badgeBg = const Color(0xFFDCFCE7);
      tierIcon = Icons.verified_user_rounded;
    } else if (dtiRatio <= 40) {
      tierTitle = 'VÙNG TIÊU CHUẨN AN TOÀN';
      tierSubtitle =
          'DTI nằm trong ngưỡng vàng của các ngân hàng thương mại (dưới 40%)';
      themeColor = const Color(0xFF0891B2);
      badgeBg = const Color(0xFFCFFAFE);
      tierIcon = Icons.health_and_safety_rounded;
    } else if (dtiRatio <= 50) {
      tierTitle = 'VÙNG CẢNH BÁO ÁP LỰC';
      tierSubtitle =
          'Nghĩa vụ trả nợ tiệm cận 50% thu nhập, cần kiểm soát chi tiêu chặt chẽ';
      themeColor = const Color(0xFFD97706);
      badgeBg = const Color(0xFFFEF3C7);
      tierIcon = Icons.warning_amber_rounded;
    } else {
      tierTitle = 'VÙNG RỦI RO CAO • BÁO ĐỘNG ĐỎ';
      tierSubtitle =
          'Nghĩa vụ trả nợ vượt quá mức an toàn, nguy cơ thâm hụt và mất thanh khoản';
      themeColor = const Color(0xFFDC2626);
      badgeBg = const Color(0xFFFEE2E2);
      tierIcon = Icons.dangerous_rounded;
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.0,
                height: 4.0,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            ),
            const SizedBox(height: 16.0),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Icon(
                    Icons.pie_chart_outline_rounded,
                    color: themeColor,
                    size: 22.0,
                  ),
                ),
                const SizedBox(width: 10.0),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Báo cáo Tỷ lệ Gánh nặng Nợ (DTI)',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2.0),
                      Text(
                        'Debt-to-Income Ratio • Tiêu chuẩn thẩm định tín dụng',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16.0),

            // Hero Card: Chỉ số DTI & Đánh giá rủi ro
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: themeColor.withValues(alpha: 0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(tierIcon, size: 18.0, color: themeColor),
                          const SizedBox(width: 6.0),
                          Text(
                            tierTitle,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: themeColor,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Tiêu chuẩn: < 40%',
                        style: TextStyle(
                          fontSize: 11.0,
                          color: themeColor.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10.0),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${dtiRatio.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 34.0,
                          fontWeight: FontWeight.w900,
                          color: themeColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 10.0),
                      Expanded(
                        child: Text(
                          tierSubtitle,
                          style: TextStyle(
                            fontSize: 12.0,
                            color: themeColor.withValues(alpha: 0.85),
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14.0),

                  // Thước đo 4 phân tầng
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 30,
                          child: Container(
                            height: 8.0,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                        const SizedBox(width: 2.0),
                        Expanded(
                          flex: 10,
                          child: Container(
                            height: 8.0,
                            color: const Color(0xFF0891B2),
                          ),
                        ),
                        const SizedBox(width: 2.0),
                        Expanded(
                          flex: 10,
                          child: Container(
                            height: 8.0,
                            color: const Color(0xFFD97706),
                          ),
                        ),
                        const SizedBox(width: 2.0),
                        Expanded(
                          flex: 50,
                          child: Container(
                            height: 8.0,
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '0% (Tối ưu)',
                        style: TextStyle(
                          fontSize: 10.0,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                      Text(
                        '40% (Ngưỡng)',
                        style: TextStyle(
                          fontSize: 10.0,
                          color: Color(0xFF0891B2),
                        ),
                      ),
                      Text(
                        '50% (Cảnh báo)',
                        style: TextStyle(
                          fontSize: 10.0,
                          color: Color(0xFFD97706),
                        ),
                      ),
                      Text(
                        '100%+ (Rất rủi ro)',
                        style: TextStyle(
                          fontSize: 10.0,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),

            // Bảng Cân đối Thu chi & Dòng tiền ròng
            const Text(
              'Cân đối Thu nhập & Nghĩa vụ Hàng tháng',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10.0),
            Container(
              padding: const EdgeInsets.all(14.0),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14.0),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildSimulationRow(
                    'Thu nhập xác nhận:',
                    income > 0
                        ? _formatCurrency(income)
                        : 'Chưa cập nhật (0 đ)',
                    AppColors.primary,
                  ),
                  const Divider(height: 14.0),
                  _buildSimulationRow(
                    'Tổng nghĩa vụ trả nợ/tháng:',
                    _formatCurrency(commitment),
                    dtiRatio > 50
                        ? const Color(0xFFDC2626)
                        : AppColors.textPrimary,
                  ),
                  const Divider(height: 14.0),
                  _buildSimulationRow(
                    netCashFlow >= 0
                        ? 'Dòng tiền thặng dư tự do:'
                        : 'Dòng tiền thâm hụt hàng tháng:',
                    (netCashFlow >= 0 ? '+ ' : '- ') +
                        _formatCurrency(netCashFlow.abs()),
                    netCashFlow >= 0
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18.0),

            // Bóc tách cơ cấu nợ theo từng hợp đồng
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Cơ cấu Nợ đóng góp vào DTI',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${activeLoans.length} khoản vay',
                  style: const TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10.0),
            if (activeLoans.isEmpty)
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: const Center(
                  child: Text(
                    'Không có khoản vay nào đang hoạt động.',
                    style: TextStyle(
                      fontSize: 13.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              )
            else
              ...activeLoans.map((loan) {
                final monthlyEst = loan.monthlyInstallmentEstimate;
                final sharePercent = income > 0
                    ? (monthlyEst / income) * 100
                    : 0.0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36.0,
                        height: 36.0,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Icon(
                          loan.isCreditCard
                              ? Icons.credit_card_rounded
                              : Icons.account_balance_rounded,
                          size: 18.0,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loan.loanName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.0,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2.0),
                            Text(
                              '${loan.lender ?? "FinCredit"} • ${loan.loanTypeDisplayName}',
                              style: const TextStyle(
                                fontSize: 11.0,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatCurrency(monthlyEst),
                            style: const TextStyle(
                              fontSize: 13.0,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            '${sharePercent.toStringAsFixed(1)}% thu nhập',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: sharePercent > 40
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 16.0),

            // Khuyến nghị chuyên gia FinCredit
            Container(
              padding: const EdgeInsets.all(14.0),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(14.0),
                border: Border.all(color: themeColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_rounded,
                        size: 18.0,
                        color: themeColor,
                      ),
                      const SizedBox(width: 6.0),
                      Text(
                        'Khuyến nghị Chiến lược FinCredit',
                        style: TextStyle(
                          fontSize: 13.0,
                          fontWeight: FontWeight.bold,
                          color: themeColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  if (income <= 0 && commitment <= 0) ...[
                    Text(
                      'Bạn chưa có khoản nợ nào và chưa cập nhật thu nhập hàng tháng. Hồ sơ tài chính của bạn đang ở trạng thái an toàn, không có áp lực chi trả nợ.',
                      style: TextStyle(
                        fontSize: 12.0,
                        color: themeColor,
                        height: 1.4,
                      ),
                    ),
                  ] else if (income <= 0 && commitment > 0) ...[
                    Text(
                      'Bạn đang có nghĩa vụ trả nợ ${_formatCurrency(commitment)}/tháng nhưng chưa cập nhật thu nhập. Vui lòng cập nhật thu nhập tại mục Hồ sơ cá nhân để nhận đánh giá tỷ lệ DTI chính xác.',
                      style: TextStyle(
                        fontSize: 12.0,
                        color: themeColor,
                        height: 1.4,
                      ),
                    ),
                  ] else if (dtiRatio > 50) ...[
                    Text(
                      'Tỷ lệ DTI của bạn đang ở mức rất cao (${dtiRatio.toStringAsFixed(1)}%). Tổng nghĩa vụ trả nợ hàng tháng (${_formatCurrency(commitment)}) đã vượt qua thu nhập xác nhận (${_formatCurrency(income)}), dẫn đến thâm hụt tài chính nghiêm trọng.',
                      style: TextStyle(
                        fontSize: 12.0,
                        color: themeColor,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    _buildAdviceBullet(
                      '1. Tái cơ cấu kỳ hạn vay:',
                      'Thương lượng kéo dài kỳ hạn của các khoản vay lớn (ví dụ Vay mua căn hộ) để giảm áp lực trả nợ mỗi tháng.',
                      themeColor,
                    ),
                    _buildAdviceBullet(
                      '2. Áp dụng phương pháp Avalanche:',
                      'Tập trung trả dứt điểm các khoản nợ có lãi suất cao nhất (như thẻ tín dụng 24%/năm) trước để cắt giảm dòng tiền trả lãi.',
                      themeColor,
                    ),
                    _buildAdviceBullet(
                      '3. Đóng băng các khoản nợ mới:',
                      'Tuyệt đối không sử dụng thêm thẻ tín dụng hoặc mở thêm hạn mức tín dụng mới cho đến khi DTI giảm về dưới 40%.',
                      themeColor,
                    ),
                  ] else if (dtiRatio > 40) ...[
                    Text(
                      'Tỷ lệ DTI của bạn (${dtiRatio.toStringAsFixed(1)}%) đang tiệm cận mức rủi ro (vượt ngưỡng tiêu chuẩn 40%). Cần chủ động cắt giảm chi tiêu không thiết yếu và tăng tốc tất toán các khoản nợ nhỏ.',
                      style: TextStyle(
                        fontSize: 12.0,
                        color: themeColor,
                        height: 1.4,
                      ),
                    ),
                  ] else ...[
                    Text(
                      'Tỷ lệ DTI của bạn (${dtiRatio.toStringAsFixed(1)}%) nằm dưới ngưỡng 40%. Đây là mức tài chính an toàn cao, tạo điều kiện thuận lợi khi thẩm định hồ sơ giải ngân mới và duy trì điểm CIC cao.',
                      style: TextStyle(
                        fontSize: 12.0,
                        color: themeColor,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20.0),

            // 2 Nút CTA chiến lược
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRouter.simulation);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      side: BorderSide(color: themeColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    child: Text(
                      'Mô phỏng cơ cấu nợ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: themeColor,
                        fontSize: 13.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRouter.debtStrategy);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    child: const Text(
                      'Tối ưu chiến lược nợ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
          ],
        ),
      ),
    );
  }
}

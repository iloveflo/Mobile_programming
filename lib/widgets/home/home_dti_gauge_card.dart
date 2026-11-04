import 'package:flutter/material.dart';

import '../../controllers/loan_controller.dart';
import '../../models/user_model.dart';
import '../widget.dart';

/// Thẻ hiển thị chỉ số gánh nặng nợ DTI (Debt-to-Income) trên trang chủ
class HomeDtiGaugeCard extends StatelessWidget {
  final UserModel? user;
  final LoanController loanController;
  final VoidCallback onTap;

  const HomeDtiGaugeCard({
    super.key,
    required this.user,
    required this.loanController,
    required this.onTap,
  });

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

  @override
  Widget build(BuildContext context) {
    final double income = user?.monthlyIncome ?? 0.0;
    final double commitment = loanController.totalMonthlyCommitment;
    final double dtiPercent = income > 0 ? (commitment / income) * 100 : 0.0;

    final String statusLabel;
    final Color statusColor;
    final Color statusBg;
    final String analysisText;

    if (income <= 0 && commitment <= 0) {
      statusLabel = '0.0% • AN TOÀN';
      statusColor = const Color(0xFF16A34A);
      statusBg = const Color(0xFFDCFCE7);
      analysisText =
          'Phân tích FinCredit: Bạn chưa có khoản nợ nào. Hãy cập nhật thu nhập hàng tháng để hệ thống phân tích sức khỏe tài chính toàn diện.';
    } else if (income <= 0 && commitment > 0) {
      statusLabel = 'CHƯA CẬP NHẬT THU NHẬP';
      statusColor = const Color(0xFFD97706);
      statusBg = const Color(0xFFFEF3C7);
      analysisText =
          'Phân tích FinCredit: Nghĩa vụ trả nợ hiện tại là ${_formatCurrency(commitment)}/tháng nhưng chưa ghi nhận thu nhập để tính tỷ lệ DTI.';
    } else if (dtiPercent <= 30) {
      statusLabel = '${dtiPercent.toStringAsFixed(1)}% • AN TOÀN CAO';
      statusColor = const Color(0xFF16A34A);
      statusBg = const Color(0xFFDCFCE7);
      analysisText =
          'Phân tích FinCredit: DTI ở mức rất thấp (${dtiPercent.toStringAsFixed(1)}%). Dòng tiền tự do dồi dào, hồ sơ tín dụng xuất sắc.';
    } else if (dtiPercent <= 40) {
      statusLabel = '${dtiPercent.toStringAsFixed(1)}% • TIÊU CHUẨN';
      statusColor = const Color(0xFF0891B2);
      statusBg = const Color(0xFFCFFAFE);
      analysisText =
          'Phân tích FinCredit: Thu nhập hàng tháng đủ khả năng chi trả các nghĩa vụ tài chính trong ngưỡng an toàn chuẩn mực (< 40%).';
    } else if (dtiPercent <= 50) {
      statusLabel = '${dtiPercent.toStringAsFixed(1)}% • CẢNH BÁO';
      statusColor = const Color(0xFFD97706);
      statusBg = const Color(0xFFFEF3C7);
      analysisText =
          'Phân tích FinCredit: Nghĩa vụ trả nợ chiếm ${dtiPercent.toStringAsFixed(1)}% thu nhập. Nên kiểm soát chi tiêu và tránh mở thêm khoản vay mới.';
    } else {
      statusLabel = '${dtiPercent.toStringAsFixed(1)}% • RỦI RO CAO';
      statusColor = const Color(0xFFDC2626);
      statusBg = const Color(0xFFFEE2E2);
      analysisText =
          'Phân tích FinCredit: Cảnh báo áp lực trả nợ nặng (${dtiPercent.toStringAsFixed(1)}% thu nhập). Cần lên kế hoạch tái cơ cấu hoặc dùng chiến lược tối ưu nợ ngay.';
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x060F172A),
              blurRadius: 10.0,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Text(
                      'Chỉ số gánh nặng nợ (DTI)',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(width: 4.0),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18.0,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 3.0,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11.0,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),

            // Thước đo phân tầng 4 dải màu
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
                  '0% (An toàn)',
                  style: TextStyle(fontSize: 10.0, color: Color(0xFF16A34A)),
                ),
                Text(
                  '40% (Ngưỡng)',
                  style: TextStyle(fontSize: 10.0, color: Color(0xFF0891B2)),
                ),
                Text(
                  '100% (Rủi ro)',
                  style: TextStyle(fontSize: 10.0, color: Color(0xFFDC2626)),
                ),
              ],
            ),
            const SizedBox(height: 10.0),
            Text(
              analysisText,
              style: const TextStyle(
                fontSize: 12.0,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

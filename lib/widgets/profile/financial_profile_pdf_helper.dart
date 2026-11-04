import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../models/user_model.dart';
import '../widget.dart';

/// Tiện ích hỗ trợ xuất và hiển thị hồ sơ năng lực tài chính dưới dạng PDF
abstract final class FinancialProfilePdfHelper {
  FinancialProfilePdfHelper._();

  /// Kích hoạt tiến trình xuất PDF hồ sơ năng lực tài chính và mở modal xem tài liệu
  static Future<void> export(
    BuildContext context, {
    required AuthController authController,
    UserModel? user,
  }) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(strokeWidth: 3.0),
                SizedBox(width: 16.0),
                Text(
                  'Đang xuất bản PDF hồ sơ...',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final pdfUrl = await authController.exportFinancialProfilePdf();

    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    if (pdfUrl != null && pdfUrl.isNotEmpty) {
      AppDocumentViewerModal.show(
        context,
        title: 'Hồ sơ năng lực tài chính (FinCredit)',
        fileKey: 'reports/fincredit_financial_report_${user?.userId ?? 1}.pdf',
        isPrivate: false,
      );
      AppSnackBar.showSuccess(
        context,
        'Đã xuất bản tóm tắt hồ sơ năng lực tài chính thành công!',
      );
    } else {
      AppSnackBar.showError(
        context,
        authController.errorMessage ??
            'Không thể xuất bản tóm tắt hồ sơ tài chính. Vui lòng thử lại sau.',
      );
    }
  }
}

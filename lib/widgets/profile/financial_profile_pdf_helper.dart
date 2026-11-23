import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../controllers/auth_controller.dart';
import '../../models/user_model.dart';
import '../widget.dart';

/// Tiện ích hỗ trợ xuất trực tiếp hồ sơ năng lực tài chính dạng PDF vào thiết bị người dùng
abstract final class FinancialProfilePdfHelper {
  FinancialProfilePdfHelper._();

  static const MethodChannel _launcherChannel = MethodChannel(
    'fincredit/launcher',
  );

  /// Tải biên bản PDF hồ sơ năng lực tài chính và lưu thẳng vào thư mục Downloads của thiết bị
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
                  'Đang xuất biên bản PDF hồ sơ...',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final bytes = await authController.downloadFinancialProfilePdfBytes();

    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    if (bytes != null && bytes.isNotEmpty) {
      final fileName =
          'HoSoNangLuc_FinCredit_${user?.userId ?? 1}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      try {
        final savedPath = await _launcherChannel.invokeMethod<String>(
          'saveAndOpenPdf',
          {'bytes': Uint8List.fromList(bytes), 'fileName': fileName},
        );
        if (!context.mounted) return;
        AppSnackBar.showSuccess(
          context,
          'Đã xuất báo cáo vào thiết bị: ${savedPath ?? fileName}',
        );
      } catch (e) {
        if (!context.mounted) return;
        AppSnackBar.showError(
          context,
          'Không thể lưu tệp PDF vào thiết bị: ${e.toString()}',
        );
      }
    } else {
      AppSnackBar.showError(
        context,
        authController.errorMessage ??
            'Không thể xuất báo cáo hồ sơ tài chính. Vui lòng thử lại sau.',
      );
    }
  }
}

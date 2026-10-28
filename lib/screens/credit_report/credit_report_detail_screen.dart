import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/credit_report_controller.dart';
import '../../service_locator.dart';
import '../../widgets/widget.dart';

/// Màn hình Chi tiết Báo cáo Tín dụng Định kỳ (Luồng 3)
class CreditReportDetailScreen extends StatefulWidget {
  final int? reportId;

  const CreditReportDetailScreen({super.key, this.reportId});

  @override
  State<CreditReportDetailScreen> createState() =>
      _CreditReportDetailScreenState();
}

class _CreditReportDetailScreenState extends State<CreditReportDetailScreen> {
  late final CreditReportController _controller;
  late final AuthController _authController;
  int? _resolvedReportId;

  @override
  void initState() {
    super.initState();
    _controller = sl<CreditReportController>();
    _authController = sl<AuthController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initReport();
    });
  }

  void _initReport() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (widget.reportId != null) {
      _resolvedReportId = widget.reportId;
    } else if (args is Map<String, dynamic> && args['reportId'] is int) {
      _resolvedReportId = args['reportId'] as int;
    }

    if (_resolvedReportId != null) {
      _controller.selectReport(
        _resolvedReportId!,
        userId: _authController.currentUser?.userId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chi tiết báo cáo tín dụng',
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          // EX-02: Không tìm thấy bản ghi báo cáo
          if (_controller.exceptionCode == 'EX-02' ||
              (_controller.selectedReport == null &&
                  _controller.errorMessage != null)) {
            return _buildErrorState(
              icon: Icons.search_off_rounded,
              iconColor: AppColors.warning,
              title: 'Không tìm thấy báo cáo',
              message:
                  _controller.errorMessage ??
                  'Bản ghi báo cáo tín dụng yêu cầu không tồn tại hoặc đã bị xóa.',
              actionLabel: 'Quay lại danh sách',
              onAction: () => Navigator.pop(context),
            );
          }

          // EX-03: Báo cáo không thuộc người dùng (403 Forbidden)
          if (_controller.exceptionCode == 'EX-03') {
            return _buildErrorState(
              icon: Icons.gpp_bad_rounded,
              iconColor: AppColors.error,
              title: 'Không có quyền truy cập',
              message:
                  _controller.errorMessage ??
                  'Bạn không có quyền truy cập vào bản ghi báo cáo tín dụng của tài khoản khác.',
              actionLabel: 'Quay lại',
              onAction: () => Navigator.pop(context),
            );
          }

          final report = _controller.selectedReport;
          if (report == null) {
            return _buildErrorState(
              icon: Icons.info_outline_rounded,
              iconColor: AppColors.textSecondary,
              title: 'Chưa chọn báo cáo',
              message:
                  'Vui lòng chọn một kỳ báo cáo từ danh sách để xem chi tiết.',
              actionLabel: 'Về danh sách',
              onAction: () => Navigator.pop(context),
            );
          }

          return CreditReportDetailView(report: report);
        },
      ),
    );
  }

  Widget _buildErrorState({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 54.0, color: iconColor),
            const SizedBox(height: 16.0),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17.0,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8.0),
            Text(
              message,
              style: const TextStyle(
                fontSize: 13.0,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

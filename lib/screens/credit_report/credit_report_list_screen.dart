import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/credit_report_controller.dart';
import '../../routes/app_router.dart';
import '../../service_locator.dart';
import '../../widgets/widget.dart';

/// Màn hình Danh sách Báo cáo Tín dụng Định kỳ (Luồng 2 & Luồng 4)
class CreditReportListScreen extends StatefulWidget {
  const CreditReportListScreen({super.key});

  @override
  State<CreditReportListScreen> createState() => _CreditReportListScreenState();
}

class _CreditReportListScreenState extends State<CreditReportListScreen> {
  late final CreditReportController _controller;
  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    _controller = sl<CreditReportController>();
    _authController = sl<AuthController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.loadReports(userId: _authController.currentUser?.userId);
    });
  }

  void _handleGenerateReport() {
    final existingPeriods = _controller.reports
        .map((r) => r.reportPeriod)
        .whereType<String>()
        .toList();

    GenerateReportDialog.show(
      context,
      existingPeriods: existingPeriods,
      onConfirm: (period) async {
        final success = await _controller.generateNewReport(
          userId: _authController.currentUser?.userId,
          reportPeriod: period,
        );

        if (!mounted) return false;

        if (success) {
          AppSnackBar.showSuccess(
            context,
            'Ảnh chụp báo cáo kỳ $period đã được khởi tạo thành công!',
          );
          if (_controller.selectedReport != null) {
            Navigator.pushNamed(
              context,
              AppRouter.creditReportDetail,
              arguments: {'reportId': _controller.selectedReport!.id},
            );
          }
          return true;
        } else {
          AppSnackBar.showError(
            context,
            _controller.errorMessage ?? 'Không thể khởi tạo báo cáo kỳ này.',
          );
          return false;
        }
      },
    );
  }

  void _navigateToDetail(int reportId) {
    Navigator.pushNamed(
      context,
      AppRouter.creditReportDetail,
      arguments: {'reportId': reportId},
    );
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
          'Báo cáo tín dụng định kỳ',
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_chart_rounded, color: AppColors.primary),
            tooltip: 'Lập báo cáo mới',
            onPressed: _handleGenerateReport,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading && _controller.reports.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          // EX-03: Lỗi phân quyền truy cập
          if (_controller.exceptionCode == 'EX-03') {
            return _buildErrorState(
              icon: Icons.gpp_bad_rounded,
              iconColor: AppColors.error,
              title: 'Không có quyền truy cập',
              message:
                  _controller.errorMessage ??
                  'Bạn không có quyền truy xuất danh sách báo cáo tín dụng này.',
              actionLabel: 'Thử lại',
              onAction: () => _controller.loadReports(
                userId: _authController.currentUser?.userId,
              ),
            );
          }

          // EX-05: Lỗi sự cố kết nối hoặc cơ sở dữ liệu
          if (_controller.exceptionCode == 'EX-05' &&
              _controller.reports.isEmpty) {
            return _buildErrorState(
              icon: Icons.cloud_off_rounded,
              iconColor: AppColors.error,
              title: 'Sự cố kết nối hệ thống',
              message:
                  _controller.errorMessage ??
                  'Hệ thống gặp sự cố khi tải danh sách báo cáo. Vui lòng thử lại.',
              actionLabel: 'Thử lại ngay',
              onAction: () => _controller.loadReports(
                userId: _authController.currentUser?.userId,
              ),
            );
          }

          // EX-01: Chưa có báo cáo nào
          if (_controller.isEmptyState) {
            return RefreshIndicator(
              onRefresh: () => _controller.loadReports(
                userId: _authController.currentUser?.userId,
              ),
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: CreditReportEmptyState(
                    onGenerateFirstReport: _handleGenerateReport,
                  ),
                ),
              ),
            );
          }

          final reports = _controller.reports;
          final trendReports = _controller.trendReports;

          return RefreshIndicator(
            onRefresh: () => _controller.loadReports(
              userId: _authController.currentUser?.userId,
            ),
            color: AppColors.primary,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 14.0,
              ),
              children: [
                // 1. Thẻ Xu hướng tín dụng qua các kỳ (Luồng 4)
                CreditReportTrendCard(trendReports: trendReports),
                const SizedBox(height: 20.0),

                // 2. Tiêu đề danh sách các kỳ báo cáo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'LỊCH SỬ CÁC KỲ BÁO CÁO ĐÃ LẬP',
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '${reports.length} bản ghi',
                      style: const TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),

                // 3. Danh sách các thẻ báo cáo tín dụng (Luồng 2)
                ...reports.map(
                  (report) => CreditReportCard(
                    report: report,
                    onTap: () => _navigateToDetail(report.id),
                  ),
                ),
                const SizedBox(height: 30.0),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          child: ElevatedButton.icon(
            onPressed: _handleGenerateReport,
            icon: const Icon(Icons.add_rounded, size: 20.0),
            label: const Text(
              'Lập báo cáo kỳ mới',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              elevation: 0,
            ),
          ),
        ),
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

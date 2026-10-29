import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/credit_profile_controller.dart';
import '../../routes/app_router.dart';
import '../../service_locator.dart';
import '../../widgets/widget.dart';
import '../main_shell_screen.dart';

/// Màn hình Sức khỏe tín dụng FinCredit (CreditHealthScreen)
/// Tuân thủ quy tắc bảo toàn kiến trúc: Không tự ý tính toán chỉ số nghiệp vụ phía Mobile;
/// Toàn bộ chỉ số được truy vấn và hiển thị trực tiếp từ CreditProfile do Backend đánh giá.
class CreditHealthScreen extends StatefulWidget {
  const CreditHealthScreen({super.key});

  @override
  State<CreditHealthScreen> createState() => _CreditHealthScreenState();
}

class _CreditHealthScreenState extends State<CreditHealthScreen> {
  late final CreditProfileController _controller;
  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    _controller = sl<CreditProfileController>();
    _authController = sl<AuthController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = _authController.currentUser?.userId;
      _controller.loadCreditProfile(userId: userId);
    });
  }

  void _handleRecalculate() async {
    final userId = _authController.currentUser?.userId;
    final success = await _controller.recalculate(userId: userId);
    if (!mounted) return;
    if (success) {
      AppSnackBar.showSuccess(
        context,
        'Hồ sơ sức khỏe tín dụng đã được cập nhật thành công!',
      );
    } else {
      AppSnackBar.showError(
        context,
        _controller.errorMessage ?? 'Không thể tính toán lại hồ sơ tín dụng.',
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
        automaticallyImplyLeading: false,
        title: const Text(
          'Sức khỏe tín dụng',
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.assignment_outlined,
              color: AppColors.primary,
            ),
            tooltip: 'Báo cáo tín dụng định kỳ',
            onPressed: () =>
                Navigator.pushNamed(context, AppRouter.creditReports),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            tooltip: 'Làm mới',
            onPressed: () {
              final userId = _authController.currentUser?.userId;
              _controller.loadCreditProfile(userId: userId);
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading && _controller.creditProfile == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          // Lỗi phân quyền truy cập
          if (_controller.exceptionCode == 'EX-03') {
            return _buildErrorState(
              icon: Icons.gpp_bad_rounded,
              iconColor: AppColors.error,
              title: 'Không có quyền truy cập',
              message:
                  _controller.errorMessage ??
                  'Bạn không có quyền truy xuất hồ sơ tín dụng của tài khoản này.',
              actionLabel: 'Thử lại',
              onAction: () => _controller.loadCreditProfile(
                userId: _authController.currentUser?.userId,
              ),
            );
          }

          // Lỗi tính toán hoặc sự cố hệ thống
          if (_controller.exceptionCode == 'EX-04' &&
              _controller.creditProfile == null) {
            return _buildErrorState(
              icon: Icons.cloud_off_rounded,
              iconColor: AppColors.error,
              title: 'Sự cố kết nối hệ thống',
              message:
                  _controller.errorMessage ??
                  'Hệ thống gặp sự cố khi xử lý dữ liệu hồ sơ. Vui lòng thử lại sau.',
              actionLabel: 'Thử lại ngay',
              onAction: () => _controller.loadCreditProfile(
                userId: _authController.currentUser?.userId,
              ),
            );
          }

          // EX-01: Chưa có khoản vay nào trên hệ thống
          if (_controller.isEmptyState) {
            return RefreshIndicator(
              onRefresh: () => _controller.loadCreditProfile(
                userId: _authController.currentUser?.userId,
              ),
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 24.0,
                ),
                child: CreditEmptyState(
                  onRefresh: () => _controller.loadCreditProfile(
                    userId: _authController.currentUser?.userId,
                  ),
                ),
              ),
            );
          }

          final profile = _controller.creditProfile;

          return RefreshIndicator(
            onRefresh: () => _controller.loadCreditProfile(
              userId: _authController.currentUser?.userId,
            ),
            color: AppColors.primary,
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 14.0,
              ),
              children: [
                // 1. Thẻ Điểm sức khỏe tín dụng tổng quan (CreditScoreGauge)
                CreditScoreGauge(
                  profile: profile,
                  isRecalculating: _controller.isRecalculating,
                  onRecalculate: _handleRecalculate,
                ),
                const SizedBox(height: 12.0),

                // 1b. Lối tắt sang Báo cáo tín dụng định kỳ (Luồng Báo cáo tín dụng)
                InkWell(
                  onTap: () =>
                      Navigator.pushNamed(context, AppRouter.creditReports),
                  borderRadius: BorderRadius.circular(14.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14.0),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: const Icon(
                            Icons.history_edu_rounded,
                            color: AppColors.primary,
                            size: 20.0,
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Báo cáo tín dụng định kỳ',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 2.0),
                              Text(
                                'Xem lại lịch sử ảnh chụp và xu hướng biến động',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14.0,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),

                // 2. Banner cảnh báo khuyết thiếu dữ liệu (EX-02)
                if (_controller.hasMissingData) ...[
                  _buildMissingDataBanner(
                    context,
                    _controller.missingDataFactors,
                  ),
                  const SizedBox(height: 16.0),
                ],

                // 3. Tiêu đề danh mục chỉ số
                const Text(
                  'CHI TIẾT DANH MỤC CHỈ SỐ TÀI CHÍNH',
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10.0),

                // Chỉ số 1: Tỷ lệ DTI (Nợ / Thu nhập)
                CreditMetricCard(
                  title: 'Tỷ lệ Nợ trên Thu nhập (DTI)',
                  value: profile?.dtiRatio != null
                      ? '${(profile!.dtiRatio! * 100).toStringAsFixed(1)}%'
                      : null,
                  isMissingData: profile?.dtiRatio == null,
                  missingHint: 'Cập nhật thu nhập',
                  onAddMissingData: () => MainShellScreen.switchTab(context, 4),
                  status: _resolveDtiStatus(profile?.dtiRatio),
                  statusColor: _resolveDtiColor(profile?.dtiRatio),
                  description:
                      'Tỷ lệ giữa tổng nghĩa vụ trả nợ hàng tháng trên thu nhập thực nhận.',
                  icon: Icons.account_balance_rounded,
                  onTap: () => CreditFactorSheet.show(
                    context,
                    title: 'Tỷ lệ Nợ trên Thu nhập (DTI)',
                    currentValue: profile?.dtiRatio != null
                        ? '${(profile!.dtiRatio! * 100).toStringAsFixed(1)}%'
                        : 'Chưa thể tính',
                    formulaExplanation:
                        'Tỷ lệ giữa tổng chi phí trả nợ hàng tháng so với thu nhập thực nhận.\n• Dưới 40%: Mức an toàn, hồ sơ tài chính lành mạnh.\n• 40% - 50%: Mức cảnh báo, cần cân đối chi tiêu.\n• Trên 50%: Mức rủi ro cao, áp lực trả nợ lớn.',
                    sourceDescription:
                        'Tổng hợp từ mức thu nhập định kỳ hàng tháng trong hồ sơ cá nhân và lịch trả nợ các khoản vay hiện hành.',
                    icon: Icons.account_balance_rounded,
                  ),
                ),

                // Chỉ số 2: Tỷ lệ LTV (Khoản vay / Tài sản)
                CreditMetricCard(
                  title: 'Tỷ lệ Vay trên Giá trị Tài sản (LTV)',
                  value: profile?.ltvRatio != null
                      ? '${(profile!.ltvRatio! * 100).toStringAsFixed(1)}%'
                      : null,
                  isMissingData: profile?.ltvRatio == null,
                  missingHint: 'Thêm tài sản bảo đảm',
                  onAddMissingData: () =>
                      Navigator.pushNamed(context, AppRouter.loanCollateralOcr),
                  status: _resolveLtvStatus(profile?.ltvRatio),
                  statusColor: _resolveLtvColor(profile?.ltvRatio),
                  description:
                      'Đo lường mức độ đòn bẩy trên tổng tài sản bảo đảm đã được định giá.',
                  icon: Icons.domain_rounded,
                  onTap: () => CreditFactorSheet.show(
                    context,
                    title: 'Tỷ lệ Vay / Tài sản (LTV)',
                    currentValue: profile?.ltvRatio != null
                        ? '${(profile!.ltvRatio! * 100).toStringAsFixed(1)}%'
                        : 'Chưa thể tính',
                    formulaExplanation:
                        'Tỷ lệ giữa tổng số tiền vay thế chấp so với giá trị định giá của tài sản bảo đảm.\n• Dưới 70%: Mức đòn bẩy an toàn theo tiêu chuẩn ngân hàng.\n• 70% - 85%: Cần theo dõi biến động thị trường tài sản.\n• Trên 85%: Nguy cơ thiếu hụt giá trị bảo đảm khi thị trường biến động.',
                    sourceDescription:
                        'Tổng hợp từ số dư nợ của các khoản vay có thế chấp và chứng thư định giá tài sản bảo đảm được ghi nhận.',
                    icon: Icons.domain_rounded,
                  ),
                ),

                // Chỉ số 3: Tỷ lệ sử dụng hạn mức tín dụng
                CreditMetricCard(
                  title: 'Tỷ lệ sử dụng hạn mức tín dụng',
                  value: profile?.creditUtilization != null
                      ? '${(profile!.creditUtilization! * 100).toStringAsFixed(1)}%'
                      : null,
                  isMissingData: profile?.creditUtilization == null,
                  missingHint: 'Bổ sung hạn mức thẻ',
                  onAddMissingData: () =>
                      Navigator.pushNamed(context, AppRouter.loanForm),
                  status: _resolveUtilizationStatus(profile?.creditUtilization),
                  statusColor: _resolveUtilizationColor(
                    profile?.creditUtilization,
                  ),
                  description:
                      'Mức độ sử dụng hạn mức khả dụng của các khoản vay thấu chi / thẻ tín dụng.',
                  icon: Icons.credit_card_rounded,
                  onTap: () => CreditFactorSheet.show(
                    context,
                    title: 'Tỷ lệ sử dụng hạn mức',
                    currentValue: profile?.creditUtilization != null
                        ? '${(profile!.creditUtilization! * 100).toStringAsFixed(1)}%'
                        : 'Chưa thể tính',
                    formulaExplanation:
                        'Tỷ lệ giữa số dư nợ thẻ tín dụng đã dùng so với tổng hạn mức được tổ chức tài chính phê duyệt.\nKhuyến nghị duy trì dưới 30% tổng hạn mức để giữ điểm tín dụng ở mức tối ưu.',
                    sourceDescription:
                        'Tổng hợp từ dư nợ thực tế và hạn mức tín dụng được cấp trên các hợp đồng thẻ tín dụng của bạn.',
                    icon: Icons.credit_card_rounded,
                  ),
                ),

                // Chỉ số 4: Tỷ lệ thanh toán đúng hạn
                CreditMetricCard(
                  title: 'Tỷ lệ thanh toán đúng hạn',
                  value: profile?.onTimePaymentRate != null
                      ? '${(profile!.onTimePaymentRate! * 100).toStringAsFixed(1)}%'
                      : null,
                  isMissingData: profile?.onTimePaymentRate == null,
                  missingHint: 'Đồng bộ lịch sử trả nợ',
                  onAddMissingData: () => _handleRecalculate(),
                  status: _resolvePaymentStatus(profile?.onTimePaymentRate),
                  statusColor: _resolvePaymentColor(profile?.onTimePaymentRate),
                  description:
                      'Tỷ lệ các kỳ phân kỳ được thanh toán đầy đủ và đúng hạn quy định.',
                  icon: Icons.event_available_rounded,
                  onTap: () => CreditFactorSheet.show(
                    context,
                    title: 'Tỷ lệ thanh toán đúng hạn',
                    currentValue: profile?.onTimePaymentRate != null
                        ? '${(profile!.onTimePaymentRate! * 100).toStringAsFixed(1)}%'
                        : 'Chưa thể tính',
                    formulaExplanation:
                        'Tỷ lệ số kỳ thanh toán đúng thời hạn trên tổng số kỳ đã đến hạn trả nợ.\nĐây là tiêu chí quan trọng hàng đầu trong việc đánh giá mức độ uy tín của người vay.',
                    sourceDescription:
                        'Tổng hợp và đối chiếu từ kế hoạch trả nợ định kỳ cùng lịch sử các giao dịch thanh toán thực tế.',
                    icon: Icons.event_available_rounded,
                  ),
                ),

                // Chỉ số 5: Số khoản vay đang hoạt động
                CreditMetricCard(
                  title: 'Số khoản vay đang hoạt động',
                  value: '${profile?.activeLoanCount ?? 0} khoản vay',
                  status: (profile?.activeLoanCount ?? 0) <= 3
                      ? 'Hợp lý'
                      : 'Đang vay nhiều',
                  statusColor: (profile?.activeLoanCount ?? 0) <= 3
                      ? AppColors.success
                      : AppColors.warning,
                  description:
                      'Tổng số khoản vay đang trong trạng thái hoạt động được ghi nhận trong hệ thống.',
                  icon: Icons.format_list_numbered_rounded,
                  onTap: () => CreditFactorSheet.show(
                    context,
                    title: 'Số khoản vay đang hoạt động',
                    currentValue: '${profile?.activeLoanCount ?? 0} khoản',
                    formulaExplanation:
                        'Tổng số hợp đồng vay và thẻ tín dụng đang trong kỳ hạn và chưa được tất toán hoàn toàn.\nDuy trì số lượng khoản vay ở mức vừa phải giúp bạn chủ động quản lý dòng tiền trả nợ.',
                    sourceDescription:
                        'Tổng hợp từ danh mục các hợp đồng tín dụng đang có hiệu lực trên tài khoản của bạn.',
                    icon: Icons.format_list_numbered_rounded,
                  ),
                ),

                const SizedBox(height: 14.0),

                // 4. Khối cam kết minh bạch dữ liệu
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(14.0),
                    border: Border.all(
                      color: AppColors.primaryLight.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.verified_user_rounded,
                        color: AppColors.primary,
                        size: 26.0,
                      ),
                      const SizedBox(width: 12.0),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nguyên tắc bảo toàn dữ liệu',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(height: 2.0),
                            Text(
                              'Hệ thống không tự ý suy diễn hoặc gán giá trị giả mạo cho các chỉ số thiếu dữ liệu. Mọi đánh giá đều phản ánh đúng dữ liệu nguồn thực tế.',
                              style: TextStyle(
                                fontSize: 11.5,
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
                const SizedBox(
                  height: 80.0,
                ), // Khoảng đệm đáy cho Bottom Navigation Bar
              ],
            ),
          );
        },
      ),
    );
  }

  // ================= Helper Widgets & Status Resolvers =================

  Widget _buildMissingDataBanner(
    BuildContext context,
    List<String> missingFactors,
  ) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.warning_amber_rounded,
                size: 20.0,
                color: Color(0xFFD97706),
              ),
              SizedBox(width: 8.0),
              Text(
                'Dữ liệu cần bổ sung',
                style: TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF92400E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          const Text(
            'Hệ thống không thể tính toán trọn vẹn một số chỉ số do hồ sơ chưa được cập nhật đầy đủ:',
            style: TextStyle(
              fontSize: 12.0,
              color: Color(0xFF78350F),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 6.0),
          ...missingFactors.map(
            (factor) => Padding(
              padding: const EdgeInsets.only(left: 6.0, bottom: 3.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(
                      color: Color(0xFFD97706),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      factor,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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

  String _resolveDtiStatus(double? ratio) {
    if (ratio == null) return 'Chưa thể tính';
    if (ratio <= 0.40) return 'Rất tốt (<40%)';
    if (ratio <= 0.50) return 'Cảnh báo (40-50%)';
    return 'Rủi ro cao (>50%)';
  }

  Color _resolveDtiColor(double? ratio) {
    if (ratio == null) return AppColors.warning;
    if (ratio <= 0.40) return AppColors.success;
    if (ratio <= 0.50) return AppColors.warning;
    return AppColors.error;
  }

  String _resolveLtvStatus(double? ratio) {
    if (ratio == null) return 'Chưa thể tính';
    if (ratio <= 0.70) return 'An toàn (<70%)';
    if (ratio <= 0.85) return 'Cảnh báo (70-85%)';
    return 'Nguy hiểm (>85%)';
  }

  Color _resolveLtvColor(double? ratio) {
    if (ratio == null) return AppColors.warning;
    if (ratio <= 0.70) return AppColors.success;
    if (ratio <= 0.85) return AppColors.warning;
    return AppColors.error;
  }

  String _resolveUtilizationStatus(double? ratio) {
    if (ratio == null) return 'Chưa thể tính';
    if (ratio <= 0.30) return 'Tối ưu (<30%)';
    if (ratio <= 0.60) return 'Trung bình (30-60%)';
    return 'Quá tải (>60%)';
  }

  Color _resolveUtilizationColor(double? ratio) {
    if (ratio == null) return AppColors.warning;
    if (ratio <= 0.30) return AppColors.success;
    if (ratio <= 0.60) return const Color(0xFF2563EB);
    return AppColors.error;
  }

  String _resolvePaymentStatus(double? rate) {
    if (rate == null) return 'Chưa thể tính';
    if (rate >= 0.95) return 'Chuẩn mực';
    if (rate >= 0.85) return 'Khá';
    return 'Cần cải thiện';
  }

  Color _resolvePaymentColor(double? rate) {
    if (rate == null) return AppColors.warning;
    if (rate >= 0.95) return AppColors.success;
    if (rate >= 0.85) return const Color(0xFF2563EB);
    return AppColors.error;
  }
}

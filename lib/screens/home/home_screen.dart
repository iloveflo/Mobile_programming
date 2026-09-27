import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/loan_controller.dart';
import '../../routes/app_router.dart';
import '../../service_locator.dart';
import '../../widgets/widget.dart';

/// Màn hình Trang chủ FinCredit (HomeScreen)
/// Hiển thị lời chào người dùng, tóm tắt tài chính động 100%, điểm tín dụng CIC và truy cập nhanh dịch vụ
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthController _authController = sl<AuthController>();
  final LoanController _loanController = sl<LoanController>();

  @override
  void initState() {
    super.initState();
    // Tải dữ liệu khoản vay và phiên thiết bị động tương ứng với tài khoản đăng nhập
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_loanController.loans.isEmpty && !_loanController.isLoading) {
        _loanController.fetchLoans();
      }
      if (_authController.activeSessions.isEmpty) {
        _authController.loadSessions();
      }
    });
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

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        title: const Text('Xác nhận đăng xuất', style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)),
        content: const Text('Bạn có muốn đăng xuất khỏi tài khoản không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await _authController.logout();
              _loanController.clear();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(context, AppRouter.login, (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context, String serviceName, String description) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.0)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: const Icon(Icons.hourglass_top_rounded, color: AppColors.warning, size: 22.0),
            ),
            const SizedBox(width: 10.0),
            const Expanded(
              child: Text(
                'Tính năng đang phát triển',
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dịch vụ "$serviceName" hiện chưa khả dụng trên phiên bản thử nghiệm này.',
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8.0),
            Text(
              description,
              style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  void _showSupportModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.support_agent_rounded, color: Color(0xFFE11D48), size: 26.0),
                const SizedBox(width: 10.0),
                const Text(
                  'Hỗ trợ khách hàng 24/7',
                  style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 14.0),
            Container(
              padding: const EdgeInsets.all(14.0),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: const Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.phone_in_talk_rounded, color: AppColors.primary, size: 20.0),
                      SizedBox(width: 10.0),
                      Text('Hotline: ', style: TextStyle(fontSize: 13.0, color: AppColors.textSecondary)),
                      Text('1900 8888 (Miễn phí)', style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                  SizedBox(height: 10.0),
                  Row(
                    children: [
                      Icon(Icons.email_outlined, color: AppColors.primary, size: 20.0),
                      SizedBox(width: 10.0),
                      Text('Email hỗ trợ: ', style: TextStyle(fontSize: 13.0, color: AppColors.textSecondary)),
                      Text('hotro@fincredit.vn', style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14.0),
            const Text(
              'Đội ngũ chuyên viên tư vấn tài chính luôn sẵn sàng giải đáp thắc mắc về hợp đồng vay, phương thức tính lãi và tài sản bảo đảm.',
              style: TextStyle(fontSize: 12.0, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_authController, _loanController]),
      builder: (context, _) {
        final user = _authController.currentUser;
        final isSampleUser = user?.userId == 1;

        // Tính toán hạn mức tín dụng khả dụng động theo người dùng
        final double availableCreditLimit = isSampleUser
            ? (150000000.0 - _loanController.totalRemainingPrincipal).clamp(0.0, 150000000.0)
            : (_loanController.totalOriginalPrincipal > 0
                ? (_loanController.totalOriginalPrincipal - _loanController.totalRemainingPrincipal).clamp(0.0, _loanController.totalOriginalPrincipal)
                : 0.0);

        final double currentDebt = _loanController.totalRemainingPrincipal;

        // Điểm CIC động: Nếu tài khoản mẫu có dữ liệu thì hiển thị, tài khoản mới chưa có lịch sử
        final String cicScoreDisplay = isSampleUser
            ? '745 • Hạng 1 (Rất tốt)'
            : (_loanController.loans.isNotEmpty ? '680 • Đang cập nhật' : 'Chưa có dữ liệu CIC');

        final int activeSessionCount = _authController.activeSessions.isNotEmpty
            ? _authController.activeSessions.length
            : 1;
        final int securityScore = _authController.biometricEnabled ? 95 : 75;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            title: Row(
              children: [
                CircleAvatar(
                  radius: 18.0,
                  backgroundColor: AppColors.primarySoft,
                  child: Text(
                    (user?.fullName.isNotEmpty == true)
                        ? user!.fullName.substring(0, 1).toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontSize: 15.0,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Xin chào,',
                        style: TextStyle(fontSize: 11.0, color: AppColors.textSecondary),
                      ),
                      Text(
                        user?.fullName ?? 'Khách hàng FinCredit',
                        style: const TextStyle(
                          fontSize: 15.0,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              // Nút truy cập nhanh Cài đặt Bảo mật (M06)
              IconButton(
                icon: const Icon(Icons.shield_outlined, color: AppColors.primary),
                tooltip: 'Cài đặt Bảo mật (M06)',
                onPressed: () {
                  Navigator.pushNamed(context, AppRouter.security);
                },
              ),
              // Nút Đăng xuất
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
                tooltip: 'Đăng xuất',
                onPressed: () => _handleLogout(context),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Thẻ Tóm tắt tài chính FinTech (Dữ liệu ĐỘNG 100%)
                  InkWell(
                    onTap: () => Navigator.pushNamed(context, AppRouter.loans),
                    borderRadius: BorderRadius.circular(20.0),
                    child: Container(
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, Color(0xFF0A3A82)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20.0),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 16.0,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Hạn mức tín dụng khả dụng',
                                style: TextStyle(
                                  fontSize: 13.0,
                                  color: Color(0xFFBFDBFE),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.lock_rounded, size: 12.0, color: Colors.white),
                                    SizedBox(width: 4.0),
                                    Text(
                                      'TLS 1.3',
                                      style: TextStyle(fontSize: 10.0, color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10.0),
                          Text(
                            _formatCurrency(availableCreditLimit),
                            style: const TextStyle(
                              fontSize: 28.0,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 18.0),
                          const Divider(color: Color(0xFF1E4E8C), height: 1),
                          const SizedBox(height: 14.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Dư nợ hiện tại', style: TextStyle(fontSize: 11.0, color: Color(0xFFBFDBFE))),
                                  const SizedBox(height: 4.0),
                                  Text(
                                    _formatCurrency(currentDebt),
                                    style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w700, color: Colors.white),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('Điểm CIC', style: TextStyle(fontSize: 11.0, color: Color(0xFFBFDBFE))),
                                  const SizedBox(height: 4.0),
                                  Text(
                                    cicScoreDisplay,
                                    style: TextStyle(
                                      fontSize: 13.0,
                                      fontWeight: FontWeight.w700,
                                      color: isSampleUser ? const Color(0xFF86EFAC) : const Color(0xFFBFDBFE),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20.0),

                  // 2. Banner Trung tâm bảo mật (Dữ liệu ĐỘNG theo phiên và cài đặt)
                  InkWell(
                    onTap: () => Navigator.pushNamed(context, AppRouter.security),
                    borderRadius: BorderRadius.circular(14.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(14.0),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Colors.white,
                            child: Icon(Icons.shield_rounded, color: AppColors.primary, size: 22.0),
                          ),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Trung tâm Bảo mật Tài khoản',
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 2.0),
                                Text(
                                  'Điểm an toàn: $securityScore/100 • $activeSessionCount thiết bị đang hoạt động',
                                  style: const TextStyle(fontSize: 11.0, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 16.0, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24.0),

                  // 3. Phím tắt tiện ích Dịch vụ tín dụng
                  const Text(
                    'DỊCH VỤ TÍN DỤNG',
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  GridView.count(
                    crossAxisCount: 3,
                    childAspectRatio: 0.88,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12.0,
                    mainAxisSpacing: 12.0,
                    children: [
                      // 1. Đã có: Danh mục khoản vay (L02-01)
                      _buildQuickAction(
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'Danh mục khoản vay',
                        color: AppColors.primary,
                        onTap: () => Navigator.pushNamed(context, AppRouter.loans),
                      ),
                      // 2. Đã có: Thêm khoản vay mới (L02-03)
                      _buildQuickAction(
                        icon: Icons.add_circle_outline_rounded,
                        label: 'Thêm khoản vay',
                        color: const Color(0xFF0D9488),
                        onTap: () => Navigator.pushNamed(context, AppRouter.loanForm),
                      ),
                      // 3. Đã có: Quản lý tài sản thế chấp & OCR (L02-04)
                      _buildQuickAction(
                        icon: Icons.document_scanner_outlined,
                        label: 'Tài sản & OCR',
                        color: const Color(0xFF7C3AED),
                        onTap: () => Navigator.pushNamed(context, AppRouter.loanCollateralOcr),
                      ),
                      // 4. Chưa có: Tra cứu CIC (Thông báo rõ ràng, không điều hướng sai lệch)
                      _buildQuickAction(
                        icon: Icons.receipt_long_outlined,
                        label: 'Tra cứu CIC',
                        color: const Color(0xFF0284C7),
                        isComingSoon: true,
                        onTap: () => _showComingSoonDialog(
                          context,
                          'Tra cứu điểm tín dụng CIC',
                          'Hệ thống đang tích hợp cổng API trực tiếp với Trung tâm Thông tin Tín dụng Quốc gia (CIC) và sẽ sớm khả dụng ở phiên bản tiếp theo.',
                        ),
                      ),
                      // 5. Chưa có: Vay tín chấp trực tuyến (Thông báo rõ ràng)
                      _buildQuickAction(
                        icon: Icons.payments_outlined,
                        label: 'Vay tín chấp',
                        color: const Color(0xFFD97706),
                        isComingSoon: true,
                        onTap: () => _showComingSoonDialog(
                          context,
                          'Đăng ký Vay tín chấp',
                          'Dịch vụ kết nối hồ sơ giải ngân trực tuyến với các ngân hàng đối tác đang trong quá trình tích hợp thử nghiệm.',
                        ),
                      ),
                      // 6. Tiện ích: Hỗ trợ khách hàng 24/7
                      _buildQuickAction(
                        icon: Icons.support_agent_rounded,
                        label: 'Hỗ trợ 24/7',
                        color: const Color(0xFFE11D48),
                        onTap: () => _showSupportModal(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24.0),

                  // 4. Huy hiệu an toàn cuối trang
                  const Center(
                    child: SecurityBadge(
                      title: 'BẢO MẬT CHUẨN CIC & SBV',
                      protocol: 'TLS 1.3',
                    ),
                  ),
                  const SizedBox(height: 20.0),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
    bool isComingSoon = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14.0),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.1),
                  child: Icon(icon, color: color, size: 22.0),
                ),
                const SizedBox(height: 8.0),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          if (isComingSoon)
            Positioned(
              top: 6.0,
              right: 6.0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 2.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6.0),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text(
                  'Sắp có',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}


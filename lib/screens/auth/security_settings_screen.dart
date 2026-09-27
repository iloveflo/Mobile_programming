import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../models/session_model.dart';
import '../../routes/app_router.dart';
import '../../service_locator.dart';
import '../../widgets/widget.dart';

/// Màn hình Cài đặt Bảo mật & Quản lý Phiên Đăng nhập (M06)
class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final AuthController _authController = sl<AuthController>();

  @override
  void initState() {
    super.initState();
    // Luôn tải danh sách các phiên thiết bị thực tế của tài khoản đang đăng nhập
    _authController.loadSessions();
  }

  void _showChangePasswordBottomSheet() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String passwordValue = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                top: 20.0,
                bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom + 24.0,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40.0,
                          height: 4.0,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(2.0),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      const Text(
                        'Đổi mật khẩu tài khoản',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      const Text(
                        'Mật khẩu mới cần đáp ứng tiêu chuẩn an toàn bảo mật FinCredit.',
                        style: TextStyle(fontSize: 13.0, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 20.0),

                      // Mật khẩu hiện tại
                      AppTextField(
                        label: 'Mật khẩu hiện tại',
                        hint: 'Nhập mật khẩu hiện tại',
                        controller: currentPasswordController,
                        isPassword: true,
                        validator: (val) =>
                            (val == null || val.isEmpty) ? 'Vui lòng nhập mật khẩu hiện tại' : null,
                      ),
                      const SizedBox(height: 16.0),

                      // Mật khẩu mới
                      AppTextField(
                        label: 'Mật khẩu mới',
                        hint: 'Tối thiểu 8 ký tự',
                        controller: newPasswordController,
                        isPassword: true,
                        onChanged: (val) => setSheetState(() => passwordValue = val),
                        validator: (val) =>
                            (val == null || val.length < 8) ? 'Tối thiểu 8 ký tự' : null,
                      ),
                      const SizedBox(height: 6.0),
                      PasswordStrengthMeter(password: passwordValue),
                      const SizedBox(height: 16.0),

                      // Xác nhận mật khẩu mới
                      AppTextField(
                        label: 'Xác nhận mật khẩu mới',
                        hint: 'Nhập lại mật khẩu mới',
                        controller: confirmPasswordController,
                        isPassword: true,
                        validator: (val) =>
                            val != newPasswordController.text ? 'Mật khẩu không khớp' : null,
                      ),
                      const SizedBox(height: 24.0),

                      // Nút lưu
                      AppPrimaryButton(
                        label: 'Xác nhận đổi mật khẩu',
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.pop(bottomSheetContext);
                          final ok = await _authController.changePassword(
                            currentPassword: currentPasswordController.text,
                            newPassword: newPasswordController.text,
                          );
                          if (!mounted) return;
                          if (ok) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Đổi mật khẩu thành công!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          } else {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(_authController.errorMessage ?? 'Đổi mật khẩu thất bại.'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmRevokeSession(SessionModel session) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        title: const Text(
          'Thu hồi phiên đăng nhập?',
          style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Thiết bị "${session.deviceName}" (${session.platform}) sẽ bị đăng xuất khỏi tài khoản ngay lập tức.',
          style: const TextStyle(fontSize: 14.0, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await _authController.revokeSession(session.id);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã thu hồi phiên trên ${session.deviceName}'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Thu hồi'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error),
            SizedBox(width: 8.0),
            Text('Đăng xuất tài khoản', style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng FinCredit trên thiết bị này?',
          style: TextStyle(fontSize: 14.0, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await _authController.logout();
              if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Cài đặt Bảo mật',
          style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _authController,
          builder: (context, _) {
            final sessions = _authController.activeSessions;
            final user = _authController.currentUser;
            final isNewUser = user != null && user.userId != 1;

            // Tính điểm số sức khỏe bảo mật tài khoản thực tế
            final int score = _authController.biometricEnabled ? 95 : 75;
            final String ratingText = score >= 90 ? 'RẤT TỐT' : (score >= 70 ? 'KHÁ' : 'TRUNG BÌNH');
            final Color ratingColor = score >= 90 ? AppColors.success : (score >= 70 ? const Color(0xFFF59E0B) : AppColors.error);
            final double progressValue = score / 100.0;

            // Phụ đề cập nhật mật khẩu động
            final String passwordSubtitle = isNewUser
                ? 'Mật khẩu vừa thiết lập khi đăng ký'
                : 'Cập nhật lần cuối: 30 ngày trước';

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Thẻ Điểm sức khỏe bảo mật (ĐỘNG THEO CẤU HÌNH BẢO MẬT)
                  Container(
                    padding: const EdgeInsets.all(18.0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, Color(0xFF1565C0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16.0),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 12.0,
                          offset: const Offset(0, 4),
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
                                Icon(Icons.security_rounded, color: Colors.white, size: 22.0),
                                SizedBox(width: 8.0),
                                Text(
                                  'Sức khỏe bảo mật tài khoản',
                                  style: TextStyle(
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                              decoration: BoxDecoration(
                                color: ratingColor,
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Text(
                                ratingText,
                                style: const TextStyle(
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16.0),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$score',
                              style: const TextStyle(
                                fontSize: 36.0,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              ' / 100 Điểm',
                              style: TextStyle(fontSize: 16.0, color: Color(0xFFBFDBFE)),
                            ),
                            const Spacer(),
                            const SecurityBadge(
                              title: 'CHUẨN CIC',
                              protocol: 'TLS 1.3',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12.0),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4.0),
                          child: LinearProgressIndicator(
                            value: progressValue,
                            minHeight: 6.0,
                            backgroundColor: const Color(0xFF1E3A8A),
                            valueColor: AlwaysStoppedAnimation<Color>(ratingColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24.0),

                  // 2. Nhóm Tùy chọn cài đặt an toàn
                  const Text(
                    'PHƯƠNG THỨC XÁC THỰC',
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14.0),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.primarySoft,
                            child: Icon(Icons.lock_outline, color: AppColors.primary, size: 20.0),
                          ),
                          title: const Text('Đổi mật khẩu đăng nhập', style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.w600)),
                          subtitle: Text(passwordSubtitle, style: const TextStyle(fontSize: 12.0, color: AppColors.textSecondary)),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16.0, color: AppColors.textSecondary),
                          onTap: _showChangePasswordBottomSheet,
                        ),
                        const Divider(height: 1, indent: 64.0, color: AppColors.border),
                        SwitchListTile(
                          secondary: const CircleAvatar(
                            backgroundColor: AppColors.primarySoft,
                            child: Icon(Icons.fingerprint_rounded, color: AppColors.primary, size: 22.0),
                          ),
                          title: const Text('Xác thực Sinh trắc học', style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.w600)),
                          subtitle: const Text('Sử dụng Face ID / Vân tay khi đăng nhập', style: TextStyle(fontSize: 12.0, color: AppColors.textSecondary)),
                          value: _authController.biometricEnabled,
                          activeTrackColor: AppColors.primary,
                          onChanged: (val) => _authController.setBiometricEnabled(val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24.0),

                  // 3. Quản lý Phiên đăng nhập thiết bị
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'PHIÊN ĐĂNG NHẬP THIẾT BỊ',
                        style: TextStyle(
                          fontSize: 12.0,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        '${sessions.length} thiết bị',
                        style: const TextStyle(fontSize: 12.0, color: AppColors.primary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10.0),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14.0),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sessions.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1, indent: 64.0, color: AppColors.border),
                      itemBuilder: (context, index) {
                        final session = sessions[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: session.isCurrent
                                ? AppColors.success.withValues(alpha: 0.12)
                                : AppColors.primarySoft,
                            child: Icon(
                              session.platform.contains('macOS') || session.platform.contains('Chrome')
                                  ? Icons.laptop_mac_rounded
                                  : Icons.smartphone_rounded,
                              color: session.isCurrent ? AppColors.success : AppColors.primary,
                              size: 20.0,
                            ),
                          ),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  session.deviceName,
                                  style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (session.isCurrent) ...[
                                const SizedBox(width: 6.0),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: const Text(
                                    'Thiết bị này',
                                    style: TextStyle(
                                      fontSize: 10.0,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(
                            '${session.platform}\n${session.location} • ${session.ipAddress}',
                            style: const TextStyle(fontSize: 12.0, color: AppColors.textSecondary, height: 1.3),
                          ),
                          isThreeLine: true,
                          trailing: session.isCurrent
                              ? null
                              : TextButton(
                                  onPressed: () => _confirmRevokeSession(session),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.error,
                                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                  ),
                                  child: const Text(
                                    'Thu hồi',
                                    style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w600),
                                  ),
                                ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32.0),

                  // 4. Nút Đăng xuất tài khoản
                  OutlinedButton.icon(
                    onPressed: _confirmLogout,
                    icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20.0),
                    label: const Text(
                      'Đăng xuất tài khoản',
                      style: TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                      side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.2),
                      backgroundColor: const Color(0xFFFEF2F2),
                    ),
                  ),
                  const SizedBox(height: 24.0),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

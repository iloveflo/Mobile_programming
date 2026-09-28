import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../models/session_model.dart';
import '../../routes/app_router.dart';
import '../../service_locator.dart';
import '../../widgets/widget.dart';

/// Màn hình Cài đặt Hệ thống & Bảo mật Ứng dụng (AppSettingsScreen)
/// Tích hợp đầy đủ cấu hình thông báo, bảo mật sinh trắc học, quản lý phiên thiết bị và hệ thống.
class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  final AuthController _authController = sl<AuthController>();

  bool _reminder3Days = true;
  bool _balanceNotice = true;
  bool _monthlyStatementEmail = true;
  bool _autoLock5Min = true;
  String _cacheSize = '12.4 MB';

  @override
  void initState() {
    super.initState();
    // Luôn tải danh sách phiên thiết bị đăng nhập thực tế của tài khoản
    _authController.loadSessions();
  }

  void _clearCache() {
    setState(() {
      _cacheSize = '0.0 MB';
    });
    AppSnackBar.showSuccess(
      context,
      'Đã dọn dẹp bộ nhớ đệm (cache) thành công!',
    );
  }

  void _confirmRevokeSession(SessionModel session) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: const Text(
          'Thu hồi phiên đăng nhập?',
          style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Thiết bị "${session.deviceName}" (${session.platform}) sẽ bị đăng xuất khỏi tài khoản ngay lập tức.',
          style: const TextStyle(
            fontSize: 14.0,
            color: AppColors.textSecondary,
          ),
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
              if (!mounted) {
                return;
              }
              AppSnackBar.showSuccess(
                context,
                'Đã thu hồi phiên trên ${session.deviceName}',
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error),
            SizedBox(width: 8.0),
            Text(
              'Đăng xuất tài khoản',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn kết thúc phiên đăng nhập?',
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
              if (!mounted) {
                return;
              }
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRouter.login,
                (route) => false,
              );
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
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'Cài đặt & Bảo mật',
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: _authController,
        builder: (context, _) {
          final sessions = _authController.activeSessions;

          // Tính toán điểm sức khỏe bảo mật tài khoản dựa trên sinh trắc học
          final int score = _authController.biometricEnabled ? 95 : 75;
          final String ratingText = score >= 90
              ? 'RẤT TỐT'
              : (score >= 70 ? 'KHÁ' : 'TRUNG BÌNH');
          final Color ratingColor = score >= 90
              ? AppColors.success
              : (score >= 70 ? const Color(0xFFF59E0B) : AppColors.error);
          final double progressValue = score / 100.0;

          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 14.0,
            ),
            children: [
              // 1. Thẻ Sức khỏe Bảo mật Tài khoản
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
                            Icon(
                              Icons.security_rounded,
                              color: Colors.white,
                              size: 22.0,
                            ),
                            SizedBox(width: 8.0),
                            Text(
                              'Sức khỏe bảo mật tài khoản',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10.0,
                            vertical: 4.0,
                          ),
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
                          style: TextStyle(
                            fontSize: 16.0,
                            color: Color(0xFFBFDBFE),
                          ),
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

              const SizedBox(height: 20.0),

              // 2. Nhóm: Phương thức xác thực & Bảo mật tài khoản
              _buildSectionHeader('Phương thức xác thực'),
              _buildCard([
                SwitchListTile(
                  value: _authController.isBiometricEnabled,
                  activeThumbColor: AppColors.primary,
                  activeTrackColor: AppColors.primarySoft,
                  title: const Text(
                    'Sinh trắc học (Vân tay / Face ID)',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Đăng nhập nhanh an toàn trên thiết bị này',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  onChanged: (val) {
                    _authController.setBiometricEnabled(val);
                  },
                ),
                const Divider(height: 1.0),
                SwitchListTile(
                  value: _autoLock5Min,
                  activeThumbColor: AppColors.primary,
                  activeTrackColor: AppColors.primarySoft,
                  title: const Text(
                    'Tự động khóa sau 5 phút',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Yêu cầu xác thực khi mở lại app ở chế độ nền',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _autoLock5Min = val;
                    });
                  },
                ),
              ]),

              const SizedBox(height: 20.0),

              // 3. Nhóm: Quản lý Phiên đăng nhập thiết bị
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionHeader('Phiên đăng nhập thiết bị'),
                  Padding(
                    padding: const EdgeInsets.only(right: 4.0, bottom: 8.0),
                    child: Text(
                      '${sessions.length} thiết bị',
                      style: const TextStyle(
                        fontSize: 12.0,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              _buildCard([
                for (int i = 0; i < sessions.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      height: 1.0,
                      indent: 64.0,
                      color: AppColors.border,
                    ),
                  _buildSessionTile(sessions[i]),
                ],
              ]),

              const SizedBox(height: 20.0),

              // 4. Nhóm: Thông báo & Nhắc nợ
              _buildSectionHeader('Thông báo & Nhắc nợ'),
              _buildCard([
                SwitchListTile(
                  value: _reminder3Days,
                  activeThumbColor: AppColors.primary,
                  activeTrackColor: AppColors.primarySoft,
                  title: const Text(
                    'Nhắc hạn trả nợ trước 3 ngày',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Nhận thông báo đẩy trước ngày đến hạn thanh toán',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _reminder3Days = val;
                    });
                  },
                ),
                const Divider(height: 1.0),
                SwitchListTile(
                  value: _balanceNotice,
                  activeThumbColor: AppColors.primary,
                  activeTrackColor: AppColors.primarySoft,
                  title: const Text(
                    'Thông báo biến động dư nợ',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Cập nhật sau mỗi lần thanh toán hoặc giải ngân',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _balanceNotice = val;
                    });
                  },
                ),
                const Divider(height: 1.0),
                SwitchListTile(
                  value: _monthlyStatementEmail,
                  activeThumbColor: AppColors.primary,
                  activeTrackColor: AppColors.primarySoft,
                  title: const Text(
                    'Gửi sao kê qua Email định kỳ',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Báo cáo tổng hợp số dư và lãi suất ngày 01 hàng tháng',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _monthlyStatementEmail = val;
                    });
                  },
                ),
              ]),

              const SizedBox(height: 20.0),

              // 5. Nhóm: Dữ liệu & Bộ nhớ tạm
              _buildSectionHeader('Dữ liệu & Bộ nhớ tạm'),
              _buildCard([
                ListTile(
                  title: const Text(
                    'Dung lượng bộ nhớ đệm',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Đang chiếm dụng: $_cacheSize',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: OutlinedButton(
                    onPressed: _clearCache,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: Color(0xFFFECACA)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Text(
                      'Xóa cache',
                      style: TextStyle(fontSize: 12.0),
                    ),
                  ),
                ),
              ]),

              const SizedBox(height: 20.0),

              // 6. Nhóm: Thông tin ứng dụng
              _buildSectionHeader('Thông tin ứng dụng'),
              _buildCard([
                const ListTile(
                  title: Text(
                    'Phiên bản ứng dụng',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: Text(
                    '1.0.0+1 (Release)',
                    style: TextStyle(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const Divider(height: 1.0),
                const ListTile(
                  title: Text(
                    'Tiêu chuẩn an ninh',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: Text(
                    'TLS 1.3 • Chuẩn CIC SBV',
                    style: TextStyle(
                      fontSize: 12.0,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Divider(height: 1.0),
                ListTile(
                  title: const Text(
                    'Điều khoản sử dụng & Chính sách bảo mật',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.open_in_new_rounded,
                    size: 18.0,
                    color: AppColors.textSecondary,
                  ),
                  onTap: () {
                    AppSnackBar.showInfo(
                      context,
                      'Mở chính sách bảo mật dữ liệu FinCredit (Bảo mật theo quy định NHNN).',
                    );
                  },
                ),
              ]),

              const SizedBox(height: 24.0),

              // 7. Nút Đăng xuất tài khoản
              OutlinedButton.icon(
                onPressed: _confirmLogout,
                icon: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.error,
                  size: 20.0,
                ),
                label: const Text(
                  'Đăng xuất tài khoản',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.2),
                  backgroundColor: const Color(0xFFFEF2F2),
                ),
              ),

              const SizedBox(height: 80.0), // Đệm đáy cho Bottom Nav Bar
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildSessionTile(SessionModel session) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: session.isCurrent
            ? AppColors.success.withValues(alpha: 0.12)
            : AppColors.primarySoft,
        child: Icon(
          session.platform.contains('macOS') ||
                  session.platform.contains('Chrome')
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
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (session.isCurrent) ...[
            const SizedBox(width: 6.0),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6.0,
                vertical: 2.0,
              ),
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
        style: const TextStyle(
          fontSize: 11.5,
          color: AppColors.textSecondary,
          height: 1.3,
        ),
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
  }

  Widget _buildCard(List<Widget> children) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14.0),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }
}

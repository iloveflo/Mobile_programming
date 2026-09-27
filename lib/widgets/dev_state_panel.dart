import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Các trạng thái xác thực giả lập phục vụ Dev/QA kiểm thử nhanh giao diện
enum DevAuthState {
  normal(
    label: 'Normal',
    description: 'Form rỗng / Mặc định',
    icon: Icons.check_circle_outline,
  ),
  loading(
    label: 'Loading',
    description: 'Đang gọi API',
    icon: Icons.hourglass_top_outlined,
  ),
  invalidCredentials(
    label: 'Invalid Credentials',
    description: 'Sai email hoặc mật khẩu',
    icon: Icons.warning_amber_rounded,
  ),
  accountUnverified(
    label: 'Account Unverified',
    description: 'Chưa kích hoạt - Chuyển sang OTP',
    icon: Icons.phonelink_ring_outlined,
  ),
  accountLocked(
    label: 'Account Locked',
    description: 'Tạm khóa tài khoản 15 phút',
    icon: Icons.lock_clock_outlined,
  ),
  networkError(
    label: 'Network Error',
    description: 'Mất kết nối mạng',
    icon: Icons.wifi_off_outlined,
  ),
  sessionExpired(
    label: 'Session Expired',
    description: 'Hết hạn phiên đăng nhập',
    icon: Icons.timer_off_outlined,
  );

  final String label;
  final String description;
  final IconData icon;

  const DevAuthState({
    required this.label,
    required this.description,
    required this.icon,
  });
}

/// Bảng điều khiển giả lập trạng thái dành cho Developer và QA.
/// Hỗ trợ thu gọn và mở rộng linh hoạt, tránh che khuất luồng giao diện chính.
class DevStatePanel extends StatefulWidget {
  /// Trạng thái đang được chọn
  final DevAuthState currentState;

  /// Callback khi Dev/QA chọn một trạng thái mới
  final ValueChanged<DevAuthState> onStateSelected;

  /// Mặc định mở rộng khi khởi tạo
  final bool initiallyExpanded;

  const DevStatePanel({
    super.key,
    required this.currentState,
    required this.onStateSelected,
    this.initiallyExpanded = false,
  });

  @override
  State<DevStatePanel> createState() => _DevStatePanelState();
}

class _DevStatePanelState extends State<DevStatePanel> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: const BorderSide(color: AppColors.border, width: 1.0),
      ),
      margin: const EdgeInsets.all(12.0),
      color: AppColors.surface,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: Nhấp vào để thu gọn/mở rộng panel
            InkWell(
              onTap: _toggleExpanded,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14.0,
                  vertical: 10.0,
                ),
                color: AppColors.primarySoft,
                child: Row(
                  children: [
                    const Icon(
                      Icons.developer_mode_rounded,
                      size: 20.0,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8.0),
                    const Text(
                      'Dev / QA State Panel',
                      style: TextStyle(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 3.0,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Text(
                        widget.currentState.label,
                        style: const TextStyle(
                          fontSize: 11.0,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppColors.primary,
                      size: 20.0,
                    ),
                  ],
                ),
              ),
            ),
            // Body: Danh sách các State giả lập khi mở rộng
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: DevAuthState.values.map((state) {
                    final bool isSelected = widget.currentState == state;
                    return InkWell(
                      onTap: () {
                        widget.onStateSelected(state);
                      },
                      borderRadius: BorderRadius.circular(10.0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10.0,
                          vertical: 8.0,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(10.0),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              state.icon,
                              size: 15.0,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6.0),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  state.label,
                                  style: TextStyle(
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  state.description,
                                  style: TextStyle(
                                    fontSize: 10.0,
                                    color: isSelected
                                        ? Colors.white.withValues(alpha: 0.8)
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../models/notification_preference_model.dart';
import '../common/app_colors.dart';

/// Modal Cài đặt Kênh nhắc nợ & Số ngày nhắc trước hạn (Mục 8)
class NotificationPreferenceSheet extends StatefulWidget {
  final NotificationPreferenceModel currentPreference;
  final String? userEmail;
  final String? userPhone;
  final Future<bool> Function(NotificationPreferenceModel newPref) onSave;

  const NotificationPreferenceSheet({
    super.key,
    required this.currentPreference,
    this.userEmail,
    this.userPhone,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required NotificationPreferenceModel currentPreference,
    String? userEmail,
    String? userPhone,
    required Future<bool> Function(NotificationPreferenceModel newPref) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NotificationPreferenceSheet(
        currentPreference: currentPreference,
        userEmail: userEmail,
        userPhone: userPhone,
        onSave: onSave,
      ),
    );
  }

  @override
  State<NotificationPreferenceSheet> createState() =>
      _NotificationPreferenceSheetState();
}

class _NotificationPreferenceSheetState
    extends State<NotificationPreferenceSheet> {
  late bool _pushEnabled;
  late bool _emailEnabled;
  late int _reminderDays;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _pushEnabled = widget.currentPreference.pushEnabled;
    _emailEnabled = widget.currentPreference.emailEnabled;
    _reminderDays = widget.currentPreference.reminderDays;
  }

  void _handleSave() async {
    setState(() => _isSaving = true);

    final updated = widget.currentPreference.copyWith(
      pushEnabled: _pushEnabled,
      emailEnabled: _emailEnabled,
      reminderDays: _reminderDays,
    );

    final success = await widget.onSave(updated);
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasNoEmail =
        widget.userEmail == null || widget.userEmail!.trim().isEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: 18.0),
          Row(
            children: const [
              Icon(Icons.tune_rounded, color: AppColors.primary, size: 24.0),
              SizedBox(width: 10.0),
              Text(
                'Cài đặt nhắc nợ định kỳ',
                style: TextStyle(
                  fontSize: 17.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          const Text(
            'Chủ động tùy chỉnh kênh nhận thông báo và thời điểm hệ thống gửi tin nhắc trước hạn.',
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18.0),

          // 1. Lựa chọn số ngày nhắc trước hạn
          const Text(
            'Nhắc trước ngày đến hạn',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10.0),
          Row(
            children: [1, 3, 5, 7].map((days) {
              final isSelected = _reminderDays == days;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: InkWell(
                    onTap: () => setState(() => _reminderDays = days),
                    borderRadius: BorderRadius.circular(10.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$days ngày',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20.0),

          // 2. Danh mục các kênh liên lạc
          const Text(
            'Kênh nhận thông báo',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10.0),

          // Push Notification
          _buildChannelTile(
            icon: Icons.notifications_active_rounded,
            title: 'Thông báo ứng dụng (Push)',
            subtitle: 'Nhận thông báo nổi trực tiếp trên thiết bị di động.',
            value: _pushEnabled,
            onChanged: (val) => setState(() => _pushEnabled = val),
          ),

          // Email
          _buildChannelTile(
            icon: Icons.email_rounded,
            title: 'Hộp thư điện tử (Email)',
            subtitle: widget.userEmail ?? 'Chưa cập nhật email',
            value: _emailEnabled,
            warning: (_emailEnabled && hasNoEmail)
                ? 'Chưa có email trong hồ sơ cá nhân'
                : null,
            onChanged: (val) => setState(() => _emailEnabled = val),
          ),
          const SizedBox(height: 20.0),

          // Nút lưu
          ElevatedButton(
            onPressed: _isSaving ? null : _handleSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20.0,
                    height: 20.0,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Lưu thiết lập nhắc nợ',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    String? warning,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: warning != null ? AppColors.warning : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22.0),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (warning != null) ...[
                  const SizedBox(height: 2.0),
                  Text(
                    '⚠ $warning',
                    style: const TextStyle(
                      fontSize: 11.0,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB45309),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

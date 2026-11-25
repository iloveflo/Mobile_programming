import 'package:flutter/material.dart';

import '../../models/notification_model.dart';
import '../common/app_colors.dart';

/// Modal Hộp thư Thông báo nhắc nợ (Mục 9)
/// Cho phép điều hướng trực tiếp sang kỳ thanh toán tương ứng khi nhấn vào thông báo
class NotificationListSheet extends StatefulWidget {
  final List<NotificationModel> notifications;
  final ValueChanged<int> onSelectSchedule;
  final Future<bool> Function(int notificationId)? onDeleteNotification;
  final Future<bool> Function()? onClearAll;

  const NotificationListSheet({
    super.key,
    required this.notifications,
    required this.onSelectSchedule,
    this.onDeleteNotification,
    this.onClearAll,
  });

  static Future<void> show(
    BuildContext context, {
    required List<NotificationModel> notifications,
    required ValueChanged<int> onSelectSchedule,
    Future<bool> Function(int notificationId)? onDeleteNotification,
    Future<bool> Function()? onClearAll,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NotificationListSheet(
        notifications: notifications,
        onSelectSchedule: onSelectSchedule,
        onDeleteNotification: onDeleteNotification,
        onClearAll: onClearAll,
      ),
    );
  }

  @override
  State<NotificationListSheet> createState() => _NotificationListSheetState();
}

class _NotificationListSheetState extends State<NotificationListSheet> {
  late List<NotificationModel> _items;
  bool _isMutating = false;

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.notifications);
  }

  Future<void> _handleDeleteOne(NotificationModel notif) async {
    if (widget.onDeleteNotification == null || _isMutating) return;
    setState(() => _isMutating = true);
    final ok = await widget.onDeleteNotification!(notif.id);
    if (!mounted) return;
    setState(() {
      _isMutating = false;
      if (ok) {
        _items.removeWhere((n) => n.id == notif.id);
      }
    });
  }

  Future<void> _handleClearAll() async {
    if (widget.onClearAll == null || _isMutating || _items.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa tất cả thông báo'),
        content: const Text(
          'Bạn có chắc muốn xóa toàn bộ thông báo hiện có không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa tất cả'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isMutating = true);
    final ok = await widget.onClearAll!();
    if (!mounted) return;
    setState(() {
      _isMutating = false;
      if (ok) {
        _items.clear();
      }
    });
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'Chờ gửi';
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute $day/$month/${dt.year}';
  }

  String _resolveChannelBadge(String channel) {
    switch (channel.toUpperCase()) {
      case 'PUSH':
        return 'Push App';
      case 'EMAIL':
        return 'Email';
      default:
        return channel;
    }
  }

  Color _resolveStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'SENT':
        return AppColors.success;
      case 'PENDING':
        return const Color(0xFF2563EB);
      case 'FAILED':
        return AppColors.error;
      case 'CANCELLED':
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }

  String _resolveStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'SENT':
        return 'Đã gửi';
      case 'PENDING':
        return 'Đã lập lịch';
      case 'FAILED':
        return 'Thất bại';
      case 'CANCELLED':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Column(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: const [
                    Icon(
                      Icons.mail_outline_rounded,
                      color: AppColors.primary,
                      size: 24.0,
                    ),
                    SizedBox(width: 10.0),
                    Expanded(
                      child: Text(
                        'Thông báo',
                        style: TextStyle(
                          fontSize: 17.0,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8.0),
              if (widget.onClearAll != null && _items.isNotEmpty) ...[
                TextButton(
                  onPressed: _isMutating ? null : _handleClearAll,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Xóa hết',
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 4.0),
              ],
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 4.0,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  '${_items.length} tin',
                  style: const TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          const Text(
            'Lịch sử các cảnh báo, nhắc nợ và biến động tín dụng của bạn.',
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16.0),

          Expanded(
            child: _items.isEmpty
                ? const Center(
                    child: Text(
                      'Chưa có thông báo nào.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13.0,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: _items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10.0),
                    itemBuilder: (context, index) {
                      final notif = _items[index];
                      final statusColor = _resolveStatusColor(notif.status);

                      return InkWell(
                        onTap: notif.scheduleId != null
                            ? () {
                                Navigator.pop(context);
                                widget.onSelectSchedule(notif.scheduleId!);
                              }
                            : null,
                        borderRadius: BorderRadius.circular(14.0),
                        child: Container(
                          padding: const EdgeInsets.all(14.0),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(14.0),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                      vertical: 3.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primarySoft,
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: Text(
                                      _resolveChannelBadge(notif.channel),
                                      style: const TextStyle(
                                        fontSize: 11.0,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8.0),
                                  Expanded(
                                    child: Text(
                                      notif.title,
                                      style: const TextStyle(
                                        fontSize: 13.0,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8.0),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                      vertical: 3.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    child: Text(
                                      _resolveStatusLabel(notif.status),
                                      style: TextStyle(
                                        fontSize: 11.0,
                                        fontWeight: FontWeight.w700,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                  if (widget.onDeleteNotification != null) ...[
                                    const SizedBox(width: 4.0),
                                    InkWell(
                                      onTap: _isMutating
                                          ? null
                                          : () => _handleDeleteOne(notif),
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: const Padding(
                                        padding: EdgeInsets.all(4.0),
                                        child: Icon(
                                          Icons.delete_outline_rounded,
                                          size: 18.0,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 6.0),
                              Text(
                                notif.message,
                                style: const TextStyle(
                                  fontSize: 12.0,
                                  color: AppColors.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      notif.sentAt != null
                                          ? 'Đã gửi: ${_formatDateTime(notif.sentAt)}'
                                          : 'Lập lịch: ${_formatDateTime(notif.scheduledAt)}',
                                      style: const TextStyle(
                                        fontSize: 11.0,
                                        color: AppColors.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (notif.scheduleId != null) ...[
                                    const SizedBox(width: 8.0),
                                    Row(
                                      children: const [
                                        Text(
                                          'Xem kỳ hạn',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        SizedBox(width: 2.0),
                                        Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 10.0,
                                          color: AppColors.primary,
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../common/app_colors.dart';

/// Hộp thoại hỗ trợ người dùng xác nhận hoặc lựa chọn kỳ báo cáo muốn khởi tạo (Luồng 1)
/// Kiểm soát chặt chẽ:
/// 1. Chống lập khống tương lai (No Future Period)
/// 2. Chống tạo trùng kỳ (Anti-Duplicate / Anti-Spam)
class GenerateReportDialog extends StatefulWidget {
  final List<String> existingPeriods;
  final Future<bool> Function(String period) onConfirm;

  const GenerateReportDialog({
    super.key,
    this.existingPeriods = const [],
    required this.onConfirm,
  });

  static Future<void> show(
    BuildContext context, {
    List<String> existingPeriods = const [],
    required Future<bool> Function(String period) onConfirm,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GenerateReportDialog(
        existingPeriods: existingPeriods,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<GenerateReportDialog> createState() => _GenerateReportDialogState();
}

class _GenerateReportDialogState extends State<GenerateReportDialog> {
  late final TextEditingController _periodController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final suggested = _calculateNextSuggestedPeriod(widget.existingPeriods);
    _periodController = TextEditingController(text: suggested);
    _periodController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _periodController.dispose();
    super.dispose();
  }

  /// Tính toán kỳ phù hợp để đề xuất (tuyệt đối không đề xuất vượt quá thời điểm hiện tại)
  static String _calculateNextSuggestedPeriod(List<String> existing) {
    final now = DateTime.now();
    final currentMonthStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';

    // 1. Nếu kỳ hiện tại chưa được lập, ưu tiên đề xuất kỳ hiện tại
    if (!existing.any((p) => p.trim() == currentMonthStr)) {
      return currentMonthStr;
    }

    // 2. Nếu kỳ hiện tại đã lập, tìm xem có kỳ quá khứ nào bị khuyết trong 6 tháng gần nhất không
    for (int i = 1; i <= 6; i++) {
      final pastDate = DateTime(now.year, now.month - i, 1);
      final pastStr =
          '${pastDate.year}-${pastDate.month.toString().padLeft(2, '0')}';
      if (!existing.any((p) => p.trim() == pastStr)) {
        return pastStr;
      }
    }

    // 3. Nếu tất cả các kỳ đến hiện tại đã lập xong, giữ ở kỳ hiện tại
    return currentMonthStr;
  }

  /// Kiểm tra xem kỳ nhập vào có thuộc tương lai hay không
  bool get _isFuturePeriod {
    final text = _periodController.text.trim();
    final parts = text.split('-');
    if (parts.length == 2) {
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (y != null && m != null) {
        final now = DateTime.now();
        if (y > now.year || (y == now.year && m > now.month)) {
          return true;
        }
      }
    }
    return false;
  }

  /// Kiểm tra xem kỳ nhập vào đã tồn tại trong danh sách chưa
  bool get _isDuplicate {
    final text = _periodController.text.trim();
    return widget.existingPeriods.any((p) => p.trim() == text);
  }

  /// Trạng thái kiểm tra xem toàn bộ các kỳ đến tháng hiện tại đã lập hết chưa
  bool get _isAllCurrentReportsCompleted {
    final now = DateTime.now();
    final currentMonthStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';
    return widget.existingPeriods.any((p) => p.trim() == currentMonthStr);
  }

  String? get _errorText {
    final text = _periodController.text.trim();
    if (text.isEmpty) return 'Vui lòng nhập kỳ báo cáo.';
    if (_isFuturePeriod) {
      final now = DateTime.now();
      return 'Không thể lập khống báo cáo tương lai (Hiện tại là Tháng ${now.month}/${now.year}).';
    }
    if (_isDuplicate) {
      return 'Kỳ báo cáo này đã được khởi tạo trước đó. Mỗi kỳ chỉ lập 1 lần.';
    }
    return null;
  }

  void _handleSubmit() async {
    final period = _periodController.text.trim();
    if (period.isEmpty || _isFuturePeriod || _isDuplicate || _isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);
    final success = await widget.onConfirm(period);
    if (!mounted) {
      return;
    }
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final period = _periodController.text.trim();
    final error = _errorText;
    final isValid = period.isNotEmpty && error == null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
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
                Icon(
                  Icons.add_chart_rounded,
                  color: AppColors.primary,
                  size: 24.0,
                ),
                SizedBox(width: 10.0),
                Text(
                  'Lập báo cáo tín dụng kỳ mới',
                  style: TextStyle(
                    fontSize: 17.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            const Text(
              'Báo cáo tín dụng là ảnh chụp (Snapshot) dữ liệu lịch sử hoặc hiện tại. Hệ thống chỉ cho phép lập báo cáo cho kỳ hiện tại hoặc quá khứ, không lập cho tương lai.',
              style: TextStyle(
                fontSize: 13.0,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14.0),

            // Thông báo nếu đã hoàn thành tất cả các kỳ đến tháng hiện tại
            if (_isAllCurrentReportsCompleted && _isDuplicate) ...[
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      size: 20.0,
                    ),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: Text(
                        'Bạn đã lập báo cáo đầy đủ đến kỳ hiện tại (Tháng ${now.month}/${now.year}). Kỳ báo cáo mới sẽ tự động mở khi bước sang tháng tiếp theo.',
                        style: const TextStyle(
                          fontSize: 12.0,
                          color: Color(0xFF166534),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14.0),
            ],

            const Text(
              'Kỳ báo cáo (Định dạng YYYY-MM hoặc Quý)',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6.0),
            TextField(
              controller: _periodController,
              decoration: InputDecoration(
                hintText: 'Ví dụ: 2026-09 hoặc 2026-10',
                prefixIcon: const Icon(
                  Icons.calendar_month_rounded,
                  size: 20.0,
                ),
                filled: true,
                fillColor: AppColors.background,
                errorText: error,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(
                    color: error != null ? AppColors.error : AppColors.border,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(
                    color: error != null ? AppColors.error : AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24.0),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: const Text('Hủy'),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: (isValid && !_isSubmitting)
                        ? _handleSubmit
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.border,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20.0,
                            height: 20.0,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Khởi tạo báo cáo',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

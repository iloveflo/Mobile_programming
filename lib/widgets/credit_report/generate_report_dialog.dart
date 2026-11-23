import 'package:flutter/material.dart';

import '../common/app_colors.dart';

/// Hộp thoại hỗ trợ người dùng xác nhận kỳ báo cáo hệ thống tự động tính toán (Luồng 1)
/// Kiểm soát chặt chẽ:
/// 1. Tự động tính các kỳ hợp lệ từ thời điểm phát sinh hồ sơ/khoản vay đến hiện tại
/// 2. Không cho lập khống tương lai và không tạo trùng kỳ
class GenerateReportDialog extends StatefulWidget {
  final List<String> existingPeriods;
  final DateTime? earliestAllowedDate;
  final Future<bool> Function(String period) onConfirm;

  const GenerateReportDialog({
    super.key,
    this.existingPeriods = const [],
    this.earliestAllowedDate,
    required this.onConfirm,
  });

  static Future<void> show(
    BuildContext context, {
    List<String> existingPeriods = const [],
    DateTime? earliestAllowedDate,
    required Future<bool> Function(String period) onConfirm,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GenerateReportDialog(
        existingPeriods: existingPeriods,
        earliestAllowedDate: earliestAllowedDate,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<GenerateReportDialog> createState() => _GenerateReportDialogState();
}

class _GenerateReportDialogState extends State<GenerateReportDialog> {
  late final List<String> _availablePeriods;
  String? _selectedPeriod;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _availablePeriods = _computeAvailablePeriods(
      widget.existingPeriods,
      earliestAllowedDate: widget.earliestAllowedDate,
    );
    _selectedPeriod = _availablePeriods.isNotEmpty
        ? _availablePeriods.first
        : null;
  }

  /// Hệ thống tự tính toán danh sách các kỳ hợp lệ chưa được khởi tạo
  static List<String> _computeAvailablePeriods(
    List<String> existing, {
    DateTime? earliestAllowedDate,
  }) {
    final now = DateTime.now();
    final minDate = earliestAllowedDate != null
        ? DateTime(earliestAllowedDate.year, earliestAllowedDate.month, 1)
        : DateTime(now.year, now.month, 1);

    final List<String> periods = [];
    // Duyệt từ tháng hiện tại lùi về tối đa thời điểm phát sinh dữ liệu
    for (int i = 0; i < 12; i++) {
      final candidate = DateTime(now.year, now.month - i, 1);
      if (candidate.isBefore(minDate)) break;
      final str =
          '${candidate.year}-${candidate.month.toString().padLeft(2, '0')}';
      if (!existing.any((p) => p.trim() == str)) {
        periods.add(str);
      }
    }
    return periods;
  }

  String _formatPeriodLabel(String period) {
    final parts = period.split('-');
    if (parts.length == 2) {
      return 'Tháng ${parts[1]}/${parts[0]} ($period)';
    }
    return period;
  }

  void _handleSubmit() async {
    final period = _selectedPeriod;
    if (period == null || period.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    final success = await widget.onConfirm(period);
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hasAvailablePeriod = _availablePeriods.isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
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
              const Row(
                children: [
                  Icon(
                    Icons.add_chart_rounded,
                    color: AppColors.primary,
                    size: 24.0,
                  ),
                  SizedBox(width: 10.0),
                  Expanded(
                    child: Text(
                      'Lập báo cáo tín dụng kỳ mới',
                      style: TextStyle(
                        fontSize: 17.0,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              const Text(
                'Hệ thống tự động xác định kỳ báo cáo hợp lệ dựa trên thời điểm phát sinh hồ sơ và các kỳ bạn đã lưu.',
                style: TextStyle(
                  fontSize: 13.0,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16.0),

              if (!hasAvailablePeriod) ...[
                Container(
                  padding: const EdgeInsets.all(14.0),
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
                        size: 22.0,
                      ),
                      const SizedBox(width: 10.0),
                      Expanded(
                        child: Text(
                          'Bạn đã lập báo cáo đầy đủ đến kỳ hiện tại (Tháng ${now.month}/${now.year}). Kỳ báo cáo mới sẽ tự động mở khi bước sang tháng tiếp theo.',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF166534),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const Text(
                  'Kỳ báo cáo khả dụng',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8.0),
                if (_availablePeriods.length == 1)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14.0,
                      vertical: 14.0,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_rounded,
                          size: 20.0,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10.0),
                        Text(
                          _formatPeriodLabel(_selectedPeriod!),
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    initialValue: _selectedPeriod,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.calendar_month_rounded,
                        size: 20.0,
                        color: AppColors.primary,
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    items: _availablePeriods
                        .map(
                          (p) => DropdownMenuItem<String>(
                            value: p,
                            child: Text(_formatPeriodLabel(p)),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _selectedPeriod = val),
                  ),
              ],

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
                      child: const Text(
                        'Đóng',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  if (hasAvailablePeriod) ...[
                    const SizedBox(width: 12.0),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14.0),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20.0,
                                height: 20.0,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Khởi tạo báo cáo',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

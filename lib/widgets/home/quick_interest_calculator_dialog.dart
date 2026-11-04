import 'package:flutter/material.dart';

import '../widget.dart';

/// Hộp thoại tính nhanh tiền lãi & tiền trả hàng tháng theo số tiền, lãi suất, kỳ hạn
class QuickInterestCalculatorDialog extends StatefulWidget {
  const QuickInterestCalculatorDialog({super.key});

  /// Phương thức hiển thị dialog
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const QuickInterestCalculatorDialog(),
    );
  }

  @override
  State<QuickInterestCalculatorDialog> createState() =>
      _QuickInterestCalculatorDialogState();
}

class _QuickInterestCalculatorDialogState
    extends State<QuickInterestCalculatorDialog> {
  final _amountController = TextEditingController(text: '100000000');
  final _rateController = TextEditingController(text: '8.5');
  final _monthsController = TextEditingController(text: '24');
  double _estimatedMonthly = 4545000;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _rateController.dispose();
    _monthsController.dispose();
    super.dispose();
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

  void _calculate() {
    final double p = double.tryParse(_amountController.text) ?? 0;
    final double r = (double.tryParse(_rateController.text) ?? 0) / 100;
    final int m = int.tryParse(_monthsController.text) ?? 12;
    if (p > 0 && m > 0) {
      final double monthlyRate = r / 12;
      final double res = (p / m) + (p * monthlyRate);
      setState(() {
        _estimatedMonthly = res;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      title: const Row(
        children: [
          Icon(Icons.calculate_rounded, color: AppColors.primary),
          SizedBox(width: 8.0),
          Text(
            'Máy tính lãi suất nhanh',
            style: TextStyle(fontSize: 17.0, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Số tiền vay (VNĐ)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) => _calculate(),
            ),
            const SizedBox(height: 12.0),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _rateController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Lãi suất (%/năm)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => _calculate(),
                  ),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: TextField(
                    controller: _monthsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Kỳ hạn (tháng)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => _calculate(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ước tính trả hàng tháng:',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    _formatCurrency(_estimatedMonthly),
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../models/bank_account_model.dart';
import '../../models/user_model.dart';
import '../widget.dart';

/// Modal BottomSheet quản lý danh sách tài khoản ngân hàng liên kết
class BankAccountsSheet extends StatelessWidget {
  final AuthController authController;
  final UserModel? user;

  const BankAccountsSheet({super.key, required this.authController, this.user});

  /// Phương thức hiển thị danh sách tài khoản
  static Future<void> show(
    BuildContext context, {
    required AuthController authController,
    UserModel? user,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) =>
          BankAccountsSheet(authController: authController, user: user),
    );
  }

  String _maskAccountNumber(String accNum) {
    if (accNum.length <= 4) return accNum;
    final prefix = accNum.substring(0, 3);
    final suffix = accNum.substring(accNum.length - 4);
    return '$prefix••• •••• $suffix';
  }

  @override
  Widget build(BuildContext context) {
    final accounts = user?.bankAccounts ?? [];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 32.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
          const SizedBox(height: 16.0),
          const Text(
            'Tài khoản thụ hưởng & Trích nợ',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6.0),
          const Text(
            'Tài khoản chính chủ nhận giải ngân các khoản vay và thiết lập trích nợ tự động hàng tháng.',
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16.0),

          if (accounts.isEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: 24.0,
                horizontal: 16.0,
              ),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14.0),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.account_balance_outlined,
                    size: 40.0,
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                  ),
                  const SizedBox(height: 10.0),
                  const Text(
                    'Chưa liên kết tài khoản ngân hàng nào',
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  const Text(
                    'Vui lòng thêm tài khoản để nhận giải ngân tức thì khi hồ sơ vay được duyệt.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ...accounts.map((acc) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Container(
                  padding: const EdgeInsets.all(14.0),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14.0),
                    border: Border.all(
                      color: acc.isDefaultDisbursal
                          ? AppColors.primary
                          : AppColors.border,
                      width: acc.isDefaultDisbursal ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40.0,
                        height: 40.0,
                        decoration: const BoxDecoration(
                          color: AppColors.primarySoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.account_balance_rounded,
                          color: AppColors.primary,
                          size: 20.0,
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  acc.bankName,
                                  style: const TextStyle(
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                if (acc.isDefaultDisbursal) ...[
                                  const SizedBox(width: 6.0),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6.0,
                                      vertical: 2.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(6.0),
                                    ),
                                    child: const Text(
                                      'Mặc định giải ngân',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                                if (acc.isAutoDebit) ...[
                                  const SizedBox(width: 6.0),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6.0,
                                      vertical: 2.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(6.0),
                                    ),
                                    child: const Text(
                                      'Trích nợ tự động',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              _maskAccountNumber(acc.accountNumber),
                              style: const TextStyle(
                                fontSize: 13.0,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              acc.accountHolderName.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11.0,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.error,
                          size: 20.0,
                        ),
                        tooltip: 'Hủy liên kết',
                        onPressed: () {
                          authController.removeBankAccount(acc.id);
                          Navigator.pop(context);
                          AppSnackBar.showSuccess(
                            context,
                            'Đã hủy liên kết tài khoản ${acc.bankName}.',
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],

          const SizedBox(height: 16.0),

          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              AddBankAccountSheet.show(
                context,
                authController: authController,
                user: user,
              );
            },
            icon: const Icon(Icons.add_rounded, size: 20.0),
            label: const Text('Thêm tài khoản ngân hàng liên kết'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Modal BottomSheet thêm mới tài khoản ngân hàng liên kết
class AddBankAccountSheet extends StatefulWidget {
  final AuthController authController;
  final UserModel? user;

  const AddBankAccountSheet({
    super.key,
    required this.authController,
    this.user,
  });

  /// Phương thức hiển thị modal tiện ích
  static Future<void> show(
    BuildContext context, {
    required AuthController authController,
    UserModel? user,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) =>
          AddBankAccountSheet(authController: authController, user: user),
    );
  }

  @override
  State<AddBankAccountSheet> createState() => _AddBankAccountSheetState();
}

class _AddBankAccountSheetState extends State<AddBankAccountSheet> {
  String _selectedBank = 'Techcombank';
  late final TextEditingController _accountNumController;
  late final TextEditingController _holderNameController;
  late bool _isDefaultDisbursal;
  bool _isAutoDebit = false;
  final _formKey = GlobalKey<FormState>();

  static const _popularBanks = [
    'Techcombank',
    'Vietcombank',
    'MBBank',
    'BIDV',
    'VietinBank',
    'VPBank',
    'ACB',
    'TPBank',
  ];

  @override
  void initState() {
    super.initState();
    _accountNumController = TextEditingController();
    _holderNameController = TextEditingController(
      text: (widget.user?.fullName.isNotEmpty == true)
          ? widget.user!.fullName.toUpperCase()
          : 'CHỦ TÀI KHOẢN',
    );
    _isDefaultDisbursal = widget.user?.bankAccounts.isEmpty ?? true;
  }

  @override
  void dispose() {
    _accountNumController.dispose();
    _holderNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20.0,
        right: 20.0,
        top: 20.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              const SizedBox(height: 16.0),
              const Text(
                'Liên kết tài khoản ngân hàng',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6.0),
              const Text(
                'Tài khoản cần là tài khoản chính chủ để đảm bảo tính pháp lý khi nhận giải ngân Napas 24/7.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16.0),

              // Chọn ngân hàng
              const Text(
                'Ngân hàng thụ hưởng',
                style: TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8.0),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _popularBanks.map((bank) {
                  final isSelected = _selectedBank == bank;
                  return ChoiceChip(
                    label: Text(bank),
                    selected: isSelected,
                    selectedColor: AppColors.primarySoft,
                    backgroundColor: AppColors.background,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 12.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedBank = bank);
                      }
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 16.0),

              AppTextField(
                label: 'Số tài khoản ngân hàng',
                hint: 'Ví dụ: 190382918888',
                controller: _accountNumController,
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(
                  Icons.numbers_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                validator: (val) {
                  if (val == null || val.trim().length < 6) {
                    return 'Số tài khoản không hợp lệ (tối thiểu 6 số)';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 14.0),

              AppTextField(
                label: 'Tên chủ tài khoản (Viết in hoa, không dấu)',
                hint: 'NGUYEN VAN DEV',
                controller: _holderNameController,
                prefixIcon: const Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                validator: (val) {
                  if (val == null || val.trim().length < 3) {
                    return 'Vui lòng nhập tên chủ tài khoản';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 10.0),

              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.primary,
                title: const Text(
                  'Đặt làm tài khoản nhận giải ngân mặc định',
                  style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Mọi khoản vay được giải ngân tự động về tài khoản này',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                value: _isDefaultDisbursal,
                onChanged: (val) {
                  setState(() => _isDefaultDisbursal = val ?? false);
                },
              ),

              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.primary,
                title: const Text(
                  'Cho phép trích nợ tự động hàng tháng (Auto-debit)',
                  style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Tự động thanh toán các kỳ nợ đến hạn để tránh phát sinh nợ quá hạn',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                value: _isAutoDebit,
                onChanged: (val) {
                  setState(() => _isAutoDebit = val ?? false);
                },
              ),

              const SizedBox(height: 16.0),

              AppPrimaryButton(
                label: 'Xác nhận liên kết tài khoản',
                onPressed: () {
                  if (!_formKey.currentState!.validate()) {
                    return;
                  }
                  final newAcc = BankAccountModel(
                    id: 'bank_${DateTime.now().millisecondsSinceEpoch}',
                    bankName: _selectedBank,
                    accountNumber: _accountNumController.text.trim(),
                    accountHolderName: _holderNameController.text
                        .trim()
                        .toUpperCase(),
                    isDefaultDisbursal: _isDefaultDisbursal,
                    isAutoDebit: _isAutoDebit,
                  );

                  widget.authController.addBankAccount(newAcc);
                  Navigator.pop(context);
                  AppSnackBar.showSuccess(
                    context,
                    'Đã liên kết tài khoản $_selectedBank thành công!',
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

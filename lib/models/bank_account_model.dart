class BankAccountModel {
  final String id;
  final String bankName;
  final String accountNumber;
  final String accountHolderName;
  final bool isDefaultDisbursal;
  final bool isAutoDebit;

  const BankAccountModel({
    required this.id,
    required this.bankName,
    required this.accountNumber,
    required this.accountHolderName,
    this.isDefaultDisbursal = false,
    this.isAutoDebit = false,
  });

  factory BankAccountModel.fromJson(Map<String, dynamic> json) {
    return BankAccountModel(
      id: json['id']?.toString() ?? '',
      bankName:
          json['bank_name']?.toString() ?? json['bankName']?.toString() ?? '',
      accountNumber:
          json['account_number']?.toString() ??
          json['accountNumber']?.toString() ??
          '',
      accountHolderName:
          json['account_holder_name']?.toString() ??
          json['accountHolderName']?.toString() ??
          '',
      isDefaultDisbursal:
          (json['is_default_disbursal'] ?? json['isDefaultDisbursal'])
              as bool? ??
          false,
      isAutoDebit:
          (json['is_auto_debit'] ?? json['isAutoDebit']) as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'bank_name': bankName,
    'account_number': accountNumber,
    'account_holder_name': accountHolderName,
    'is_default_disbursal': isDefaultDisbursal,
    'is_auto_debit': isAutoDebit,
  };
}

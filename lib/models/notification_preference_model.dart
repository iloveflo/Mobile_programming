class NotificationPreferenceModel {
  final int id;
  final int userId;
  final bool pushEnabled;
  final bool emailEnabled;
  final bool balanceFluctuationEnabled;
  final bool monthlyStatementEnabled;
  final int reminderDays;
  final DateTime? updatedAt;

  const NotificationPreferenceModel({
    required this.id,
    required this.userId,
    required this.pushEnabled,
    required this.emailEnabled,
    required this.reminderDays,
    this.balanceFluctuationEnabled = true,
    this.monthlyStatementEnabled = true,
    this.updatedAt,
  });

  factory NotificationPreferenceModel.fromJson(Map<String, dynamic> json) {
    return NotificationPreferenceModel(
      id: json['preference_id'] as int,
      userId: json['user_id'] as int,
      pushEnabled: json['push_enabled'] as bool? ?? true,
      emailEnabled: json['email_enabled'] as bool? ?? true,
      balanceFluctuationEnabled:
          json['balance_fluctuation_enabled'] as bool? ?? true,
      monthlyStatementEnabled:
          json['monthly_statement_enabled'] as bool? ?? true,
      reminderDays: json['reminder_days'] as int? ?? 3,
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'preference_id': id,
    'user_id': userId,
    'push_enabled': pushEnabled,
    'email_enabled': emailEnabled,
    'balance_fluctuation_enabled': balanceFluctuationEnabled,
    'monthly_statement_enabled': monthlyStatementEnabled,
    'reminder_days': reminderDays,
    'updated_at': updatedAt?.toIso8601String(),
  };

  NotificationPreferenceModel copyWith({
    int? id,
    int? userId,
    bool? pushEnabled,
    bool? emailEnabled,
    bool? balanceFluctuationEnabled,
    bool? monthlyStatementEnabled,
    int? reminderDays,
    DateTime? updatedAt,
  }) {
    return NotificationPreferenceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      balanceFluctuationEnabled:
          balanceFluctuationEnabled ?? this.balanceFluctuationEnabled,
      monthlyStatementEnabled:
          monthlyStatementEnabled ?? this.monthlyStatementEnabled,
      reminderDays: reminderDays ?? this.reminderDays,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

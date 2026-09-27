class NotificationPreferenceModel {
  final int id;
  final int userId;
  final bool pushEnabled;
  final bool emailEnabled;
  final bool smsEnabled;
  final int reminderDays;
  final DateTime? updatedAt;

  const NotificationPreferenceModel({
    required this.id,
    required this.userId,
    required this.pushEnabled,
    required this.emailEnabled,
    required this.smsEnabled,
    required this.reminderDays,
    this.updatedAt,
  });

  factory NotificationPreferenceModel.fromJson(Map<String, dynamic> json) {
    return NotificationPreferenceModel(
      id: json['preference_id'] as int,
      userId: json['user_id'] as int,
      pushEnabled: json['push_enabled'] as bool? ?? true,
      emailEnabled: json['email_enabled'] as bool? ?? true,
      smsEnabled: json['sms_enabled'] as bool? ?? false,
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
    'sms_enabled': smsEnabled,
    'reminder_days': reminderDays,
    'updated_at': updatedAt?.toIso8601String(),
  };
}

import '../models/notification_preference_model.dart';

class NotificationPreferenceMockData {
  static final List<NotificationPreferenceModel>
  notificationPreferencesDatabase = [
    NotificationPreferenceModel(
      id: 1,
      userId: 1,
      pushEnabled: true,
      emailEnabled: true,
      smsEnabled: false,
      reminderDays: 3,
      updatedAt: DateTime(2026, 9, 1, 8, 15),
    ),
  ];
}

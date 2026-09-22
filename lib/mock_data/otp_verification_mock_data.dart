import '../models/otp_verification_model.dart';

class OtpVerificationMockData {
  static final List<OtpVerificationModel> otpVerificationsDatabase = [
    OtpVerificationModel(
      id: 1,
      userId: 1,
      code: '123456',
      purpose: 'EMAIL_VERIFICATION',
      expiresAt: DateTime(2026, 9, 22, 10, 5),
      verifiedAt: DateTime(2026, 9, 22, 9, 57),
      status: 'VERIFIED',
      createdAt: DateTime(2026, 9, 22, 9, 55),
    ),
  ];
}

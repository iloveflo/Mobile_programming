/// Mô hình dữ liệu gửi yêu cầu đăng ký tài khoản FinCredit
class RegisterRequestModel {
  final String fullName;
  final String email;
  final String phone;
  final DateTime? dateOfBirth;
  final String password;
  final bool agreeToTerms;

  const RegisterRequestModel({
    required this.fullName,
    required this.email,
    required this.phone,
    this.dateOfBirth,
    required this.password,
    this.agreeToTerms = false,
  });

  Map<String, dynamic> toJson() => {
    'full_name': fullName,
    'email': email,
    'phone': phone,
    'date_of_birth': dateOfBirth?.toIso8601String(),
    'password': password,
    'agree_to_terms': agreeToTerms,
  };
}

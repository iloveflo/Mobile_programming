/// Lớp tiện ích cung cấp các quy tắc kiểm tra (validation) dữ liệu biểu mẫu chuẩn hóa cho FinCredit
class AppValidators {
  AppValidators._();

  /// Biểu thức chính quy kiểm tra định dạng Email chuẩn RFC 5322 cơ bản
  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
  );

  /// Biểu thức chính quy kiểm tra số điện thoại Việt Nam chuẩn (10 chữ số bắt đầu bằng 03, 05, 07, 08, 09)
  static final RegExp _vnPhoneRegExp = RegExp(
    r'^(0)(3[2-9]|5[25689]|7[06-9]|8[1-9]|9[0-9])[0-9]{7}$',
  );

  /// Biểu thức chính quy kiểm tra CCCD 12 chữ số hoặc CMND 9 chữ số
  static final RegExp _idCardRegExp = RegExp(r'^[0-9]{9}$|^[0-9]{12}$');

  /// Biểu thức chính quy kiểm tra số tài khoản ngân hàng (6 đến 20 ký tự số)
  static final RegExp _bankAccountRegExp = RegExp(r'^[0-9]{6,20}$');

  /// 1. Kiểm tra trường bắt buộc không được để trống
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName không được để trống';
    }
    return null;
  }

  /// 2. Kiểm tra họ và tên hợp lệ (tối thiểu 2 ký tự, không chứa ký tự đặc biệt)
  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập họ và tên';
    }
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return 'Họ và tên phải có tối thiểu 2 ký tự';
    }
    if (trimmed.length > 70) {
      return 'Họ và tên không được vượt quá 70 ký tự';
    }
    // Không chứa số hoặc ký tự đặc biệt không hợp lệ trong tên người
    if (RegExp(r'[0-9!@#\$%^&*()_+={}\[\]:;"<>,.?/\\|`~]').hasMatch(trimmed)) {
      return 'Họ và tên không được chứa số hoặc ký tự đặc biệt';
    }
    return null;
  }

  /// 3. Kiểm tra định dạng Email
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập địa chỉ email';
    }
    final trimmed = value.trim();
    if (!_emailRegExp.hasMatch(trimmed)) {
      return 'Định dạng email không hợp lệ (ví dụ: name@example.com)';
    }
    return null;
  }

  /// 4. Kiểm tra số điện thoại Việt Nam
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập số điện thoại';
    }
    final cleanPhone = value.replaceAll(RegExp(r'[\s\.\-]'), '');
    if (!_vnPhoneRegExp.hasMatch(cleanPhone)) {
      return 'Số điện thoại không hợp lệ (cần 10 số, ví dụ: 0912345678)';
    }
    return null;
  }

  /// 5. Kiểm tra mã định danh đăng nhập (Email hoặc SĐT hoặc Mã CIC)
  static String? validateIdentifier(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập Email, Số điện thoại hoặc Mã CIC';
    }
    final trimmed = value.trim();
    if (trimmed.contains('@')) {
      return validateEmail(trimmed);
    }
    // Nếu toàn số -> kiểm tra độ dài số điện thoại hoặc mã định danh
    if (RegExp(r'^[0-9]+$').hasMatch(trimmed)) {
      if (trimmed.length < 8 || trimmed.length > 15) {
        return 'Số điện thoại hoặc mã CIC cần từ 8 đến 15 số';
      }
      return null;
    }
    if (trimmed.length < 3) {
      return 'Mã định danh tối thiểu 3 ký tự';
    }
    return null;
  }

  /// 6. Kiểm tra mật khẩu tài khoản
  /// Yêu cầu: Tối thiểu 8 ký tự, gồm ít nhất 1 chữ cái và 1 chữ số
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    if (value.length < 8) {
      return 'Mật khẩu phải từ 8 ký tự trở lên';
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(value)) {
      return 'Mật khẩu phải chứa ít nhất một chữ cái';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Mật khẩu phải chứa ít nhất một chữ số';
    }
    return null;
  }

  /// 7. Kiểm tra xác nhận mật khẩu
  static String? validateConfirmPassword(
    String? value,
    String originalPassword,
  ) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập lại mật khẩu để xác nhận';
    }
    if (value != originalPassword) {
      return 'Mật khẩu xác nhận không khớp';
    }
    return null;
  }

  /// 8. Kiểm tra số CCCD / CMND
  static String? validateIdCard(String? value, {bool required = false}) {
    if (value == null || value.trim().isEmpty) {
      if (required) {
        return 'Vui lòng nhập số CCCD gắn chip (12 số)';
      }
      return null;
    }
    final clean = value.replaceAll(RegExp(r'[\s\.\-]'), '');
    if (!_idCardRegExp.hasMatch(clean)) {
      return 'Số CCCD gắn chip không hợp lệ (chuẩn 12 chữ số)';
    }
    return null;
  }

  /// 9. Kiểm tra thu nhập hàng tháng
  static String? validateMonthlyIncome(
    String? value, {
    double min = 1000000,
    double max = 10000000000,
    bool required = false,
  }) {
    if (value == null || value.trim().isEmpty) {
      if (required) {
        return 'Vui lòng nhập thu nhập hàng tháng';
      }
      return null;
    }
    final clean = value.replaceAll('.', '').replaceAll(',', '').trim();
    final num = double.tryParse(clean);
    if (num == null) {
      return 'Số tiền thu nhập không hợp lệ';
    }
    if (num < min) {
      return 'Thu nhập tối thiểu là 1.000.000 VNĐ / tháng';
    }
    if (num > max) {
      return 'Thu nhập tối đa là 10.000.000.000 VNĐ / tháng';
    }
    return null;
  }

  /// 10. Kiểm tra số tài khoản ngân hàng
  static String? validateBankAccountNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập số tài khoản ngân hàng';
    }
    final clean = value.replaceAll(RegExp(r'[\s\-]'), '');
    if (!_bankAccountRegExp.hasMatch(clean)) {
      return 'Số tài khoản không hợp lệ (từ 6 đến 20 chữ số)';
    }
    return null;
  }

  /// 11. Kiểm tra tên chủ tài khoản thụ hưởng
  static String? validateAccountHolderName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập tên chủ tài khoản';
    }
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return 'Tên chủ tài khoản quá ngắn';
    }
    if (RegExp(r'[0-9!@#\$%^&*()_+={}\[\]:;"<>,.?/\\|`~]').hasMatch(trimmed)) {
      return 'Tên chủ tài khoản không được chứa số hoặc ký tự đặc biệt';
    }
    return null;
  }

  /// 12. Kiểm tra tên khoản vay
  static String? validateLoanName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập tên hoặc mục đích khoản vay';
    }
    final trimmed = value.trim();
    if (trimmed.length < 3) {
      return 'Tên khoản vay cần từ 3 ký tự trở lên';
    }
    if (trimmed.length > 100) {
      return 'Tên khoản vay không được vượt quá 100 ký tự';
    }
    return null;
  }

  /// 13. Kiểm tra số tiền vay
  static String? validateLoanAmount(
    String? value, {
    double min = 5000000,
    double max = 50000000000,
  }) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập số tiền vay';
    }
    final clean = value.replaceAll('.', '').replaceAll(',', '').trim();
    final num = double.tryParse(clean);
    if (num == null) {
      return 'Số tiền vay không hợp lệ';
    }
    if (num < min) {
      return 'Số tiền vay tối thiểu là 5.000.000 VNĐ (5 triệu)';
    }
    if (num > max) {
      return 'Số tiền vay tối đa là 50.000.000.000 VNĐ (50 tỷ)';
    }
    return null;
  }

  /// 14. Kiểm tra tên tài sản bảo đảm
  static String? validateCollateralName(String? value, {bool required = true}) {
    if (value == null || value.trim().isEmpty) {
      if (required) {
        return 'Vui lòng nhập tên tài sản bảo đảm';
      }
      return null;
    }
    final trimmed = value.trim();
    if (trimmed.length < 3) {
      return 'Tên tài sản cần tối thiểu 3 ký tự';
    }
    return null;
  }

  /// 15. Kiểm tra giá trị định giá tài sản bảo đảm
  static String? validateCollateralValue(
    String? value, {
    required double min,
    required double max,
    required String displayName,
    required String minFormatted,
    required String maxFormatted,
    bool required = true,
  }) {
    if (value == null || value.trim().isEmpty) {
      if (required) {
        return 'Vui lòng nhập giá trị định giá của $displayName';
      }
      return null;
    }
    final clean = value.replaceAll('.', '').replaceAll(',', '').trim();
    final val = double.tryParse(clean);
    if (val == null) {
      return 'Giá trị định giá không hợp lệ';
    }
    if (val < min) {
      return 'Định giá tối thiểu cho $displayName là $minFormatted';
    }
    if (val > max) {
      return 'Định giá tối đa cho $displayName là $maxFormatted';
    }
    return null;
  }
}

import 'dart:io' show Platform;
import 'dart:math';

import '../../mock_data/refresh_token_mock_data.dart';
import '../../mock_data/user_mock_data.dart';
import '../../models/auth_token_model.dart';
import '../../models/bank_account_model.dart';
import '../../models/session_model.dart';
import '../../models/user_model.dart';
import '../interfaces/auth_repository.dart';

/// Triển khai giả lập của AuthRepository phục vụ phát triển Frontend và kiểm thử nghiệp vụ
class MockAuthRepository implements AuthRepository {
  /// Cờ giả lập lỗi mạng phục vụ Dev/QA kiểm thử
  bool simulateNetworkError;

  // Trạng thái bộ nhớ nội bộ (In-Memory State)
  int _failedPasswordAttempts = 0;
  int _failedOtpAttempts = 0;
  DateTime? _lockUntil;

  UserModel? _currentUser;
  AuthTokenModel? _currentToken;
  final Map<int, List<SessionModel>> _userSessions = {};

  MockAuthRepository({this.simulateNetworkError = false}) {
    _initMockSessions();
  }

  String _getDeviceName() {
    try {
      if (Platform.isAndroid) return 'Thiết bị Android (Điện thoại)';
      if (Platform.isIOS) return 'iPhone (Thiết bị này)';
      if (Platform.isMacOS) return 'MacBook Pro';
      if (Platform.isWindows) return 'Windows PC';
      if (Platform.isLinux) return 'Linux Device';
    } catch (_) {}
    return 'Thiết bị di động hiện tại';
  }

  String _getPlatformName() {
    try {
      if (Platform.isAndroid) return 'Android 14 • FinCredit App';
      if (Platform.isIOS) return 'iOS 17.5 • FinCredit App';
      if (Platform.isMacOS) return 'macOS • FinCredit App';
      if (Platform.isWindows) return 'Windows 11 • FinCredit Web';
      if (Platform.isLinux) return 'Linux • FinCredit App';
    } catch (_) {}
    return 'Mobile • FinCredit App';
  }

  void _initMockSessions() {
    _userSessions.clear();
    // Tài khoản dev mẫu (userId == 1) có 3 phiên phục vụ kiểm thử tính năng thu hồi thiết bị
    _userSessions[1] = [
      SessionModel(
        id: 'sess_current',
        deviceName: 'iPhone 15 Pro Max',
        platform: 'iOS 17.5 • FinCredit App',
        ipAddress: '113.161.45.12',
        location: 'TP. Hồ Chí Minh, Việt Nam',
        lastActive: DateTime.now(),
        isCurrent: true,
      ),
      SessionModel(
        id: 'sess_macbook',
        deviceName: 'MacBook Pro 16" M3',
        platform: 'macOS Sonoma • Chrome 128',
        ipAddress: '113.161.45.12',
        location: 'TP. Hồ Chí Minh, Việt Nam',
        lastActive: DateTime.now().subtract(const Duration(hours: 3)),
        isCurrent: false,
      ),
      SessionModel(
        id: 'sess_samsung',
        deviceName: 'Samsung Galaxy S24 Ultra',
        platform: 'Android 14 • OneUI 6.1',
        ipAddress: '14.232.208.9',
        location: 'Hà Nội, Việt Nam',
        lastActive: DateTime.now().subtract(const Duration(days: 2)),
        isCurrent: false,
      ),
    ];
  }

  /// Đã loại bỏ hoàn toàn độ trễ giả lập để phản hồi tức thì
  Future<void> _simulateDelay([int minMs = 0, int maxMs = 0]) async {
    if (simulateNetworkError) {
      throw const NetworkAuthException(
        'Mất kết nối mạng. Vui lòng kiểm tra Wifi/4G.',
      );
    }
    return;
  }

  @override
  Future<AuthTokenModel?> checkSession() async {
    await _simulateDelay(400, 700);

    if (_currentToken != null && !_currentToken!.isExpired) {
      return _currentToken;
    }

    // Kiểm tra token mẫu từ RefreshTokenMockData
    if (RefreshTokenMockData.refreshTokensDatabase.isNotEmpty) {
      final sample = RefreshTokenMockData.refreshTokensDatabase.first;
      if (sample.revokedAt == null &&
          DateTime.now().isBefore(sample.expiresAt)) {
        _currentToken = AuthTokenModel(
          accessToken: 'mock_jwt_access_token_${sample.userId}',
          refreshToken: sample.token,
          expiresAt: sample.expiresAt,
          userId: sample.userId,
        );
        // Gán user mẫu
        _currentUser = UserMockData.usersDatabase.firstWhere(
          (u) => u.userId == sample.userId,
          orElse: () => UserMockData.usersDatabase.first,
        );
        return _currentToken;
      }
    }

    return null;
  }

  @override
  Future<UserModel> login({
    required String identifier,
    required String password,
  }) async {
    await _simulateDelay();

    final trimmedId = identifier.trim();

    // 1. Kiểm tra tài khoản có đang bị khóa bởi thời gian hay không
    if (_lockUntil != null && DateTime.now().isBefore(_lockUntil!)) {
      final diff = _lockUntil!.difference(DateTime.now()).inMinutes + 1;
      throw AccountLockedException(
        'Tài khoản đang bị tạm khóa. Vui lòng thử lại sau $diff phút.',
        lockUntil: _lockUntil,
      );
    }

    // 2. Kịch bản Mock: Tài khoản bị khóa (locked@...)
    if (trimmedId.toLowerCase().contains('locked')) {
      _lockUntil = DateTime.now().add(const Duration(minutes: 15));
      throw AccountLockedException(
        'Khóa đăng nhập 15 phút do phát hiện hành vi bất thường.',
        lockUntil: _lockUntil,
      );
    }

    // 3. Kịch bản Mock: Tài khoản chưa kích hoạt (unverified@...)
    if (trimmedId.toLowerCase().contains('unverified')) {
      throw AccountUnverifiedException(
        trimmedId,
        phone: '0900000001',
        message:
            'Tài khoản chưa được kích hoạt. Vui lòng hoàn tất xác thực OTP.',
      );
    }

    // 4. Tìm kiếm tài khoản trong Database giả lập
    final user = UserMockData.usersDatabase.cast<UserModel?>().firstWhere(
      (u) =>
          (u?.email.toLowerCase() == trimmedId.toLowerCase() ||
              u?.phone == trimmedId) &&
          u?.passwordHash == password,
      orElse: () => null,
    );

    if (user != null) {
      _failedPasswordAttempts = 0;
      _lockUntil = null;
      _currentUser = user;
      if (user.userId != 1 && !_userSessions.containsKey(user.userId)) {
        _userSessions[user.userId] = [
          SessionModel(
            id: 'sess_${user.userId}_current',
            deviceName: _getDeviceName(),
            platform: _getPlatformName(),
            ipAddress: '113.161.45.12',
            location: 'TP. Hồ Chí Minh, Việt Nam',
            lastActive: DateTime.now(),
            isCurrent: true,
          ),
        ];
      }
      _currentToken = AuthTokenModel(
        accessToken: 'mock_jwt_access_token_${user.userId}',
        refreshToken: 'mock_jwt_refresh_token_${user.userId}',
        userId: user.userId,
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );
      return user;
    }

    // 5. Xử lý khi sai mật khẩu -> tăng đếm
    _failedPasswordAttempts++;
    if (_failedPasswordAttempts >= 5) {
      _lockUntil = DateTime.now().add(const Duration(minutes: 15));
      throw AccountLockedException(
        'Khóa đăng nhập 15 phút do nhập sai quá 5 lần',
        lockUntil: _lockUntil,
      );
    }

    throw const InvalidCredentialsException(
      'Thông tin đăng nhập không hợp lệ.',
    );
  }

  @override
  Future<void> register(Map<String, dynamic> registerData) async {
    await _simulateDelay();

    final email = (registerData['email'] ?? '').toString().trim();
    final isExist = UserMockData.usersDatabase.any(
      (u) => u.email.toLowerCase() == email.toLowerCase(),
    );

    if (isExist) {
      throw Exception('Email này đã được sử dụng trên hệ thống FinCredit!');
    }

    final newUser = UserModel(
      userId: DateTime.now().millisecondsSinceEpoch,
      fullName:
          (registerData['full_name'] ??
                  registerData['fullName'] ??
                  'Người Dùng Mới')
              .toString(),
      email: email,
      phone: (registerData['phone'] ?? '').toString(),
      passwordHash: (registerData['password'] ?? '').toString(),
      dateOfBirth: registerData['date_of_birth'] != null
          ? DateTime.tryParse(registerData['date_of_birth'].toString())
          : null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      token: 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}',
    );

    UserMockData.usersDatabase.add(newUser);
    _currentUser = newUser;
    _userSessions[newUser.userId] = [
      SessionModel(
        id: 'sess_${newUser.userId}_current',
        deviceName: _getDeviceName(),
        platform: _getPlatformName(),
        ipAddress: '113.161.45.12',
        location: 'TP. Hồ Chí Minh, Việt Nam',
        lastActive: DateTime.now(),
        isCurrent: true,
      ),
    ];
  }

  @override
  Future<bool> verifyOtp({
    required String otp,
    required String flowType,
  }) async {
    await _simulateDelay();

    // Trường hợp mã đã hết hạn
    if (otp == '000000') {
      throw const OtpException('Mã OTP đã hết hạn', isExpired: true);
    }

    // Trường hợp mã chính xác
    if (otp == '123456') {
      _failedOtpAttempts = 0;
      return true;
    }

    // Các mã khác -> sai
    _failedOtpAttempts++;
    final remaining = max(0, 5 - _failedOtpAttempts);

    if (_failedOtpAttempts >= 5) {
      throw const OtpException(
        'Tạm khóa xác thực 15 phút',
        isExpired: false,
        remainingAttempts: 0,
      );
    }

    throw OtpException(
      'Mã OTP không chính xác. Còn $remaining lần thử',
      remainingAttempts: remaining,
      isExpired: false,
    );
  }

  @override
  Future<void> resendOtp() async {
    await _simulateDelay();
    // Giả lập reset bộ đếm thử lại cho mã OTP mới
    _failedOtpAttempts = 0;
  }

  @override
  Future<void> resetPassword({required String newPassword}) async {
    await _simulateDelay();

    if (_currentUser != null) {
      final index = UserMockData.usersDatabase.indexWhere(
        (u) => u.userId == _currentUser!.userId,
      );
      if (index != -1) {
        final current = UserMockData.usersDatabase[index];
        UserMockData.usersDatabase[index] = UserModel(
          userId: current.userId,
          fullName: current.fullName,
          email: current.email,
          phone: current.phone,
          passwordHash: newPassword,
          monthlyIncome: current.monthlyIncome,
          dateOfBirth: current.dateOfBirth,
          createdAt: current.createdAt,
          updatedAt: DateTime.now(),
          token: current.token,
        );
      }
    }

    // Thu hồi các phiên khác, chỉ giữ lại phiên hiện tại
    final uid = _currentUser?.userId ?? 1;
    _userSessions[uid]?.removeWhere((s) => !s.isCurrent);
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _simulateDelay();

    if (_currentUser != null && _currentUser!.passwordHash != currentPassword) {
      throw const InvalidCredentialsException(
        'Mật khẩu hiện tại không chính xác.',
      );
    }

    await resetPassword(newPassword: newPassword);
  }

  @override
  Future<List<SessionModel>> getActiveSessions() async {
    await _simulateDelay(300, 600);
    final uid = _currentUser?.userId ?? 1;

    if (!_userSessions.containsKey(uid) || _userSessions[uid]!.isEmpty) {
      _userSessions[uid] = [
        SessionModel(
          id: 'sess_${uid}_current',
          deviceName: _getDeviceName(),
          platform: _getPlatformName(),
          ipAddress: '113.161.45.12',
          location: 'TP. Hồ Chí Minh, Việt Nam',
          lastActive: DateTime.now(),
          isCurrent: true,
        ),
      ];
    }

    return List<SessionModel>.from(_userSessions[uid]!);
  }

  @override
  Future<void> revokeSession(String sessionId) async {
    await _simulateDelay(400, 800);
    final uid = _currentUser?.userId ?? 1;
    _userSessions[uid]?.removeWhere((s) => s.id == sessionId);
  }

  @override
  Future<UserModel> getProfile() async {
    await _simulateDelay();
    if (_currentUser != null) {
      return _currentUser!;
    }
    if (UserMockData.usersDatabase.isNotEmpty) {
      _currentUser = UserMockData.usersDatabase.first;
      return _currentUser!;
    }
    throw const InvalidCredentialsException('Không tìm thấy thông tin hồ sơ.');
  }

  @override
  Future<UserModel> updateProfile(Map<String, dynamic> profileData) async {
    await _simulateDelay();
    final base = _currentUser ?? UserMockData.usersDatabase.first;

    final updated = base.copyWith(
      fullName:
          profileData['full_name']?.toString() ??
          profileData['fullName']?.toString() ??
          base.fullName,
      phone: profileData['phone']?.toString() ?? base.phone,
      monthlyIncome:
          (profileData['monthly_income'] ??
                  profileData['monthlyIncome'] as num?)
              ?.toDouble() ??
          base.monthlyIncome,
      idCardNumber:
          profileData['id_card_number']?.toString() ??
          profileData['idCardNumber']?.toString() ??
          base.idCardNumber,
      address: profileData['address']?.toString() ?? base.address,
      occupation: profileData['occupation']?.toString() ?? base.occupation,
      workplace: profileData['workplace']?.toString() ?? base.workplace,
      contractType:
          profileData['contract_type']?.toString() ??
          profileData['contractType']?.toString() ??
          base.contractType,
      isEkycVerified:
          profileData['is_ekyc_verified'] as bool? ??
          profileData['isEkycVerified'] as bool? ??
          base.isEkycVerified,
      ekycTier:
          profileData['ekyc_tier']?.toString() ??
          profileData['ekycTier']?.toString() ??
          base.ekycTier,
      membershipTier:
          profileData['membership_tier']?.toString() ??
          profileData['membershipTier']?.toString() ??
          base.membershipTier,
      cicScore:
          (profileData['cic_score'] ?? profileData['cicScore'] as num?)
              ?.toInt() ??
          base.cicScore,
      updatedAt: DateTime.now(),
    );

    _currentUser = updated;
    final index = UserMockData.usersDatabase.indexWhere(
      (u) => u.userId == updated.userId,
    );
    if (index != -1) {
      UserMockData.usersDatabase[index] = updated;
    }
    return updated;
  }

  @override
  Future<List<BankAccountModel>> getBankAccounts() async {
    await _simulateDelay();
    return _currentUser?.bankAccounts ?? [];
  }

  @override
  Future<BankAccountModel> addBankAccount(
    Map<String, dynamic> accountData,
  ) async {
    await _simulateDelay();
    final newAccount = BankAccountModel.fromJson(accountData);
    final user = _currentUser ?? UserMockData.usersDatabase.first;
    final updatedList = List<BankAccountModel>.from(user.bankAccounts)
      ..removeWhere((a) => a.id == newAccount.id)
      ..add(newAccount);

    _currentUser = user.copyWith(bankAccounts: updatedList);
    final index = UserMockData.usersDatabase.indexWhere(
      (u) => u.userId == user.userId,
    );
    if (index != -1) {
      UserMockData.usersDatabase[index] = _currentUser!;
    }
    return newAccount;
  }

  @override
  Future<void> deleteBankAccount(String accountId) async {
    await _simulateDelay();
    if (_currentUser != null) {
      final updatedList = _currentUser!.bankAccounts
          .where((a) => a.id != accountId)
          .toList();
      _currentUser = _currentUser!.copyWith(bankAccounts: updatedList);
      final index = UserMockData.usersDatabase.indexWhere(
        (u) => u.userId == _currentUser!.userId,
      );
      if (index != -1) {
        UserMockData.usersDatabase[index] = _currentUser!;
      }
    }
  }

  @override
  Future<void> logout() async {
    await _simulateDelay(300, 500);
    _currentUser = null;
    _currentToken = null;
    _failedPasswordAttempts = 0;
    _failedOtpAttempts = 0;
  }
}

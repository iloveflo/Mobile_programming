import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import '../mock_data/user_mock_data.dart';
import '../models/bank_account_model.dart';
import '../models/register_request_model.dart';
import '../models/session_model.dart';
import '../models/user_model.dart';
import '../repositories/interfaces/auth_repository.dart';
import '../widgets/dev_state_panel.dart';
import 'loan_controller.dart';

/// Kết quả của thao tác đăng nhập
enum AuthResultState { success, unverified, locked, invalid }

/// Luồng xác thực mã OTP
enum OtpFlow { register, forgotPassword }

/// Bộ điều khiển xác thực người dùng trung tâm (AuthController)
class AuthController extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthController(this._authRepository);

  // ================= Quản lý Trạng thái =================
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  List<SessionModel> _activeSessions = [];

  // ================= Cài đặt & Tùy chọn =================
  bool _rememberMe = true;
  bool _biometricEnabled = true;

  // ================= Trạng thái OTP & Khóa tài khoản =================
  int _otpCountdown = 105; // 105 giây ~ 01:45
  int _remainingResendAttempts = 3;
  int _failedOtpAttempts = 0;
  Timer? _otpTimer;

  String? _pendingFullName;
  String? _pendingEmail;
  String? _pendingPhone;
  OtpFlow? _pendingFlow;
  DateTime? _lockUntil;

  // ================= Getters =================
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<SessionModel> get activeSessions => List.unmodifiable(_activeSessions);

  bool get rememberMe => _rememberMe;
  bool get biometricEnabled => _biometricEnabled;
  bool get isBiometricEnabled => _biometricEnabled;

  int get otpCountdown => _otpCountdown;
  int get remainingResendAttempts => _remainingResendAttempts;
  int get failedOtpAttempts => _failedOtpAttempts;
  String? get pendingFullName => _pendingFullName;
  String? get pendingEmail => _pendingEmail;
  String? get pendingPhone => _pendingPhone;
  OtpFlow? get pendingFlow => _pendingFlow;

  /// Hiển thị thời gian đếm ngược dạng MM:SS (ví dụ 01:45)
  String get formattedCountdown {
    final minutes = (_otpCountdown ~/ 60).toString().padLeft(2, '0');
    final seconds = (_otpCountdown % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Cho phép gửi lại mã khi hết thời gian đếm ngược và còn lượt gửi
  bool get canResendOtp => _otpCountdown == 0 && _remainingResendAttempts > 0;

  /// Kiểm tra tài khoản có đang bị khóa hay không
  bool get isAccountLocked =>
      _lockUntil != null && DateTime.now().isBefore(_lockUntil!);

  /// Số phút còn lại trước khi tài khoản được mở khóa
  int get lockRemainingMinutes {
    if (!isAccountLocked || _lockUntil == null) return 0;
    final diff = _lockUntil!.difference(DateTime.now()).inMinutes;
    return diff <= 0 ? 1 : diff + 1;
  }

  // ================= Mutators / Setters =================
  void setRememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  void setBiometricEnabled(bool value) {
    _biometricEnabled = value;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Thiết lập đối tượng UserModel hiện tại (dùng khi fetch profile từ backend hoặc login)
  void setCurrentUser(UserModel? user) {
    _currentUser = user;
    notifyListeners();
  }

  /// Cập nhật thông tin hồ sơ người dùng (thu nhập, họ tên, số điện thoại, nghề nghiệp, cccd, ...)
  void updateCurrentUser({
    String? fullName,
    String? phone,
    double? monthlyIncome,
    DateTime? dateOfBirth,
    String? idCardNumber,
    String? address,
    String? occupation,
    String? workplace,
    String? contractType,
    bool? isEkycVerified,
    String? ekycTier,
    String? membershipTier,
    int? cicScore,
    List<BankAccountModel>? bankAccounts,
  }) {
    if (_currentUser == null) {
      return;
    }
    _currentUser = _currentUser!.copyWith(
      fullName: fullName,
      phone: phone,
      monthlyIncome: monthlyIncome,
      dateOfBirth: dateOfBirth,
      idCardNumber: idCardNumber,
      address: address,
      occupation: occupation,
      workplace: workplace,
      contractType: contractType,
      isEkycVerified: isEkycVerified,
      ekycTier: ekycTier,
      membershipTier: membershipTier,
      cicScore: cicScore,
      bankAccounts: bankAccounts,
      updatedAt: DateTime.now(),
    );
    notifyListeners();

    // Đồng bộ xuống repository (nếu là API thật sẽ cập nhật backend)
    final Map<String, dynamic> patchData = {};
    if (fullName != null) patchData['full_name'] = fullName;
    if (phone != null) patchData['phone'] = phone;
    if (monthlyIncome != null) patchData['monthly_income'] = monthlyIncome;
    if (idCardNumber != null) patchData['id_card_number'] = idCardNumber;
    if (address != null) patchData['address'] = address;
    if (occupation != null) patchData['occupation'] = occupation;
    if (workplace != null) patchData['workplace'] = workplace;
    if (contractType != null) patchData['contract_type'] = contractType;
    if (isEkycVerified != null) patchData['is_ekyc_verified'] = isEkycVerified;
    if (ekycTier != null) patchData['ekyc_tier'] = ekycTier;
    if (membershipTier != null) patchData['membership_tier'] = membershipTier;
    if (cicScore != null) patchData['cic_score'] = cicScore;

    if (patchData.isNotEmpty) {
      _authRepository.updateProfile(patchData).catchError((_) => _currentUser!);
    }
  }

  /// Thêm tài khoản ngân hàng thụ hưởng liên kết
  void addBankAccount(BankAccountModel account) {
    if (_currentUser == null) {
      return;
    }
    final updatedList = List<BankAccountModel>.from(_currentUser!.bankAccounts)
      ..add(account);
    _currentUser = _currentUser!.copyWith(
      bankAccounts: updatedList,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    _authRepository.addBankAccount(account.toJson()).catchError((_) => account);
  }

  /// Xóa tài khoản ngân hàng liên kết
  void removeBankAccount(String accountId) {
    if (_currentUser == null) {
      return;
    }
    final updatedList = _currentUser!.bankAccounts
        .where((a) => a.id != accountId)
        .toList();
    _currentUser = _currentUser!.copyWith(
      bankAccounts: updatedList,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    _authRepository.deleteBankAccount(accountId).catchError((_) {});
  }

  /// Tải thông tin hồ sơ mới nhất từ backend repository
  Future<void> fetchProfile() async {
    try {
      final profile = await _authRepository.getProfile();
      _currentUser = profile;
      notifyListeners();
    } catch (_) {}
  }

  /// Đồng bộ cập nhật hồ sơ với chờ phản hồi (async await)
  Future<bool> syncProfile(Map<String, dynamic> profileData) async {
    try {
      final updated = await _authRepository.updateProfile(profileData);
      _currentUser = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void setPendingVerification({
    String? fullName,
    required String email,
    required String phone,
    required OtpFlow flow,
  }) {
    if (fullName != null && fullName.isNotEmpty) {
      _pendingFullName = fullName;
    }
    _pendingEmail = email;
    _pendingPhone = phone;
    _pendingFlow = flow;
    _startOtpTimer();
    notifyListeners();
  }

  // ================= Nghiệp vụ Xác thực =================

  /// Kiểm tra trạng thái phiên làm việc khi khởi động ứng dụng
  Future<bool> checkSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _authRepository.checkSession();

      if (token != null && !token.isExpired) {
        if (_currentUser == null) {
          try {
            _currentUser = await _authRepository.getProfile();
          } catch (_) {}
        }
        if (_activeSessions.isEmpty) {
          await loadSessions();
        }
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Đăng nhập tài khoản
  Future<AuthResultState> login(String identifier, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // 1. Kiểm tra tài khoản có đang bị khóa hay không
    if (isAccountLocked) {
      _isLoading = false;
      _errorMessage =
          'Tài khoản đang bị tạm khóa. Vui lòng thử lại sau $lockRemainingMinutes phút.';
      notifyListeners();
      return AuthResultState.locked;
    }

    try {
      // 2. Gọi repository xác thực
      final user = await _authRepository.login(
        identifier: identifier,
        password: password,
      );
      _currentUser = user;
      _failedOtpAttempts = 0;
      await loadSessions();

      _isLoading = false;
      notifyListeners();
      return AuthResultState.success;
    } on AccountLockedException catch (e) {
      _isLoading = false;
      _lockUntil =
          e.lockUntil ?? DateTime.now().add(const Duration(minutes: 15));
      _errorMessage = e.message;
      notifyListeners();
      return AuthResultState.locked;
    } on AccountUnverifiedException catch (e) {
      _isLoading = false;
      _pendingFullName = null;
      _pendingEmail = e.email;
      _pendingPhone = e.phone ?? '0900000001';
      _pendingFlow = OtpFlow.register;
      _startOtpTimer();
      notifyListeners();
      return AuthResultState.unverified;
    } on InvalidCredentialsException catch (e) {
      _isLoading = false;
      _errorMessage = e.message;
      notifyListeners();
      return AuthResultState.invalid;
    } on NetworkAuthException catch (e) {
      _isLoading = false;
      _errorMessage = e.message;
      notifyListeners();
      return AuthResultState.invalid;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return AuthResultState.invalid;
    }
  }

  /// Đăng ký tài khoản mới và bắt đầu luồng xác thực OTP
  Future<bool> register(RegisterRequestModel request) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.register(request.toJson());

      _pendingFullName = request.fullName;
      _pendingEmail = request.email;
      _pendingPhone = request.phone;
      _pendingFlow = OtpFlow.register;
      _startOtpTimer();

      _isLoading = false;
      notifyListeners();
      return true;
    } on NetworkAuthException catch (e) {
      _isLoading = false;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Xác thực mã OTP gửi về điện thoại / email
  Future<bool> verifyOtp(String otp, {required OtpFlow flow}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final isSuccess = await _authRepository.verifyOtp(
        otp: otp,
        flowType: flow == OtpFlow.register ? 'REGISTER' : 'FORGOT_PASSWORD',
      );

      if (!isSuccess) {
        _failedOtpAttempts++;
        _errorMessage = 'Mã OTP không chính xác. Vui lòng thử lại.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Hủy đồng hồ đếm ngược khi xác thực thành công
      _cancelOtpTimer();

      if (flow == OtpFlow.register) {
        UserModel? matchedUser;
        try {
          matchedUser = UserMockData.usersDatabase.firstWhere(
            (u) => u.email.toLowerCase() == (_pendingEmail ?? '').toLowerCase(),
          );
        } catch (_) {}

        String registeredName =
            _pendingFullName?.trim() ??
            matchedUser?.fullName ??
            'Khách hàng FinCredit';
        if (registeredName.isEmpty) registeredName = 'Khách hàng FinCredit';
        final uid =
            matchedUser?.userId ?? DateTime.now().millisecondsSinceEpoch;

        _currentUser = UserModel(
          userId: uid,
          fullName: registeredName,
          email: _pendingEmail ?? matchedUser?.email ?? 'user@fincredit.vn',
          phone: _pendingPhone ?? matchedUser?.phone ?? '0912345678',
          passwordHash: matchedUser?.passwordHash ?? 'secured_hash',
          token: 'jwt_verified_token_$uid',
          createdAt: DateTime.now(),
        );
        _biometricEnabled =
            false; // Mới tạo tài khoản -> chưa bật sinh trắc học
        await loadSessions();
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on OtpException catch (e) {
      _failedOtpAttempts++;
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } on NetworkAuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Gửi lại mã OTP
  Future<void> resendOtp() async {
    if (!canResendOtp) {
      if (_remainingResendAttempts <= 0) {
        _errorMessage = 'Bạn đã dùng hết số lần gửi lại OTP trong ngày.';
        notifyListeners();
      }
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _authRepository.resendOtp();
      _remainingResendAttempts--;
      _startOtpTimer();
    } on NetworkAuthException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cập nhật mật khẩu mới và thu hồi các phiên đăng nhập khác
  Future<bool> resetPassword(String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.resetPassword(newPassword: newPassword);
      _activeSessions = await _authRepository.getActiveSessions();

      _isLoading = false;
      notifyListeners();
      return true;
    } on NetworkAuthException catch (e) {
      _isLoading = false;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Không thể đặt lại mật khẩu. Vui lòng thử lại.';
      notifyListeners();
      return false;
    }
  }

  /// Đổi mật khẩu chủ động
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _activeSessions = await _authRepository.getActiveSessions();

      _isLoading = false;
      notifyListeners();
      return true;
    } on InvalidCredentialsException catch (e) {
      _isLoading = false;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } on NetworkAuthException catch (e) {
      _isLoading = false;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Tải danh sách các phiên thiết bị đang hoạt động
  Future<void> loadSessions() async {
    try {
      _activeSessions = await _authRepository.getActiveSessions();
      notifyListeners();
    } catch (_) {}
  }

  /// Thu hồi một phiên làm việc cụ thể
  Future<void> revokeSession(String sessionId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authRepository.revokeSession(sessionId);
      _activeSessions = await _authRepository.getActiveSessions();
    } catch (_) {
      _activeSessions = _activeSessions
          .where((s) => s.id != sessionId)
          .toList();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Đăng xuất tài khoản
  Future<void> logout() async {
    _currentUser = null;
    _activeSessions = [];
    _cancelOtpTimer();
    _errorMessage = null;
    _lockUntil = null;
    notifyListeners();

    try {
      if (GetIt.I.isRegistered<LoanController>()) {
        GetIt.I<LoanController>().clear();
      }
    } catch (_) {}

    try {
      await _authRepository.logout();
    } catch (_) {}
  }

  // ================= Tiện ích Hỗ trợ Dev/QA =================
  void setDevState(DevAuthState state) {
    _cancelOtpTimer();
    _errorMessage = null;

    switch (state) {
      case DevAuthState.normal:
        _isLoading = false;
        _currentUser = null;
        _lockUntil = null;
        break;
      case DevAuthState.loading:
        _isLoading = true;
        break;
      case DevAuthState.invalidCredentials:
        _isLoading = false;
        _errorMessage =
            'Thông tin đăng nhập không hợp lệ. Vui lòng kiểm tra lại.';
        break;
      case DevAuthState.accountUnverified:
        _isLoading = false;
        _pendingFullName = 'Nguyễn Văn Dev';
        _pendingEmail = 'dev@test.com';
        _pendingPhone = '0900000001';
        _pendingFlow = OtpFlow.register;
        _startOtpTimer();
        break;
      case DevAuthState.accountLocked:
        _isLoading = false;
        _lockUntil = DateTime.now().add(const Duration(minutes: 15));
        _errorMessage = 'Tài khoản bị tạm khóa 15 phút do nhập sai nhiều lần.';
        break;
      case DevAuthState.networkError:
        _isLoading = false;
        _errorMessage = 'Mất kết nối mạng. Vui lòng kiểm tra kết nối Internet.';
        break;
      case DevAuthState.sessionExpired:
        _isLoading = false;
        _currentUser = null;
        _errorMessage = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
        break;
    }
    notifyListeners();
  }

  // ================= Quản lý Timer OTP =================
  void _startOtpTimer() {
    _cancelOtpTimer();
    _otpCountdown = 105;
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_otpCountdown > 0) {
        _otpCountdown--;
        notifyListeners();
      } else {
        timer.cancel();
        notifyListeners();
      }
    });
  }

  void _cancelOtpTimer() {
    _otpTimer?.cancel();
    _otpTimer = null;
  }

  @override
  void dispose() {
    _cancelOtpTimer();
    super.dispose();
  }
}

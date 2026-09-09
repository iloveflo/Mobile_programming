import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../repositories/interfaces/auth_repository.dart';

class AuthController extends ChangeNotifier {
  final AuthRepository _authRepository;

  // Khởi tạo trực tiếp bằng this._authRepository
  AuthController(this._authRepository);
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters để UI đọc trạng thái
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); // Báo cho UI render trạng thái loading

    try {
      _currentUser = await _authRepository.login(email, password);
      _isLoading = false;
      notifyListeners();
      return true; // Đăng nhập thành công
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false; // Đăng nhập thất bại
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    return _handleAuthAction(
      () => _authRepository.register(name, email, password),
    );
  }

  // Hàm xử lý chung luồng loading và bắt lỗi
  Future<bool> _handleAuthAction(Future<UserModel> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await action();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}

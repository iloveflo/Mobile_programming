import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../controllers/credit_profile_controller.dart';
import '../controllers/loan_controller.dart';
import '../controllers/payment_schedule_controller.dart';
import '../core/config/app_env.dart';
import '../service_locator.dart';

/// Trừu tượng hóa Socket client để dễ viết Unit Test không cần server thật
abstract class RealtimeSocketDriver {
  void connect({
    required String origin,
    required String token,
    required void Function(String event, dynamic data) onEvent,
  });
  void disconnect();
}

class SocketIoRealtimeDriver implements RealtimeSocketDriver {
  io.Socket? _socket;

  @override
  void connect({
    required String origin,
    required String token,
    required void Function(String event, dynamic data) onEvent,
  }) {
    disconnect();
    final socket = io.io(
      origin,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setAuth({'token': token})
          .enableForceNew()
          .enableAutoConnect()
          .enableReconnection()
          .build(),
    );

    for (final eventName in const [
      'credit_health_update',
      'notification',
      'session_revoked',
    ]) {
      socket.on(eventName, (data) => onEvent(eventName, data));
    }
    socket.onConnect((_) => onEvent('socket_connected', null));
    socket.onDisconnect((_) => onEvent('socket_disconnected', null));
    socket.onConnectError((err) => onEvent('socket_disconnected', err));
    socket.connect();
    _socket = socket;
  }

  @override
  void disconnect() {
    _socket?.clearListeners();
    _socket?.dispose();
    _socket = null;
  }
}

/// Dịch vụ lắng nghe sự kiện Real-time từ PostgreSQL LISTEN/NOTIFY -> Socket.IO
class RealtimeService {
  final RealtimeSocketDriver _driver;
  final Duration debounceDuration;

  final Map<String, Timer> _debounceTimers = {};
  bool _isConnected = false;
  bool _isSocketLive = false;
  String? _activeToken;

  void Function(String title, String message)? onNotificationReceived;
  VoidCallback? onSessionRevoked;
  void Function(bool isConnected)? onConnectionStateChanged;

  /// Hook tùy chọn để test hoặc tùy biến luồng làm mới
  Future<void> Function()? onRefreshLoans;
  Future<void> Function()? onRefreshSchedules;
  Future<void> Function()? onRefreshNotifications;
  Future<void> Function()? onRefreshCreditProfile;

  RealtimeService({
    RealtimeSocketDriver? driver,
    this.debounceDuration = const Duration(milliseconds: 300),
  }) : _driver = driver ?? SocketIoRealtimeDriver();

  bool get isConnected => _isConnected;
  bool get isSocketLive => _isSocketLive;

  /// Chuyển `http://host:3000/api/v1` -> `http://host:3000`
  static String resolveSocketOrigin(String apiBaseUrl) {
    final trimmed = apiBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    return trimmed.replaceFirst(RegExp(r'/api(/v\d+)?$'), '');
  }

  void connect({required String accessToken, String? baseUrl}) {
    if (accessToken.isEmpty) return;
    if (_isConnected && _activeToken == accessToken) return;

    _activeToken = accessToken;
    _isConnected = true;
    final origin = resolveSocketOrigin(baseUrl ?? AppEnv.baseUrl);
    _driver.connect(origin: origin, token: accessToken, onEvent: handleEvent);
  }

  void disconnect() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
    _driver.disconnect();
    _isConnected = false;
    _isSocketLive = false;
    _activeToken = null;
  }

  @visibleForTesting
  void handleEvent(String event, dynamic raw) {
    if (event == 'socket_connected') {
      _isSocketLive = true;
      onConnectionStateChanged?.call(true);
      return;
    }

    if (event == 'socket_disconnected') {
      _isSocketLive = false;
      onConnectionStateChanged?.call(false);
      return;
    }

    final Map<String, dynamic> payload = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};

    if (event == 'session_revoked') {
      disconnect();
      onSessionRevoked?.call();
      return;
    }

    if (event == 'notification') {
      _scheduleRefresh('notifications', _triggerRefreshNotifications);
      final title = (payload['title'] ?? 'Thông báo mới').toString();
      final message = (payload['message'] ?? '').toString();
      onNotificationReceived?.call(title, message);
      return;
    }

    if (event == 'credit_health_update') {
      final table = (payload['table'] ?? '').toString().toLowerCase();
      switch (table) {
        case 'notifications':
          _scheduleRefresh('notifications', _triggerRefreshNotifications);
          break;
        case 'loans':
          _scheduleRefresh('loans', _triggerRefreshLoans);
          _scheduleRefresh('credit', _triggerRefreshCreditProfile);
          break;
        case 'payment_schedules':
        case 'payments':
          _scheduleRefresh('schedules', _triggerRefreshSchedules);
          _scheduleRefresh('loans', _triggerRefreshLoans);
          _scheduleRefresh('credit', _triggerRefreshCreditProfile);
          break;
        case 'credit_profiles':
          _scheduleRefresh('credit', _triggerRefreshCreditProfile);
          break;
      }
    }
  }

  void _scheduleRefresh(String key, Future<void> Function() action) {
    _debounceTimers[key]?.cancel();
    _debounceTimers[key] = Timer(debounceDuration, () {
      _debounceTimers.remove(key);
      action();
    });
  }

  Future<void> _triggerRefreshLoans() async {
    if (onRefreshLoans != null) {
      await onRefreshLoans!();
      return;
    }
    if (sl.isRegistered<LoanController>()) {
      await sl<LoanController>().fetchLoans();
    }
  }

  Future<void> _triggerRefreshSchedules() async {
    if (onRefreshSchedules != null) {
      await onRefreshSchedules!();
      return;
    }
    if (sl.isRegistered<PaymentScheduleController>()) {
      await sl<PaymentScheduleController>().loadSchedules();
    }
  }

  Future<void> _triggerRefreshNotifications() async {
    if (onRefreshNotifications != null) {
      await onRefreshNotifications!();
      return;
    }
    if (sl.isRegistered<PaymentScheduleController>()) {
      await sl<PaymentScheduleController>().loadNotifications();
    }
  }

  Future<void> _triggerRefreshCreditProfile() async {
    if (onRefreshCreditProfile != null) {
      await onRefreshCreditProfile!();
      return;
    }
    if (sl.isRegistered<CreditProfileController>()) {
      await sl<CreditProfileController>().loadCreditProfile();
    }
  }
}

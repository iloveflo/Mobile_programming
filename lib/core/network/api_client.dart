// lib/core/network/api_client.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import '../config/app_env.dart';

/// Ngoại lệ tùy chỉnh khi Backend API trả về mã lỗi HTTP (4xx, 5xx)
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic data;

  const ApiException({
    required this.statusCode,
    required this.message,
    this.data,
  });

  @override
  String toString() => message;
}

/// HTTP Client trung tâm phục vụ kết nối RESTful API của FinCredit
/// Sử dụng HttpClient chuẩn từ Dart SDK, sẵn sàng hoạt động mà không cần cài thêm dependencies.
class ApiClient {
  final String baseUrl;
  final HttpClient _httpClient;
  final Duration timeout;
  String? _authToken;

  ApiClient({
    String? baseUrl,
    HttpClient? httpClient,
    this.timeout = const Duration(seconds: 15),
  }) : baseUrl = baseUrl ?? AppEnv.baseUrl,
       _httpClient =
           httpClient ??
           (HttpClient()..connectionTimeout = const Duration(seconds: 10));

  /// Token xác thực Bearer hiện tại
  String? get authToken => _authToken;

  /// Thiết lập Token sau khi đăng nhập thành công
  void setAuthToken(String? token) {
    _authToken = token;
  }

  /// Xóa token khi đăng xuất
  void clearAuthToken() {
    _authToken = null;
  }

  /// Callback tự động làm mới Access Token khi gặp mã lỗi HTTP 401
  Future<bool> Function()? onRefreshToken;
  Future<bool>? _refreshFuture;

  /// Chuẩn hóa và tạo URI hoàn chỉnh từ baseUrl + endpoint
  Uri _buildUri(String endpoint, [Map<String, dynamic>? queryParams]) {
    String cleanBase = baseUrl.trim();
    if (cleanBase.endsWith('/')) {
      cleanBase = cleanBase.substring(0, cleanBase.length - 1);
    }
    String cleanEndpoint = endpoint.trim();
    if (!cleanEndpoint.startsWith('/')) {
      cleanEndpoint = '/$cleanEndpoint';
    }

    // Chuẩn hóa và triệt tiêu xung đột trùng lặp prefix '/api' hoặc '/api/v1'
    final hasBaseApi = RegExp(r'/api(/v\d+)?$').hasMatch(cleanBase);

    if (hasBaseApi) {
      if (cleanEndpoint.startsWith('/api/v')) {
        final match = RegExp(r'^/api/v\d+').firstMatch(cleanEndpoint);
        if (match != null) {
          cleanEndpoint = cleanEndpoint.substring(match.end);
        }
      } else if (cleanEndpoint.startsWith('/api/')) {
        cleanEndpoint = cleanEndpoint.substring(4);
      }
    } else {
      if (!cleanEndpoint.startsWith('/api/') &&
          !cleanEndpoint.startsWith('/api')) {
        cleanEndpoint = '/api$cleanEndpoint';
      }
    }

    final fullUrl = '$cleanBase$cleanEndpoint';
    final uri = Uri.parse(fullUrl);

    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(
        queryParameters: {
          ...uri.queryParameters,
          ...queryParams.map((k, v) => MapEntry(k, v.toString())),
        },
      );
    }
    return uri;
  }

  /// Cấu hình Headers mặc định (JSON & Bearer Token)
  void _applyHeaders(
    HttpClientRequest request,
    Map<String, String>? extraHeaders,
  ) {
    request.headers.set(
      HttpHeaders.contentTypeHeader,
      'application/json; charset=utf-8',
    );
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');

    if (_authToken != null && _authToken!.isNotEmpty) {
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer $_authToken',
      );
    }

    if (extraHeaders != null) {
      extraHeaders.forEach((key, value) {
        request.headers.set(key, value);
      });
    }
  }

  /// Xử lý phản hồi từ Backend
  Future<dynamic> _processResponse(HttpClientResponse response) async {
    final responseBody = await response.transform(utf8.decoder).join();
    dynamic decodedData;

    if (responseBody.trim().isNotEmpty) {
      try {
        decodedData = jsonDecode(responseBody);
      } catch (_) {
        decodedData = responseBody;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decodedData;
    }

    // Trích xuất thông điệp lỗi từ Backend payload nếu có
    String errorMessage =
        'Yêu cầu không thành công (HTTP ${response.statusCode})';
    if (decodedData is Map<String, dynamic>) {
      errorMessage =
          decodedData['message'] ??
          decodedData['error'] ??
          decodedData['msg'] ??
          errorMessage;
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: errorMessage,
      data: decodedData,
    );
  }

  /// Thực thi HTTP request với cơ chế Auto Token Refresh Interceptor khi gặp 401
  Future<dynamic> _executeWithRetry(
    String endpoint,
    Future<dynamic> Function() action,
  ) async {
    try {
      return await action();
    } on ApiException catch (e) {
      final isAuthEndpoint =
          endpoint.contains('login') ||
          endpoint.contains('register') ||
          endpoint.contains('refresh') ||
          endpoint.contains('session');
      if (e.statusCode == 401 && !isAuthEndpoint && onRefreshToken != null) {
        final bool isInitiator = _refreshFuture == null;
        _refreshFuture ??= onRefreshToken!();
        try {
          final success = await _refreshFuture!;
          if (success) {
            return await action();
          }
        } finally {
          if (isInitiator) {
            _refreshFuture = null;
          }
        }
      }
      rethrow;
    }
  }

  // ================= CÁC PHƯƠNG THỨC HTTP CHUẨN =================

  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
  }) {
    return _executeWithRetry(endpoint, () async {
      final uri = _buildUri(endpoint, queryParams);
      final request = await _httpClient.getUrl(uri).timeout(timeout);
      _applyHeaders(request, headers);
      final response = await request.close().timeout(timeout);
      return _processResponse(response);
    });
  }

  /// Tải dữ liệu nhị phân (file PDF/ảnh) trực tiếp từ Backend
  Future<List<int>> getBytes(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
  }) async {
    final result = await _executeWithRetry(endpoint, () async {
      final uri = _buildUri(endpoint, queryParams);
      final request = await _httpClient.getUrl(uri).timeout(timeout);
      _applyHeaders(request, headers);
      final response = await request.close().timeout(timeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final builder = BytesBuilder(copy: false);
        await for (final chunk in response) {
          builder.add(chunk);
        }
        return builder.takeBytes();
      }
      await _processResponse(response);
      return <int>[];
    });
    return List<int>.from(result as List);
  }

  static final Random _idempotencyRandom = Random.secure();

  static String _generateIdempotencyKey() {
    final ts = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final r1 = _idempotencyRandom.nextInt(1 << 30).toRadixString(36);
    final r2 = _idempotencyRandom.nextInt(1 << 30).toRadixString(36);
    return 'fc-$ts-$r1$r2';
  }

  static Map<String, String> _withIdempotencyKey(Map<String, String>? headers) {
    final merged = <String, String>{...?headers};
    final hasKey = merged.keys.any(
      (k) =>
          k.toLowerCase() == 'idempotency-key' ||
          k.toLowerCase() == 'x-idempotency-key',
    );
    if (!hasKey) {
      merged['Idempotency-Key'] = _generateIdempotencyKey();
    }
    return merged;
  }

  Future<dynamic> post(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
  }) {
    final effectiveHeaders = _withIdempotencyKey(headers);
    return _executeWithRetry(endpoint, () async {
      final uri = _buildUri(endpoint);
      final request = await _httpClient.postUrl(uri).timeout(timeout);
      _applyHeaders(request, effectiveHeaders);

      if (body != null) {
        request.write(body is String ? body : jsonEncode(body));
      }

      final response = await request.close().timeout(timeout);
      return _processResponse(response);
    });
  }

  Future<dynamic> put(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
  }) {
    final effectiveHeaders = _withIdempotencyKey(headers);
    return _executeWithRetry(endpoint, () async {
      final uri = _buildUri(endpoint);
      final request = await _httpClient.putUrl(uri).timeout(timeout);
      _applyHeaders(request, effectiveHeaders);

      if (body != null) {
        request.write(body is String ? body : jsonEncode(body));
      }

      final response = await request.close().timeout(timeout);
      return _processResponse(response);
    });
  }

  Future<dynamic> patch(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
  }) {
    final effectiveHeaders = _withIdempotencyKey(headers);
    return _executeWithRetry(endpoint, () async {
      final uri = _buildUri(endpoint);
      final request = await _httpClient.patchUrl(uri).timeout(timeout);
      _applyHeaders(request, effectiveHeaders);

      if (body != null) {
        request.write(body is String ? body : jsonEncode(body));
      }

      final response = await request.close().timeout(timeout);
      return _processResponse(response);
    });
  }

  Future<dynamic> delete(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
  }) {
    final effectiveHeaders = _withIdempotencyKey(headers);
    return _executeWithRetry(endpoint, () async {
      final uri = _buildUri(endpoint);
      final request = await _httpClient.deleteUrl(uri).timeout(timeout);
      _applyHeaders(request, effectiveHeaders);

      if (body != null) {
        request.write(body is String ? body : jsonEncode(body));
      }

      final response = await request.close().timeout(timeout);
      return _processResponse(response);
    });
  }

  /// Gửi dữ liệu nhị phân (ảnh / file) trực tiếp qua phương thức PUT lên Cloudflare R2 Presigned URL
  Future<bool> uploadBinary(
    Uri presignedUri,
    List<int> bytes, {
    String contentType = 'image/jpeg',
    Map<String, String>? extraHeaders,
  }) async {
    final request = await _httpClient
        .putUrl(presignedUri)
        .timeout(const Duration(minutes: 5));
    request.headers.set(HttpHeaders.contentTypeHeader, contentType);
    request.headers.contentLength = bytes.length;
    if (extraHeaders != null) {
      extraHeaders.forEach((key, value) {
        request.headers.set(key, value);
      });
    }
    request.add(bytes);
    final response = await request.close().timeout(const Duration(minutes: 5));
    return response.statusCode >= 200 && response.statusCode < 300;
  }
}

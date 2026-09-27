// lib/core/network/api_client.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

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

    // Loại bỏ xung đột trùng lặp '/api' nếu baseUrl đã chứa '/api' hoặc '/api/v1'
    if (cleanBase.endsWith('/api') && cleanEndpoint.startsWith('/api/')) {
      cleanEndpoint = cleanEndpoint.substring(4);
    } else if (cleanBase.contains(RegExp(r'/api/v\d+$')) &&
        cleanEndpoint.startsWith('/api/')) {
      cleanEndpoint = cleanEndpoint.substring(4);
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

  // ================= CÁC PHƯƠNG THỨC HTTP CHUẨN =================

  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
  }) async {
    final uri = _buildUri(endpoint, queryParams);
    final request = await _httpClient.getUrl(uri).timeout(timeout);
    _applyHeaders(request, headers);
    final response = await request.close().timeout(timeout);
    return _processResponse(response);
  }

  Future<dynamic> post(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(endpoint);
    final request = await _httpClient.postUrl(uri).timeout(timeout);
    _applyHeaders(request, headers);

    if (body != null) {
      request.write(body is String ? body : jsonEncode(body));
    }

    final response = await request.close().timeout(timeout);
    return _processResponse(response);
  }

  Future<dynamic> put(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(endpoint);
    final request = await _httpClient.putUrl(uri).timeout(timeout);
    _applyHeaders(request, headers);

    if (body != null) {
      request.write(body is String ? body : jsonEncode(body));
    }

    final response = await request.close().timeout(timeout);
    return _processResponse(response);
  }

  Future<dynamic> patch(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(endpoint);
    final request = await _httpClient.patchUrl(uri).timeout(timeout);
    _applyHeaders(request, headers);

    if (body != null) {
      request.write(body is String ? body : jsonEncode(body));
    }

    final response = await request.close().timeout(timeout);
    return _processResponse(response);
  }

  Future<dynamic> delete(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(endpoint);
    final request = await _httpClient.deleteUrl(uri).timeout(timeout);
    _applyHeaders(request, headers);

    if (body != null) {
      request.write(body is String ? body : jsonEncode(body));
    }

    final response = await request.close().timeout(timeout);
    return _processResponse(response);
  }
}

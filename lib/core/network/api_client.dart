// lib/core/network/api_client.dart
import '../config/app_env.dart';

class ApiClient {
  final String baseUrl;

  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? AppEnv.baseUrl;

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) async {
    // URL hoàn chỉnh khi gọi API: '$baseUrl$endpoint'
    throw UnimplementedError('ApiClient chưa được tích hợp HTTP/Dio');
  }

  Future<dynamic> get(String endpoint) async {
    throw UnimplementedError('ApiClient chưa được tích hợp HTTP/Dio');
  }
}
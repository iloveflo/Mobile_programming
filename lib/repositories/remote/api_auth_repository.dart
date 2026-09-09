import '../../core/network/api_client.dart';
import '../../models/user_model.dart';
import '../interfaces/auth_repository.dart';

class ApiAuthRepository implements AuthRepository {
  final ApiClient client;

  ApiAuthRepository({required this.client});

  @override
  Future<UserModel> login(String email, String password) async {
    // Truyền trực tiếp path endpoint vào client.post
    final response = await client.post(
      '/auth/login',
      body: {'email': email, 'password': password},
    );

    return UserModel.fromJson(response.data);
  }

  @override
  Future<UserModel> register(String name, String email, String password) async {
    final response = await client.post(
      '/auth/register',
      body: {'name': name, 'email': email, 'password': password},
    );

    return UserModel.fromJson(response.data);
  }
}

import 'package:flutter/material.dart';
import '../../controllers/auth_controller.dart';
import '../../routes/app_router.dart';
import '../../service_locator.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'dev@test.com');
  final _passwordController = TextEditingController(text: '123456');
  final _authController = sl<AuthController>();
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLoginPressed() async {
    final isSuccess = await _authController.login(
      _emailController.text,
      _passwordController.text,
    );
    
    if (!mounted) return;

    if (isSuccess) {
      Navigator.pushReplacementNamed(context, AppRouter.home);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_authController.errorMessage ?? 'Đăng nhập thất bại'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  

  @override
  Widget build(BuildContext context) {
    // ListenableBuilder giúp tự động rebuild UI khi controller gọi notifyListeners()
    return ListenableBuilder(
      listenable: _authController,
      builder: (context, child) {
        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Mật khẩu'),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _authController.isLoading ? null : _onLoginPressed,
                  child: _authController.isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Đăng nhập'),
                ),
                
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRouter.register);
                  },
                  child: const Text('Chưa có tài khoản? Đăng ký ngay'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'routes/app_router.dart';
import 'service_locator.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Khởi tạo Service Locator (Mock/API Repository)
  setupServiceLocator();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF35313B),
        ),
      ),
      // Cấu hình điều hướng bằng Route
      initialRoute: AppRouter.login,
      routes: AppRouter.routes,
    );
  }
}
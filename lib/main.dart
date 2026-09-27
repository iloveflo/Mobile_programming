import 'package:flutter/material.dart';

import 'routes/app_router.dart';
import 'service_locator.dart';
import 'widgets/widget.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Service Locator (Mock/API Repository)
  setupServiceLocator();

  runApp(const FinCreditApp());
}

class FinCreditApp extends StatelessWidget {
  const FinCreditApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinCredit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          surface: AppColors.surface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      // M01: Bắt đầu từ SplashScreen
      initialRoute: AppRouter.splash,
      routes: AppRouter.routes,
    );
  }
}

/// Alias đảm bảo tương thích ngược cho test
typedef MyApp = FinCreditApp;

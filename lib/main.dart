import 'package:flutter/material.dart';

import 'layout/responsive_layout.dart';
import 'routes/app_router.dart';
import 'service_locator.dart';
import 'services/push_notification_service.dart';
import 'widgets/widget.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase Cloud Messaging (FCM) để nhận thông báo khi app đã tắt
  await PushNotificationService.instance.initialize();

  // Khởi tạo Service Locator (Mock/API Repository)
  setupServiceLocator();

  runApp(const FinCreditApp());
}

class FinCreditApp extends StatelessWidget {
  const FinCreditApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: AppRouter.navigatorKey,
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
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: ResponsiveTextScaler.clamp(context),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

/// Alias đảm bảo tương thích ngược cho test
typedef MyApp = FinCreditApp;

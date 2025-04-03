// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_login_template/controllers/dashboard_controller.dart';
import 'package:flutter_login_template/controllers/product_controller.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'config/theme.dart';
import 'controllers/admin_auth_controller.dart';
import 'controllers/admin_management_controller.dart';
import 'screens/admin/admin_home_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/splash/splash_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    // GetX 컨트롤러 초기화
    Get.put(AdminAuthController());
    Get.put(AdminManagementController());
    Get.put(ProductController());
    Get.put(DashboardController());

    return GetMaterialApp(
      title: '네이처바스켓 어드민',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminAuthController authController = Get.find<AdminAuthController>();

    return Obx(() {
      if (authController.isLoading.value) {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      if (authController.isLoggedIn) {
        if (authController.currentAdmin.value != null) {
          return const AdminHomeScreen();
        } else {
          // 로그인은 되어 있지만 관리자 정보가 없는 경우
          // 사용자 권한 오류 또는 불일치 (비관리자가 로그인한 경우)
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '접근 권한 오류',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '관리자 권한이 없는 계정입니다.',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => authController.signOut(),
                    child: const Text('로그아웃'),
                  ),
                ],
              ),
            ),
          );
        }
      } else {
        // 첫 실행 여부에 따라 스플래시 또는 로그인 화면으로 이동
        // 네이처바스켓 어드민은 항상 로그인 화면으로 바로 이동
        return const LoginScreen();
      }
    });
  }
}

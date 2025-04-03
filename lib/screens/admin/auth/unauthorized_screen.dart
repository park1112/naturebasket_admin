// lib/screens/admin/auth/unauthorized_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/admin_auth_controller.dart';
import '../../../config/theme.dart';

class UnauthorizedScreen extends StatelessWidget {
  final String? errorMessage;
  final String? errorDetails;

  const UnauthorizedScreen({
    Key? key,
    this.errorMessage,
    this.errorDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AdminAuthController authController = Get.find<AdminAuthController>();

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isSmallScreen = constraints.maxWidth < 600;

            return Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 24 : 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/lock.png',
                        width: isSmallScreen ? 120 : 160,
                        height: isSmallScreen ? 120 : 160,
                        errorBuilder: (context, error, stackTrace) {
                          // 이미지가 없는 경우 아이콘으로 대체
                          return Icon(
                            Icons.no_accounts,
                            size: isSmallScreen ? 100 : 140,
                            color: Colors.red.withOpacity(0.7),
                          );
                        },
                      ),
                      const SizedBox(height: 40),
                      Text(
                        errorMessage ?? '접근 권한이 없습니다',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 24 : 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        errorDetails ??
                            '관리자 권한이 없거나 계정이 비활성화되었습니다.\n관리자에게 문의하세요.',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18,
                          color: Colors.grey.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: isSmallScreen ? double.infinity : 300,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await authController.signOut();
                          },
                          icon: const Icon(Icons.logout),
                          label: const Text(
                            '로그아웃',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () {
                          // 정보 이메일이나 연락처가 있다면 여기서 제공
                          Get.snackbar(
                            '안내',
                            '관리자 이메일: admin@naturebasket.com',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.blue.withOpacity(0.1),
                          );
                        },
                        icon: const Icon(Icons.support_agent, size: 20),
                        label: const Text('관리자 연락처 보기'),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        '© ${DateTime.now().year} 네이처바스켓',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

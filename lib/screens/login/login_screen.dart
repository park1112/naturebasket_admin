// lib/screens/login/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_login_template/config/theme.dart';
import 'package:flutter_login_template/screens/admin/auth/admin_signup_screen.dart';
import 'package:get/get.dart';
import '../../controllers/admin_auth_controller.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AdminAuthController _authController = Get.find<AdminAuthController>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      await _authController.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isSmallScreen = constraints.maxWidth < 600;

            return Center(
              child: SingleChildScrollView(
                child: Container(
                  width: isSmallScreen ? null : 400,
                  padding: EdgeInsets.all(isSmallScreen ? 24 : 40),
                  decoration: isSmallScreen
                      ? null
                      : BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 로고 및 제목
                      Icon(
                        Icons.eco,
                        size: 80,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        '네이처바스켓 어드민',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // 로그인 폼
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // 이메일 필드
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: '이메일',
                                hintText: '관리자 이메일을 입력하세요',
                                prefixIcon: Icon(Icons.email),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '이메일을 입력해주세요.';
                                }
                                if (!GetUtils.isEmail(value)) {
                                  return '올바른 이메일 형식이 아닙니다.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // 비밀번호 필드
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: '비밀번호',
                                hintText: '비밀번호를 입력하세요',
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                border: const OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '비밀번호를 입력해주세요.';
                                }
                                return null;
                              },
                            ),

                            // 비밀번호 찾기 링크
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Get.to(() => const ForgotPasswordScreen());
                                },
                                child: const Text('비밀번호 찾기'),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // 로그인 버튼
                            Obx(() => SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _authController.isLoading.value
                                        ? null
                                        : _login,
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: _authController.isLoading.value
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                            ),
                                          )
                                        : const Text(
                                            '로그인',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                )),
                            const SizedBox(height: 24),
                            // 회원가입 버튼 추가
                            TextButton(
                              onPressed: () =>
                                  Get.to(() => const AdminSignupScreen()),
                              child: const Text(
                                '관리자 회원가입',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          ],
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

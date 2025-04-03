// lib/screens/admin/auth/admin_signup_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/admin_auth_controller.dart';
import '../../../controllers/admin_management_controller.dart';
import '../../../models/admin_model.dart';
import '../../../config/theme.dart';

class AdminSignupScreen extends StatefulWidget {
  const AdminSignupScreen({Key? key}) : super(key: key);

  @override
  State<AdminSignupScreen> createState() => _AdminSignupScreenState();
}

class _AdminSignupScreenState extends State<AdminSignupScreen> {
  final AdminAuthController _authController = Get.find<AdminAuthController>();
  final AdminManagementController _managementController =
      Get.find<AdminManagementController>();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  AdminRole _selectedRole = AdminRole.viewer;
  List<String> _selectedPermissions = [];

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSignupEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkSignupAvailability();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // 첫 번째 관리자 계정 생성인지 확인
  Future<void> _checkSignupAvailability() async {
    try {
      await _managementController.loadAdmins();
      setState(() {
        // 관리자가 없으면 첫 번째 관리자 계정을 최고 관리자로 생성
        if (_managementController.admins.isEmpty) {
          // 첫 번째 관리자는 최고 관리자 권한 부여
          _isSignupEnabled = true;
          _selectedRole = AdminRole.superAdmin;
          _selectedPermissions = List.from(_getAllPermissions());
        } else {
          // 이미 관리자가 있더라도 가입은 진행되나, 기본 권한(예: 조회자 또는 pending 상태)으로 생성하고 활성화는 false로 처리
          _isSignupEnabled = true;
          _selectedRole = AdminRole.viewer; // 또는 pending 상태가 있다면 pending으로 설정
          _selectedPermissions = []; // 기본 권한 없음
        }
      });
    } catch (e) {
      Get.snackbar(
        '오류',
        '관리자 정보를 확인하는 중 문제가 발생했습니다: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
      );
    }
  }

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      // 비밀번호 일치 확인
      if (_passwordController.text != _confirmPasswordController.text) {
        Get.snackbar(
          '오류',
          '비밀번호가 일치하지 않습니다',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.1),
        );
        return;
      }

      try {
        // 관리자 계정 생성 (Firebase Auth에서 계정 생성 후 Firestore에 문서 생성)
        bool success = await _managementController.createAdmin(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          role: _selectedRole,
          permissions: _selectedPermissions,
        );

        if (success) {
          // Firebase Auth에서 createUserWithEmailAndPassword 호출 시 자동 로그인되므로,
          // 별도의 signIn 호출은 필요하지 않습니다.
          Get.snackbar(
            '회원가입 성공',
            '관리자 계정이 생성되었습니다.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.withOpacity(0.1),
          );
          // 이후 원하는 관리자 메인 화면 등으로 이동합니다.
          Get.offAllNamed('/adminDashboard');
        }
      } catch (e) {
        Get.snackbar(
          '오류',
          '관리자 계정 생성 중 오류가 발생했습니다: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.1),
        );
      }
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
                  width: isSmallScreen ? null : 500,
                  padding: EdgeInsets.all(isSmallScreen ? 20 : 40),
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
                  child: _isSignupEnabled
                      ? _buildSignupForm(isSmallScreen)
                      : _buildSignupDisabled(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSignupForm(bool isSmallScreen) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 로고 및 제목
          Icon(
            Icons.admin_panel_settings,
            size: 64,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 24),
          Text(
            _managementController.admins.isEmpty ? '첫 관리자 계정 생성' : '관리자 회원가입',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _managementController.admins.isEmpty
                ? '첫 번째 관리자는 자동으로 최고 관리자 권한을 갖습니다'
                : '기존 관리자의 승인을 통해 가입이 완료됩니다',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),

          // 이름 필드
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '이름',
              hintText: '이름을 입력하세요',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '이름을 입력해주세요.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // 이메일 필드
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: '이메일',
              hintText: '이메일을 입력하세요',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
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
            decoration: InputDecoration(
              labelText: '비밀번호',
              hintText: '비밀번호를 입력하세요',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: const OutlineInputBorder(),
            ),
            obscureText: _obscurePassword,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '비밀번호를 입력해주세요.';
              }
              if (value.length < 8) {
                return '비밀번호는 8자 이상이어야 합니다.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // 비밀번호 확인 필드
          TextFormField(
            controller: _confirmPasswordController,
            decoration: InputDecoration(
              labelText: '비밀번호 확인',
              hintText: '비밀번호를 다시 입력하세요',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              border: const OutlineInputBorder(),
            ),
            obscureText: _obscureConfirmPassword,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '비밀번호를 다시 입력해주세요.';
              }
              if (value != _passwordController.text) {
                return '비밀번호가 일치하지 않습니다.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // 관리자 역할 선택 (첫 관리자는 최고 관리자로 고정)
          if (_managementController.admins.isNotEmpty) ...[
            DropdownButtonFormField<AdminRole>(
              value: _selectedRole,
              decoration: const InputDecoration(
                labelText: '관리자 역할',
                prefixIcon: Icon(Icons.admin_panel_settings),
                border: OutlineInputBorder(),
              ),
              items: AdminRole.values.map((role) {
                return DropdownMenuItem<AdminRole>(
                  value: role,
                  child: Text(_getRoleDisplayName(role)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedRole = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
          ],

          const SizedBox(height: 24),

          // 회원가입 버튼
          Obx(() => SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _authController.isLoading.value ? null : _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
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
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          '회원가입',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              )),
          const SizedBox(height: 16),

          // 로그인 화면으로 이동
          TextButton(
            onPressed: () {
              Get.back();
            },
            child: const Text('이미 계정이 있으신가요? 로그인'),
          ),
        ],
      ),
    );
  }

  Widget _buildSignupDisabled() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.lock,
          size: 64,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 24),
        const Text(
          '관리자 회원가입 제한',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '관리자 계정은 기존 관리자의 초대를 통해서만 생성할 수 있습니다. 관리자에게 문의하세요.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '로그인 화면으로 돌아가기',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getRoleDisplayName(AdminRole role) {
    switch (role) {
      case AdminRole.superAdmin:
        return '최고 관리자';
      case AdminRole.manager:
        return '관리자';
      case AdminRole.editor:
        return '편집자';
      case AdminRole.viewer:
        return '조회자';
      default:
        return '조회자';
    }
  }

  // 모든 권한 목록 가져오기
  List<String> _getAllPermissions() {
    return [
      // 관리자 관리 권한
      'view_admins',
      'create_admin',
      'edit_admin',
      'edit_admin_role',
      'edit_admin_permissions',
      'toggle_admin_status',
      'reset_admin_password',

      // 상품 관리 권한
      'view_products',
      'create_product',
      'edit_product',
      'delete_product',
      'manage_inventory',

      // 주문 관리 권한
      'view_orders',
      'update_order_status',
      'cancel_order',
      'refund_order',
      'export_orders',

      // 회원 관리 권한
      'view_customers',
      'edit_customer',
      'block_customer',
      'delete_customer',

      // 마케팅 관리 권한
      'view_promotions',
      'create_promotion',
      'edit_promotion',
      'delete_promotion',
      'send_notifications',

      // 콘텐츠 관리 권한
      'view_content',
      'create_content',
      'edit_content',
      'delete_content',
      'publish_content',

      // 통계 및 리포트 권한
      'view_dashboard',
      'view_sales_reports',
      'view_customer_reports',
      'view_product_reports',
      'export_reports',

      // 설정 권한
      'view_settings',
      'edit_settings',
      'manage_payment_settings',
      'manage_shipping_settings',
    ];
  }
}

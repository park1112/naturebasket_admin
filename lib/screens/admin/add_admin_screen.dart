// lib/screens/admin/add_admin_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/admin_management_controller.dart';
import '../../controllers/admin_auth_controller.dart';
import '../../models/admin_model.dart';
import '../../config/theme.dart';

class AddAdminScreen extends StatefulWidget {
  const AddAdminScreen({Key? key}) : super(key: key);

  @override
  State<AddAdminScreen> createState() => _AddAdminScreenState();
}

class _AddAdminScreenState extends State<AddAdminScreen> {
  final AdminManagementController _managementController =
      Get.find<AdminManagementController>();
  final AdminAuthController _authController = Get.find<AdminAuthController>();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  AdminRole _selectedRole = AdminRole.viewer;
  List<String> _selectedPermissions = [];

  @override
  void initState() {
    super.initState();
    // 기본적으로 권한은 없음. 역할에 따라 자동 선택됨
    if (_selectedRole == AdminRole.superAdmin) {
      _selectedPermissions = List.from(_getAllPermissions());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('관리자 추가'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isSmallScreen = constraints.maxWidth < 600;

          return Obx(() {
            if (_managementController.isLoading.value) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            return SingleChildScrollView(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBasicInfoCard(isSmallScreen),
                    const SizedBox(height: 24),
                    _buildRoleCard(isSmallScreen),
                    const SizedBox(height: 24),
                    if (_selectedRole != AdminRole.superAdmin)
                      _buildPermissionsCard(isSmallScreen),
                    const SizedBox(height: 32),
                    _buildSubmitButton(isSmallScreen),
                  ],
                ),
              ),
            );
          });
        },
      ),
    );
  }

  Widget _buildBasicInfoCard(bool isSmallScreen) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '기본 정보',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '이름',
                hintText: '관리자 이름을 입력하세요',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '이름을 입력해주세요.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: '이메일',
                hintText: '관리자 이메일을 입력하세요',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
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
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: '비밀번호',
                hintText: '초기 비밀번호를 입력하세요',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
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
            const SizedBox(height: 8),
            Text(
              '* 비밀번호는 8자 이상이어야 합니다.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard(bool isSmallScreen) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '역할 설정',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            DropdownButtonFormField<AdminRole>(
              value: _selectedRole,
              decoration: const InputDecoration(
                labelText: '역할',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.admin_panel_settings),
              ),
              onChanged: (AdminRole? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedRole = newValue;

                    // 최고 관리자로 변경 시 모든 권한 부여
                    if (newValue == AdminRole.superAdmin) {
                      _selectedPermissions = List.from(_getAllPermissions());
                    }
                  });
                }
              },
              items: AdminRole.values
                  .map<DropdownMenuItem<AdminRole>>((AdminRole role) {
                return DropdownMenuItem<AdminRole>(
                  value: role,
                  child: Text(_getRoleDisplayName(role)),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(
              _getRoleDescription(_selectedRole),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsCard(bool isSmallScreen) {
    List<String> permissions = _getAllPermissions();
    Map<String, List<String>> groupedPermissions =
        _groupPermissions(permissions);

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '권한 설정',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      if (_selectedPermissions.length == permissions.length) {
                        _selectedPermissions.clear();
                      } else {
                        _selectedPermissions = List.from(permissions);
                      }
                    });
                  },
                  icon: Icon(
                    _selectedPermissions.length == permissions.length
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    size: 18,
                  ),
                  label: Text(
                    _selectedPermissions.length == permissions.length
                        ? '전체 해제'
                        : '전체 선택',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            for (String group in groupedPermissions.keys) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 4),
                child: Text(
                  _getPermissionGroupDisplayName(group),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  for (String permission in groupedPermissions[group]!)
                    _buildPermissionChip(permission),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionChip(String permission) {
    bool isSelected = _selectedPermissions.contains(permission);

    return FilterChip(
      label: Text(_getPermissionDisplayName(permission)),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          if (selected) {
            _selectedPermissions.add(permission);
          } else {
            _selectedPermissions.remove(permission);
          }
        });
      },
      backgroundColor: Colors.grey.shade100,
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildSubmitButton(bool isSmallScreen) {
    return Obx(() => SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed:
                _managementController.isLoading.value ? null : _createAdmin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _managementController.isLoading.value
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    '관리자 계정 생성',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ));
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

  String _getRoleDescription(AdminRole role) {
    switch (role) {
      case AdminRole.superAdmin:
        return '최고 관리자는 모든 기능에 접근 가능하며, 다른 관리자 계정을 관리할 수 있습니다.';
      case AdminRole.manager:
        return '관리자는 대부분의 기능에 접근 가능하지만, 일부 민감한 설정은 제한될 수 있습니다.';
      case AdminRole.editor:
        return '편집자는 콘텐츠 및 상품 관리와 같은 편집 기능에 접근 가능합니다.';
      case AdminRole.viewer:
        return '조회자는 읽기 전용 권한만 가지며, 데이터 수정 권한은 없습니다.';
      default:
        return '';
    }
  }

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

  Map<String, List<String>> _groupPermissions(List<String> permissions) {
    Map<String, List<String>> grouped = {};

    for (String permission in permissions) {
      String group = permission.split('_')[0];
      if (group == 'view' ||
          group == 'edit' ||
          group == 'create' ||
          group == 'delete') {
        group = permission.split('_')[1];
      }

      if (!grouped.containsKey(group)) {
        grouped[group] = [];
      }

      grouped[group]!.add(permission);
    }

    return grouped;
  }

  String _getPermissionGroupDisplayName(String group) {
    switch (group) {
      case 'admins':
        return '관리자 관리';
      case 'products':
        return '상품 관리';
      case 'orders':
        return '주문 관리';
      case 'customers':
        return '회원 관리';
      case 'promotions':
        return '마케팅 관리';
      case 'content':
        return '콘텐츠 관리';
      case 'dashboard':
        return '대시보드';
      case 'sales':
        return '매출 통계';
      case 'customer':
        return '고객 통계';
      case 'product':
        return '상품 통계';
      case 'reports':
        return '리포트';
      case 'settings':
        return '설정';
      case 'payment':
        return '결제 설정';
      case 'shipping':
        return '배송 설정';
      case 'inventory':
        return '재고 관리';
      case 'notifications':
        return '알림 관리';
      default:
        return group.substring(0, 1).toUpperCase() + group.substring(1);
    }
  }

  String _getPermissionDisplayName(String permission) {
    Map<String, String> displayNames = {
      'view_admins': '관리자 조회',
      'create_admin': '관리자 생성',
      'edit_admin': '관리자 수정',
      'edit_admin_role': '관리자 역할 수정',
      'edit_admin_permissions': '관리자 권한 수정',
      'toggle_admin_status': '관리자 상태 변경',
      'reset_admin_password': '관리자 비밀번호 재설정',
      'view_products': '상품 조회',
      'create_product': '상품 생성',
      'edit_product': '상품 수정',
      'delete_product': '상품 삭제',
      'manage_inventory': '재고 관리',
      'view_orders': '주문 조회',
      'update_order_status': '주문 상태 변경',
      'cancel_order': '주문 취소',
      'refund_order': '환불 처리',
      'export_orders': '주문 내보내기',
      'view_customers': '회원 조회',
      'edit_customer': '회원 정보 수정',
      'block_customer': '회원 차단',
      'delete_customer': '회원 삭제',
      'view_promotions': '프로모션 조회',
      'create_promotion': '프로모션 생성',
      'edit_promotion': '프로모션 수정',
      'delete_promotion': '프로모션 삭제',
      'send_notifications': '알림 전송',
      'view_content': '콘텐츠 조회',
      'create_content': '콘텐츠 생성',
      'edit_content': '콘텐츠 수정',
      'delete_content': '콘텐츠 삭제',
      'publish_content': '콘텐츠 발행',
      'view_dashboard': '대시보드 조회',
      'view_sales_reports': '매출 리포트 조회',
      'view_customer_reports': '고객 리포트 조회',
      'view_product_reports': '상품 리포트 조회',
      'export_reports': '리포트 내보내기',
      'view_settings': '설정 조회',
      'edit_settings': '설정 수정',
      'manage_payment_settings': '결제 설정 관리',
      'manage_shipping_settings': '배송 설정 관리',
    };

    return displayNames[permission] ?? permission;
  }

  void _createAdmin() async {
    if (_formKey.currentState!.validate()) {
      // 관리자 계정 생성
      try {
        await _managementController.createAdmin(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          role: _selectedRole,
          permissions: _selectedPermissions,
        );

        // 성공 시 화면 닫기
        Get.back();
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
}

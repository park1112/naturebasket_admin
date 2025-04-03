// lib/screens/admin/admin_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/admin_management_controller.dart';
import '../../controllers/admin_auth_controller.dart';
import '../../models/admin_model.dart';
import '../../config/theme.dart';

class AdminDetailScreen extends StatefulWidget {
  final AdminModel admin;

  const AdminDetailScreen({Key? key, required this.admin}) : super(key: key);

  @override
  State<AdminDetailScreen> createState() => _AdminDetailScreenState();
}

class _AdminDetailScreenState extends State<AdminDetailScreen> {
  final AdminManagementController _managementController =
      Get.find<AdminManagementController>();
  final AdminAuthController _authController = Get.find<AdminAuthController>();

  bool _isEditing = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late AdminRole _selectedRole;
  late List<String> _selectedPermissions;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.admin.name);
    _selectedRole = widget.admin.role;
    _selectedPermissions = List.from(widget.admin.permissions);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '관리자 정보 수정' : '관리자 정보'),
        actions: [
          if (_authController.hasPermission('edit_admin') && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _nameController.text = widget.admin.name;
                  _selectedRole = widget.admin.role;
                  _selectedPermissions = List.from(widget.admin.permissions);
                  _isEditing = false;
                });
              },
            ),
        ],
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
                    _buildProfileHeader(isSmallScreen),
                    SizedBox(height: isSmallScreen ? 24 : 32),
                    if (isSmallScreen)
                      _buildAdminInfoCard(isSmallScreen)
                    else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildAdminInfoCard(isSmallScreen),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 3,
                            child: _buildPermissionsCard(isSmallScreen),
                          ),
                        ],
                      ),
                    if (isSmallScreen) ...[
                      const SizedBox(height: 24),
                      _buildPermissionsCard(isSmallScreen),
                    ],
                    const SizedBox(height: 24),
                    _buildActionButtons(isSmallScreen),
                  ],
                ),
              ),
            );
          });
        },
      ),
      bottomNavigationBar: _isEditing
          ? BottomAppBar(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: const Text(
                    '변경사항 저장',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildProfileHeader(bool isSmallScreen) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
        child: Row(
          children: [
            CircleAvatar(
              radius: isSmallScreen ? 30 : 40,
              backgroundColor: Colors.blue.withOpacity(0.1),
              backgroundImage: widget.admin.photoURL != null
                  ? NetworkImage(widget.admin.photoURL!)
                  : null,
              child: widget.admin.photoURL == null
                  ? Icon(
                      Icons.person,
                      size: isSmallScreen ? 30 : 40,
                      color: Colors.blue,
                    )
                  : null,
            ),
            SizedBox(width: isSmallScreen ? 16 : 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isEditing)
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: '이름',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '이름을 입력해주세요.';
                        }
                        return null;
                      },
                    )
                  else
                    Text(
                      widget.admin.name,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 20 : 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  SizedBox(height: isSmallScreen ? 4 : 8),
                  Text(
                    widget.admin.email,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 8 : 12),
                  Row(
                    children: [
                      _buildRoleChip(_getRoleDisplayName(widget.admin.role)),
                      const SizedBox(width: 8),
                      _buildStatusBadge(widget.admin.isActive),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminInfoCard(bool isSmallScreen) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '관리자 정보',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildInfoItem(
                '역할',
                _isEditing
                    ? _buildRoleSelector()
                    : _getRoleDisplayName(widget.admin.role)),
            _buildInfoItem('생성자', widget.admin.createdBy),
            _buildInfoItem('생성일', _formatDate(widget.admin.createdAt)),
            _buildInfoItem('마지막 로그인', _formatDate(widget.admin.lastLogin)),
            _buildInfoItem(
                '상태',
                _isEditing
                    ? Switch(
                        value: widget.admin.isActive,
                        onChanged:
                            _authController.hasPermission('toggle_admin_status')
                                ? (value) {
                                    setState(() {
                                      // 상태 변경은 저장 시 적용됩니다.
                                    });
                                  }
                                : null,
                      )
                    : _buildStatusBadge(widget.admin.isActive)),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsCard(bool isSmallScreen) {
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
                  '권한 정보',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_isEditing && _selectedRole != AdminRole.superAdmin)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        if (_selectedPermissions.length ==
                            _getAllPermissions().length) {
                          _selectedPermissions.clear();
                        } else {
                          _selectedPermissions =
                              List.from(_getAllPermissions());
                        }
                      });
                    },
                    icon: Icon(
                      _selectedPermissions.length == _getAllPermissions().length
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      size: 18,
                    ),
                    label: Text(
                      _selectedPermissions.length == _getAllPermissions().length
                          ? '전체 해제'
                          : '전체 선택',
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            if (_selectedRole == AdminRole.superAdmin)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '최고 관리자는 모든 권한을 가지고 있습니다.',
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              _buildPermissionList(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: value is Widget
                ? value
                : Text(
                    value.toString(),
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelector() {
    return DropdownButton<AdminRole>(
      value: _selectedRole,
      isExpanded: true,
      onChanged: _authController.hasPermission('edit_admin_role')
          ? (AdminRole? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedRole = newValue;

                  // 최고 관리자로 변경 시 모든 권한 부여
                  if (newValue == AdminRole.superAdmin) {
                    _selectedPermissions = List.from(_getAllPermissions());
                  }
                });
              }
            }
          : null,
      items:
          AdminRole.values.map<DropdownMenuItem<AdminRole>>((AdminRole role) {
        return DropdownMenuItem<AdminRole>(
          value: role,
          child: Text(_getRoleDisplayName(role)),
        );
      }).toList(),
    );
  }

  Widget _buildPermissionList() {
    List<String> permissions = _getAllPermissions();
    Map<String, List<String>> groupedPermissions =
        _groupPermissions(permissions);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
    );
  }

  Widget _buildPermissionChip(String permission) {
    bool isSelected = _selectedPermissions.contains(permission);

    return FilterChip(
      label: Text(_getPermissionDisplayName(permission)),
      selected: isSelected,
      onSelected: _isEditing &&
              _authController.hasPermission('edit_admin_permissions') &&
              _selectedRole != AdminRole.superAdmin
          ? (bool selected) {
              setState(() {
                if (selected) {
                  _selectedPermissions.add(permission);
                } else {
                  _selectedPermissions.remove(permission);
                }
              });
            }
          : null,
      backgroundColor: Colors.grey.shade100,
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildActionButtons(bool isSmallScreen) {
    if (_isEditing) {
      return const SizedBox.shrink(); // 편집 모드에서는 하단 버튼 사용
    }

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        if (_authController.hasPermission('reset_admin_password'))
          ElevatedButton.icon(
            onPressed: () => _showResetPasswordDialog(),
            icon: const Icon(Icons.password),
            label: const Text('비밀번호 재설정'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              minimumSize: Size(isSmallScreen ? double.infinity : 200, 48),
            ),
          ),
        if (_authController.hasPermission('toggle_admin_status'))
          ElevatedButton.icon(
            onPressed: () => _showToggleStatusConfirmation(),
            icon:
                Icon(widget.admin.isActive ? Icons.block : Icons.check_circle),
            label: Text(widget.admin.isActive ? '계정 비활성화' : '계정 활성화'),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  widget.admin.isActive ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
              minimumSize: Size(isSmallScreen ? double.infinity : 200, 48),
            ),
          ),
      ],
    );
  }

  Widget _buildRoleChip(String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        role,
        style: const TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isActive ? '활성' : '비활성',
        style: TextStyle(
          fontSize: 12,
          color: isActive ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
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

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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

  void _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      // 관리자 정보 업데이트
      await _managementController.updateAdmin(
        widget.admin.uid,
        name: _nameController.text,
        role: _selectedRole,
        permissions: _selectedPermissions,
      );

      // 편집 모드 종료
      setState(() {
        _isEditing = false;
      });
    }
  }

  void _showResetPasswordDialog() {
    final TextEditingController passwordController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    Get.dialog(
      AlertDialog(
        title: const Text('비밀번호 재설정'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${widget.admin.name} 관리자의 비밀번호를 재설정합니다.',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: '새 비밀번호',
                  border: OutlineInputBorder(),
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
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Get.back();
                await _managementController.resetAdminPassword(
                  widget.admin.uid,
                  passwordController.text,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('재설정'),
          ),
        ],
      ),
    );
  }

  void _showToggleStatusConfirmation() {
    final bool isDeactivating = widget.admin.isActive;
    Get.dialog(
      AlertDialog(
        title: Text(isDeactivating ? '관리자 비활성화' : '관리자 활성화'),
        content: Text(isDeactivating
            ? '${widget.admin.name} 관리자의 계정을 비활성화하시겠습니까? 비활성화된 계정은 로그인할 수 없습니다.'
            : '${widget.admin.name} 관리자의 계정을 활성화하시겠습니까? 활성화된 계정은 로그인할 수 있습니다.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              if (isDeactivating) {
                await _managementController.deactivateAdmin(widget.admin.uid);
              } else {
                await _managementController.activateAdmin(widget.admin.uid);
              }
              // 변경 사항 반영을 위해 관리자 목록 다시 로드
              await _managementController.loadAdmins();
              Get.back(); // 상세 화면 닫기
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDeactivating ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(isDeactivating ? '비활성화' : '활성화'),
          ),
        ],
      ),
    );
  }
}

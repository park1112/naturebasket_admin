// lib/screens/admin/admin_management_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/admin_management_controller.dart';
import '../../controllers/admin_auth_controller.dart';
import '../../models/admin_model.dart';
import 'add_admin_screen.dart';
import 'admin_detail_screen.dart';
import 'activity_logs_screen.dart';

class AdminManagementScreen extends StatelessWidget {
  const AdminManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AdminManagementController controller =
        Get.find<AdminManagementController>();
    final AdminAuthController authController = Get.find<AdminAuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('관리자 관리'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Get.to(() => const ActivityLogsScreen());
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadAdmins(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (controller.admins.isEmpty) {
          return const Center(
            child: Text('등록된 관리자가 없습니다.'),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            bool isSmallScreen = constraints.maxWidth < 600;

            if (isSmallScreen) {
              // 모바일 레이아웃
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: controller.admins.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final admin = controller.admins[index];
                  return _buildAdminListItem(admin, authController, controller,
                      isSmallScreen, context);
                },
              );
            } else {
              // 태블릿/데스크톱 레이아웃
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(authController),
                    const SizedBox(height: 24),
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  '관리자 목록',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                _buildAddAdminButton(authController),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 8),
                            _buildAdminListHeader(),
                            const Divider(),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: controller.admins.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(),
                              itemBuilder: (context, index) {
                                final admin = controller.admins[index];
                                return _buildAdminListItem(admin,
                                    authController, controller, false, context);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
          },
        );
      }),
      floatingActionButton: Obx(() {
        if (authController.hasPermission('create_admin')) {
          return FloatingActionButton(
            onPressed: () => Get.to(() => const AddAdminScreen()),
            child: const Icon(Icons.add),
          );
        }
        return const SizedBox.shrink();
      }),
    );
  }

  Widget _buildHeader(AdminAuthController authController) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blue.withOpacity(0.1),
              child: const Icon(
                Icons.admin_panel_settings,
                color: Colors.blue,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '관리자 계정 관리',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '관리자 계정을 생성하고 권한을 관리할 수 있습니다.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            _buildAddAdminButton(authController),
          ],
        ),
      ),
    );
  }

  Widget _buildAddAdminButton(AdminAuthController authController) {
    if (authController.hasPermission('create_admin')) {
      return ElevatedButton.icon(
        onPressed: () => Get.to(() => const AddAdminScreen()),
        icon: const Icon(Icons.add),
        label: const Text('관리자 추가'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildAdminListHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '이름',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              '이메일',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '권한',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '상태',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '마지막 로그인',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 100),
        ],
      ),
    );
  }

  Widget _buildAdminListItem(
    AdminModel admin,
    AdminAuthController authController,
    AdminManagementController controller,
    bool isSmallScreen,
    BuildContext context,
  ) {
    if (isSmallScreen) {
      // 모바일 레이아웃 - 카드 형태
      return Card(
        elevation: 1,
        child: InkWell(
          onTap: () => Get.to(() => AdminDetailScreen(admin: admin)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      backgroundImage: admin.photoURL != null
                          ? NetworkImage(admin.photoURL!)
                          : null,
                      child: admin.photoURL == null
                          ? const Icon(
                              Icons.person,
                              color: Colors.blue,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            admin.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            admin.email,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(admin.isActive),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.verified_user,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getRoleDisplayName(admin.role),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '마지막 로그인: ${_formatDate(admin.lastLogin)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (authController.hasPermission('edit_admin'))
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        color: Colors.blue,
                        onPressed: () {
                          Get.to(() => AdminDetailScreen(admin: admin));
                        },
                      ),
                    if (authController.hasPermission('toggle_admin_status'))
                      IconButton(
                        icon: Icon(
                          admin.isActive ? Icons.block : Icons.check_circle,
                          size: 20,
                        ),
                        color: admin.isActive ? Colors.red : Colors.green,
                        onPressed: () {
                          _showToggleStatusConfirmation(
                              context, admin, controller);
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // 태블릿/데스크톱 레이아웃 - 테이블 행
      return InkWell(
        onTap: () => Get.to(() => AdminDetailScreen(admin: admin)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      backgroundImage: admin.photoURL != null
                          ? NetworkImage(admin.photoURL!)
                          : null,
                      child: admin.photoURL == null
                          ? const Icon(
                              Icons.person,
                              color: Colors.blue,
                              size: 16,
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        admin.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  admin.email,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(_getRoleDisplayName(admin.role)),
              ),
              Expanded(
                flex: 2,
                child: _buildStatusBadge(admin.isActive),
              ),
              Expanded(
                flex: 2,
                child: Text(_formatDate(admin.lastLogin)),
              ),
              SizedBox(
                width: 100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (authController.hasPermission('edit_admin'))
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        color: Colors.blue,
                        onPressed: () {
                          Get.to(() => AdminDetailScreen(admin: admin));
                        },
                      ),
                    if (authController.hasPermission('toggle_admin_status'))
                      IconButton(
                        icon: Icon(
                          admin.isActive ? Icons.block : Icons.check_circle,
                          size: 20,
                        ),
                        color: admin.isActive ? Colors.red : Colors.green,
                        onPressed: () {
                          _showToggleStatusConfirmation(
                              context, admin, controller);
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
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
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _showToggleStatusConfirmation(
    BuildContext context,
    AdminModel admin,
    AdminManagementController controller,
  ) {
    final bool isDeactivating = admin.isActive;
    Get.dialog(
      AlertDialog(
        title: Text(isDeactivating ? '관리자 비활성화' : '관리자 활성화'),
        content: Text(isDeactivating
            ? '${admin.name} 관리자의 계정을 비활성화하시겠습니까? 비활성화된 계정은 로그인할 수 없습니다.'
            : '${admin.name} 관리자의 계정을 활성화하시겠습니까? 활성화된 계정은 로그인할 수 있습니다.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              if (isDeactivating) {
                await controller.deactivateAdmin(admin.uid);
              } else {
                await controller.activateAdmin(admin.uid);
              }
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

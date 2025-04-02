// lib/screens/admin/admin_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_login_template/screens/admin/product/add_product_screen.dart';
import 'package:flutter_login_template/screens/admin/product/product_list_screen.dart'
    as product;
import 'package:get/get.dart';
import '../../controllers/admin_auth_controller.dart';
import '../../models/admin_model.dart';
import '../../config/theme.dart';
import 'admin_management_screen.dart';
import 'widgets/stats_card.dart';
import 'widgets/recent_activities_widget.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AdminAuthController authController = Get.find<AdminAuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('네이처바스켓 어드민'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // 알림 화면으로 이동
            },
          ),
          Obx(() => PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'profile') {
                    // 프로필 화면으로 이동
                  } else if (value == 'password') {
                    _showChangePasswordDialog(context, authController);
                  } else if (value == 'logout') {
                    _showLogoutConfirmation(context, authController);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundImage: authController
                                      .currentAdmin.value?.photoURL !=
                                  null
                              ? NetworkImage(
                                  authController.currentAdmin.value!.photoURL!)
                              : null,
                          child: authController.currentAdmin.value?.photoURL ==
                                  null
                              ? const Icon(Icons.person, size: 14)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(authController.currentAdmin.value?.name ?? '관리자'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'password',
                    child: Row(
                      children: [
                        Icon(Icons.lock, size: 16),
                        SizedBox(width: 8),
                        Text('비밀번호 변경'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 16),
                        SizedBox(width: 8),
                        Text('로그아웃'),
                      ],
                    ),
                  ),
                ],
              )),
        ],
      ),
      drawer: _buildAdminDrawer(authController),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isSmallScreen = constraints.maxWidth < 600;
          bool isLargeScreen = constraints.maxWidth >= 1200;

          if (isSmallScreen) {
            // 모바일 레이아웃
            return _buildMobileLayout(authController);
          } else if (isLargeScreen) {
            // 큰 화면 레이아웃
            return _buildLargeScreenLayout(authController);
          } else {
            // 태블릿 레이아웃
            return _buildTabletLayout(authController);
          }
        },
      ),
    );
  }

  Widget _buildWelcomeCard(AdminAuthController authController) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(() {
                    final admin = authController.currentAdmin.value;
                    return Text(
                      '안녕하세요, ${admin?.name ?? '관리자'}님!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  Text(
                    '${DateTime.now().year}년 ${DateTime.now().month}월 ${DateTime.now().day}일',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '네이처바스켓 관리자 페이지에 오신 것을 환영합니다. 필요한 정보를 확인하고 관리하세요.',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            CircleAvatar(
              radius: 40,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: const Icon(
                Icons.dashboard,
                size: 40,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '주요 지표',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Column(
          children: [
            StatsCard(
              title: '총 매출',
              value: '4,568,000원',
              icon: Icons.attach_money,
              color: Colors.green,
              trend: '+12.5%',
              isPositiveTrend: true,
            ),
            const SizedBox(height: 16),
            StatsCard(
              title: '총 주문',
              value: '245건',
              icon: Icons.shopping_cart,
              color: Colors.blue,
              trend: '+8.2%',
              isPositiveTrend: true,
            ),
            const SizedBox(height: 16),
            StatsCard(
              title: '신규 회원',
              value: '38명',
              icon: Icons.person_add,
              color: Colors.purple,
              trend: '+5.7%',
              isPositiveTrend: true,
            ),
            const SizedBox(height: 16),
            StatsCard(
              title: '품절 상품',
              value: '12개',
              icon: Icons.inventory,
              color: Colors.orange,
              trend: '-2.3%',
              isPositiveTrend: false,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStatsGrid({required int columns}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '주요 지표',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: columns,
          childAspectRatio: 1.5,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: const [
            StatsCard(
              title: '총 매출',
              value: '4,568,000원',
              icon: Icons.attach_money,
              color: Colors.green,
              trend: '+12.5%',
              isPositiveTrend: true,
            ),
            StatsCard(
              title: '총 주문',
              value: '245건',
              icon: Icons.shopping_cart,
              color: Colors.blue,
              trend: '+8.2%',
              isPositiveTrend: true,
            ),
            StatsCard(
              title: '신규 회원',
              value: '38명',
              icon: Icons.person_add,
              color: Colors.purple,
              trend: '+5.7%',
              isPositiveTrend: true,
            ),
            StatsCard(
              title: '품절 상품',
              value: '12개',
              icon: Icons.inventory,
              color: Colors.orange,
              trend: '-2.3%',
              isPositiveTrend: false,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentActivitiesSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '최근 활동',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // 전체 활동 내역 페이지로 이동
                  },
                  child: const Text('전체보기'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const RecentActivitiesWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessSection(AdminAuthController authController) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '빠른 접근',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildQuickAccessButton(
              icon: Icons.add_shopping_cart,
              title: '상품 등록',
              onPressed: () {
                Get.to(() => const AddProductScreen());
              },
              isEnabled: authController.hasPermission('create_product'),
            ),
            const SizedBox(height: 12),
            _buildQuickAccessButton(
              icon: Icons.edit_note,
              title: '주문 관리',
              onPressed: () {
                // 주문 관리 페이지로 이동
              },
              isEnabled: authController.hasPermission('update_order_status'),
            ),
            const SizedBox(height: 12),
            _buildQuickAccessButton(
              icon: Icons.people,
              title: '회원 관리',
              onPressed: () {
                // 회원 관리 페이지로 이동
              },
              isEnabled: authController.hasPermission('view_customers'),
            ),
            const SizedBox(height: 12),
            _buildQuickAccessButton(
              icon: Icons.admin_panel_settings,
              title: '관리자 관리',
              onPressed: () {
                Get.to(() => const AdminManagementScreen());
              },
              isEnabled: authController.hasPermission('view_admins'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessButton({
    required IconData icon,
    required String title,
    required VoidCallback onPressed,
    required bool isEnabled,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isEnabled ? onPressed : null,
        icon: Icon(icon),
        label: Text(title),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          disabledForegroundColor: Colors.grey.shade500,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }

  void _showChangePasswordDialog(
      BuildContext context, AdminAuthController authController) {
    final TextEditingController currentPasswordController =
        TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    Get.dialog(
      AlertDialog(
        title: const Text('비밀번호 변경'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentPasswordController,
                decoration: const InputDecoration(
                  labelText: '현재 비밀번호',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '현재 비밀번호를 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: newPasswordController,
                decoration: const InputDecoration(
                  labelText: '새 비밀번호',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '새 비밀번호를 입력해주세요.';
                  }
                  if (value.length < 8) {
                    return '비밀번호는 8자 이상이어야 합니다.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: '새 비밀번호 확인',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '새 비밀번호를 다시 입력해주세요.';
                  }
                  if (value != newPasswordController.text) {
                    return '비밀번호가 일치하지 않습니다.';
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
          Obx(() => ElevatedButton(
                onPressed: authController.isLoading.value
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          final bool success =
                              await authController.changePassword(
                            currentPasswordController.text,
                            newPasswordController.text,
                          );
                          if (success) {
                            Get.back();
                          }
                        }
                      },
                child: authController.isLoading.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('변경'),
              )),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(
      BuildContext context, AdminAuthController authController) {
    Get.dialog(
      AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await authController.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminDrawer(AdminAuthController authController) {
    return Drawer(
      child: Column(
        children: [
          Obx(() {
            final admin = authController.currentAdmin.value;

            return UserAccountsDrawerHeader(
              accountName: Text(admin?.name ?? '관리자'),
              accountEmail: Text(admin?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundImage: admin?.photoURL != null
                    ? NetworkImage(admin!.photoURL!)
                    : null,
                child:
                    admin?.photoURL == null ? const Icon(Icons.person) : null,
              ),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
              ),
            );
          }),
          _buildDrawerItem(
            icon: Icons.dashboard,
            title: '대시보드',
            onTap: () {
              Get.back(); // 드로어 닫기
              // 이미 대시보드 화면이면 아무 작업 안함
            },
          ),
          if (authController.hasPermission('view_products'))
            _buildDrawerItem(
              icon: Icons.inventory,
              title: '상품 관리',
              onTap: () {
                Get.back();
                Get.to(() => const product.ProductListScreen());
              },
            ),
          if (authController.hasPermission('view_orders'))
            _buildDrawerItem(
              icon: Icons.shopping_cart,
              title: '주문 관리',
              onTap: () {
                Get.back();
                // 주문 관리 화면으로 이동
              },
            ),
          if (authController.hasPermission('view_customers'))
            _buildDrawerItem(
              icon: Icons.people,
              title: '회원 관리',
              onTap: () {
                Get.back();
                // 회원 관리 화면으로 이동
              },
            ),
          if (authController.hasPermission('view_promotions'))
            _buildDrawerItem(
              icon: Icons.local_offer,
              title: '마케팅 관리',
              onTap: () {
                Get.back();
                // 마케팅 관리 화면으로 이동
              },
            ),
          if (authController.hasPermission('view_content'))
            _buildDrawerItem(
              icon: Icons.article,
              title: '콘텐츠 관리',
              onTap: () {
                Get.back();
                // 콘텐츠 관리 화면으로 이동
              },
            ),
          if (authController.hasPermission('view_admins'))
            _buildDrawerItem(
              icon: Icons.admin_panel_settings,
              title: '관리자 관리',
              onTap: () {
                Get.back();
                Get.to(() => const AdminManagementScreen());
              },
            ),
          if (authController.hasPermission('view_settings'))
            _buildDrawerItem(
              icon: Icons.settings,
              title: '설정',
              onTap: () {
                Get.back();
                // 설정 화면으로 이동
              },
            ),
          const Spacer(),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.logout,
            title: '로그아웃',
            onTap: () {
              Get.back();
              _showLogoutConfirmation(Get.context!, authController);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }

  Widget _buildMobileLayout(AdminAuthController authController) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(authController),
          const SizedBox(height: 24),
          _buildQuickStatsSection(),
          const SizedBox(height: 24),
          _buildRecentActivitiesSection(),
          const SizedBox(height: 24),
          _buildQuickAccessSection(authController),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(AdminAuthController authController) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(authController),
          const SizedBox(height: 24),
          _buildQuickStatsGrid(columns: 2),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _buildRecentActivitiesSection(),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: _buildQuickAccessSection(authController),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLargeScreenLayout(AdminAuthController authController) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(authController),
          const SizedBox(height: 32),
          _buildQuickStatsGrid(columns: 4),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _buildRecentActivitiesSection(),
              ),
              const SizedBox(width: 32),
              Expanded(
                flex: 2,
                child: _buildQuickAccessSection(authController),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// lib/screens/admin/admin_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_login_template/controllers/admin_management_controller.dart';
import 'package:flutter_login_template/controllers/dashboard_controller.dart';
import 'package:flutter_login_template/screens/admin/activity_logs_screen.dart';
import 'package:flutter_login_template/screens/admin/product/add_product_screen.dart';
import 'package:flutter_login_template/screens/admin/product/product_list_screen.dart'
    as product;
import 'package:flutter_login_template/screens/dashboard/dashboard_screen.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/admin_auth_controller.dart';
import '../../models/admin_model.dart';
import '../../config/theme.dart';
import 'admin_management_screen.dart';
import 'widgets/stats_card.dart';
import 'widgets/recent_activities_widget.dart';
import '../../controllers/product_controller.dart';
import '../../controllers/order_controller.dart';
// import '../../controllers/customer_controller.dart';
// import '../../screens/admin/order_list_screen.dart';
// import '../../screens/admin/customer_list_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({Key? key}) : super(key: key);

  String _formatNumber(num number) {
    return NumberFormat('#,###').format(number);
  }

  @override
  Widget build(BuildContext context) {
    final AdminAuthController authController = Get.find<AdminAuthController>();
    final DashboardController dashboardController =
        Get.find<DashboardController>();
    // Make sure AdminManagementController is put in app.dart if not already
    final AdminManagementController managementController =
        Get.find<AdminManagementController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('네이처바스켓 어드민'),
        actions: [
          LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = MediaQuery.of(context).size.width;

              if (screenWidth < 600) {
                // 모바일 화면에서는 더보기 메뉴로 통합
                return PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    switch (value) {
                      case 'notifications':
                        // 알림 화면으로 이동
                        break;
                      case 'password':
                        _showChangePasswordDialog(context, authController);
                        break;
                      case 'logout':
                        _showLogoutConfirmation(context, authController);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'notifications',
                      child: Row(
                        children: [
                          Icon(Icons.notifications_outlined, size: 16),
                          SizedBox(width: 8),
                          Text('알림'),
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
                );
              }

              // 태블릿/데스크톱 화면
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      // 알림 화면으로 이동
                    },
                  ),
                  Obx(() => PopupMenuButton<String>(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundImage: authController
                                            .currentAdmin.value?.photoURL !=
                                        null
                                    ? NetworkImage(authController
                                        .currentAdmin.value!.photoURL!)
                                    : null,
                                child: authController
                                            .currentAdmin.value?.photoURL ==
                                        null
                                    ? const Icon(Icons.person, size: 14)
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                authController.currentAdmin.value?.name ??
                                    '관리자',
                                style: const TextStyle(color: Colors.white),
                              ),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                        onSelected: (value) {
                          if (value == 'password') {
                            _showChangePasswordDialog(context, authController);
                          } else if (value == 'logout') {
                            _showLogoutConfirmation(context, authController);
                          }
                        },
                        itemBuilder: (context) => [
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
              );
            },
          ),
        ],
      ),
      drawer: _buildAdminDrawer(authController),
      body: Obx(() {
        // Wrap body with Obx for reactivity to multiple controllers
        // Check combined loading state
        if (dashboardController.isLoading.value ||
            managementController.isLoadingRecentLogs.value) {
          return const Center(child: CircularProgressIndicator());
        }

        // Check for essential data, show error or empty state if needed
        final summary = dashboardController.summary.value;
        // Add checks for other necessary data if needed

        return LayoutBuilder(
          builder: (context, constraints) {
            bool isSmallScreen = constraints.maxWidth < 600;
            bool isLargeScreen = constraints.maxWidth >= 1200;

            if (isSmallScreen) {
              return _buildMobileLayout(authController, dashboardController,
                  managementController, summary);
            } else if (isLargeScreen) {
              return _buildLargeScreenLayout(authController,
                  dashboardController, managementController, summary);
            } else {
              return _buildTabletLayout(authController, dashboardController,
                  managementController, summary);
            }
          },
        );
      }),
    );
  }

  Widget _buildWelcomeCard(AdminAuthController authController) {
    // ... (Welcome card code remains mostly the same, using Obx inside if needed) ...
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
                    // Use Obx here for reactivity
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
                    DateFormat('yyyy년 MM월 dd일')
                        .format(DateTime.now()), // Use DateFormat
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
            // ... (Icon remains the same) ...
          ],
        ),
      ),
    );
  }

  // Updated to use Wrap and real data
  Widget _buildQuickStatsSection(
      DashboardController dashboardController, dynamic summary) {
    // Safely extract data with defaults
    final totalSales = summary?.totalSales ?? 0.0;
    final totalOrders = summary?.totalOrders ?? 0;
    final newUsers = summary?.newUsers ?? 0;
    final productsSoldCount =
        summary?.productsSold ?? 0; // Example, adjust field name if needed

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
        Wrap(
          // Use Wrap for flexible layout
          spacing: 16, // Horizontal spacing
          runSpacing: 16, // Vertical spacing
          children: [
            StatsCard(
              title: '총 매출',
              value: '${_formatNumber(totalSales)}원', // Use formatter
              icon: Icons.attach_money,
              color: Colors.green,
              // trend: '+12.5%', // Fetch real trend data if available
              // isPositiveTrend: true,
            ),
            StatsCard(
              title: '총 주문',
              value: '${_formatNumber(totalOrders)}건', // Use formatter
              icon: Icons.shopping_cart,
              color: Colors.blue,
              // trend: '+8.2%',
              // isPositiveTrend: true,
            ),
            StatsCard(
              title: '신규 회원',
              value: '${_formatNumber(newUsers)}명', // Use formatter
              icon: Icons.person_add,
              color: Colors.purple,
              // trend: '+5.7%',
              // isPositiveTrend: true,
            ),
            StatsCard(
              title: '판매 상품 수', // Changed from '품절 상품'
              value: '${_formatNumber(productsSoldCount)}개', // Use real data
              icon: Icons.inventory_2, // Different icon maybe
              color: Colors.orange,
              // trend: '-2.3%', // Fetch real trend data if available
              // isPositiveTrend: false,
            ),
            // Add more StatsCard if needed based on your summary data
          ],
        )
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

  // Updated to pass data
  Widget _buildRecentActivitiesSection(
      AdminManagementController managementController) {
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
                    // Navigate to the full ActivityLogsScreen
                    Get.to(() => const ActivityLogsScreen());
                  },
                  child: const Text('전체보기'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // RecentActivitiesWidget now fetches its own data via controller
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
            // _buildQuickAccessButton(
            //   icon: Icons.edit_note,
            //   title: '주문 관리',
            //   onPressed: () {
            //     Get.put(OrderController());
            //     Get.to(() => const OrderListScreen());
            //   },
            //   isEnabled: authController.hasPermission('view_orders'),
            // ),
            // const SizedBox(height: 12),
            // _buildQuickAccessButton(
            //   icon: Icons.people,
            //   title: '회원 관리',
            //   onPressed: () {
            //     Get.put(CustomerController());
            //     Get.to(() => const CustomerListScreen());
            //   },
            //   isEnabled: authController.hasPermission('view_customers'),
            // ),
            const SizedBox(height: 12),
            _buildQuickAccessButton(
              icon: Icons.admin_panel_settings,
              title: '관리자 관리',
              onPressed: () {
                Get.to(() => const AdminManagementScreen());
              },
              isEnabled: authController.hasPermission('view_admins'),
            ),
            const SizedBox(height: 12),
            _buildQuickAccessButton(
              icon: Icons.bar_chart,
              title: '상세 대시보드',
              onPressed: () {
                Get.to(() => const DashboardScreen());
              },
              isEnabled: authController.hasPermission('view_dashboard'),
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
                if (!Get.isRegistered<ProductController>()) {
                  Get.put(ProductController());
                }
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

  Widget _buildMobileLayout(
      AdminAuthController authController,
      DashboardController dashboardController,
      AdminManagementController managementController,
      dynamic summary) {
    // Accept data
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(authController),
          const SizedBox(height: 24),
          _buildQuickStatsSection(dashboardController, summary), // Pass data
          const SizedBox(height: 24),
          _buildRecentActivitiesSection(
              managementController), // Pass controller
          const SizedBox(height: 24),
          _buildQuickAccessSection(authController),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(
      AdminAuthController authController,
      DashboardController dashboardController,
      AdminManagementController managementController,
      dynamic summary) {
    // Accept data
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(authController),
          const SizedBox(height: 24),
          // Use _buildQuickStatsSection for Wrap layout on tablet too
          _buildQuickStatsSection(dashboardController, summary), // Pass data
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _buildRecentActivitiesSection(
                    managementController), // Pass controller
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

  Widget _buildLargeScreenLayout(
      AdminAuthController authController,
      DashboardController dashboardController,
      AdminManagementController managementController,
      dynamic summary) {
    // Accept data
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(authController),
          const SizedBox(height: 32),
          _buildQuickStatsSection(
              dashboardController, summary), // Use Wrap here too
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _buildRecentActivitiesSection(
                    managementController), // Pass controller
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

void initControllers() {
  // 공통으로 사용되는 컨트롤러들 초기화
  Get.put(AdminAuthController());
  Get.put(DashboardController());
  Get.put(AdminManagementController());

  // 필요한 경우에만 초기화하는 컨트롤러들은 해당 페이지로 이동할 때 초기화
  // Get.lazyPut(() => ProductController());
  // Get.lazyPut(() => OrderController());
  // Get.lazyPut(() => CustomerController());
}

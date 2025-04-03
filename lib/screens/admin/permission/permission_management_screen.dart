// // lib/screens/admin/permission/permission_management_screen.dart
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../../../controllers/admin_management_controller.dart';
// import '../../../controllers/admin_auth_controller.dart';
// import '../../../models/admin_model.dart';
// import '../../../config/theme.dart';

// class PermissionManagementScreen extends StatefulWidget {
//   const PermissionManagementScreen({Key? key}) : super(key: key);

//   @override
//   State<PermissionManagementScreen> createState() => _PermissionManagementScreenState();
// }

// class _PermissionManagementScreenState extends State<PermissionManagementScreen> {
//   final AdminManagementController _managementController = Get.find<AdminManagementController>();
//   final AdminAuthController _authController = Get.find<AdminAuthController>();
  
//   // 선택된 관리자 ID
//   String? _selectedAdminId;
  
//   @override
//   void initState() {
//     super.initState();
//     _managementController.loadAdmins();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('권한 관리'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: () => _managementController.loadAdmins(),
//           ),
//         ],
//       ),
//       body: Obx(() {
//         if (_managementController.isLoading.value) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         // 데이터가 없는 경우
//         if (_managementController.admins.isEmpty) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
//                 const SizedBox(height: 16),
//                 const Text(
//                   '등록된 관리자가 없습니다.',
//                   style: TextStyle(
//                     fontSize: 16,
//                     color: Colors.grey,
//                   ),
//                 ),
//               ],
//             ),
//           );
//         }

//         return LayoutBuilder(
//           builder: (context, constraints) {
//             bool isSmallScreen = constraints.maxWidth < 800;
            
//             if (isSmallScreen) {
//               // 모바일 레이아웃: 목록 선택 후 상세 화면으로 이동
//               return _buildAdminList();
//             } else {
//               // 태블릿/데스크톱 레이아웃: 좌측에 목록, 우측에 상세 정보
//               return Row(
//                 children: [
//                   // 관리자 목록 (좌측)
//                   SizedBox(
//                     width: 300,
//                     child: _buildAdminList(),
//                   ),
                  
//                   // 수직 구분선
//                   const VerticalDivider(width: 1),
                  
//                   // 권한 관리 상세 (우측)
//                   Expanded(
//                     child: _selectedAdminId != null
//                         ? _buildPermissionEditor(_getSelectedAdmin())
//                         : _buildEmptyPermissionEditor(),
//                   ),
//                 ],
//               );
//             }
//           },
//         );
//       }),
//     );
//   }

//   // 관리자 목록 위젯
//   Widget _buildAdminList() {
//     return Column(
//       children: [
//         // 헤더
//         Container(
//           padding: const EdgeInsets.all(16),
//           color: Colors.grey.shade100,
//           child: Row(
//             children: [
//               Icon(Icons.people, color: AppTheme.primaryColor),
//               const SizedBox(width: 8),
//               Text(
//                 '관리자 목록',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   color: AppTheme.primaryColor,
//                 ),
//               ),
//             ],
//           ),
//         ),
        
//         // 목록
//         Expanded(
//           child: ListView.separated(
//             itemCount: _managementController.admins.length,
//             separatorBuilder: (context, index) => const Divider(height: 1),
//             itemBuilder: (context, index) {
//               final admin = _managementController.admins[index];
//               final bool isCurrentAdmin = admin.uid == _authController.currentAdmin.value?.uid;
//               final bool isSelected = admin.uid == _selectedAdminId;

//               return ListTile(
//                 leading: CircleAvatar(
//                   backgroundColor: isSelected
//                       ? AppTheme.primaryColor
//                       : Colors.grey.shade200,
//                   child: Icon(
//                     Icons.person,
//                     color: isSelected ? Colors.white : Colors.grey.shade700,
//                   ),
//                 ),
//                 title: Text(
//                   admin.name,
//                   style: const TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 subtitle: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(admin.email),
//                     const SizedBox(height: 4),
//                     Row(
//                       children: [
//                         _buildRoleBadge(admin.role),
//                         const SizedBox(width: 8),
//                         _buildStatusBadge(admin.isActive),
//                         if (isCurrentAdmin) ...[
//                           const SizedBox(width: 8),
//                           Container(
//                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                             decoration: BoxDecoration(
//                               color: Colors.blue.withOpacity(0.1),
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: const Text(
//                               '현재 계정',
//                               style: TextStyle(
//                                 fontSize: 10,
//                                 color: Colors.blue,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ],
//                     ),
//                   ],
//                 ),
//                 selected: isSelected,
//                 selectedTileColor: AppTheme.primaryColor.withOpacity(0.05),
//                 onTap: () {
//                   setState(() {
//                     _selectedAdminId = admin.uid;
//                   });
                  
//                   // 모바일에서는 상세 화면으로 이동
//                   if (MediaQuery.of(context).size.width < 800) {
//                     _showPermissionScreen(admin);
//                   }
//                 },
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   // 권한 편집 상세 화면
//   Widget _buildPermissionEditor(AdminModel admin) {
//     // 권한 변경이 가능한지 확인
//     final bool isCurrentAdmin = admin.uid == _authController.currentAdmin.value?.uid;
//     final bool canEditRole = _authController.hasPermission('edit_admin_role') && !isCurrentAdmin;
//     final bool canEditPermissions = _authController.hasPermission('edit_admin_permissions') && !isCurrentAdmin;
//     final bool canToggleStatus = _authController.hasPermission('toggle_admin_status') && !isCurrentAdmin;

//     return Padding(
//       padding: const EdgeInsets.all(24),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // 관리자 정보 헤더
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               CircleAvatar(
//                 radius: 32,
//                 backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
//                 child: Text(
//                   admin.name.isNotEmpty ? admin.name[0].toUpperCase() : 'A',
//                   style: TextStyle(
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                     color: AppTheme.primaryColor,
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       admin.name,
//                       style: const TextStyle(
//                         fontSize: 24,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     Text(
//                       admin.email,
//                       style: TextStyle(
//                         fontSize: 16,
//                         color: Colors.grey.shade600,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Row(
//                       children: [
//                         _buildRoleBadge(admin.role),
//                         const SizedBox(width: 8),
//                         _buildStatusBadge(admin.isActive),
//                       ],
//                     ),
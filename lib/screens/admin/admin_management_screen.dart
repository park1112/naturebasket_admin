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
    final AdminManagementController controller = Get.find<AdminManagementController>();
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
                  final admin = controller.
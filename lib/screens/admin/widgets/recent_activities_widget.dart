// lib/screens/admin/widgets/recent_activities_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Import GetX if not already
import 'package:intl/intl.dart';
import '../../../models/admin_activity_log.dart'; // Import model
import '../../../controllers/admin_management_controller.dart'; // Import controller

class RecentActivitiesWidget extends StatelessWidget {
  const RecentActivitiesWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Find the controller
    final AdminManagementController controller =
        Get.find<AdminManagementController>();

    return Obx(() {
      // Make it reactive
      if (controller.isLoadingRecentLogs.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.activityLogs.isEmpty) {
        return const Center(child: Text('최근 활동이 없습니다.'));
      }

      // Use the fetched logs
      final activities = controller.activityLogs;

      return ListView.separated(
        shrinkWrap: true, // Important for usage inside Column/Row
        physics:
            const NeverScrollableScrollPhysics(), // Disable scrolling within widget
        itemCount: activities.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final activity = activities[index];
          return _buildActivityItem(activity);
        },
      );
    });
  }

  Widget _buildActivityItem(AdminActivityLog activity) {
    // Use AdminActivityLog model
    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            _getActivityColor(activity.targetType).withOpacity(0.1),
        child: Icon(
          _getActivityIcon(activity.targetType),
          color: _getActivityColor(activity.targetType),
          size: 18,
        ),
      ),
      title: Text(
          _getActionDisplayName(activity.action)), // Display formatted action
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Display target information if available
          if (activity.targetId.isNotEmpty)
            Text(
                '${_getTargetTypeDisplayName(activity.targetType)}: ${activity.targetId}'),
          const SizedBox(height: 4),
          Text(
            '${activity.adminName} · ${_formatTime(activity.timestamp)}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
      isThreeLine: activity.targetId.isNotEmpty, // Adjust based on content
      contentPadding: EdgeInsets.zero,
    );
  }

  // Helper methods (moved or adapted from activity_logs_screen.dart if needed)
  String _getActionDisplayName(String action) {
    // Add more specific action names if desired
    switch (action) {
      case 'login':
        return '로그인';
      case 'logout':
        return '로그아웃';
      case 'create_admin':
        return '관리자 생성';
      case 'update_admin':
        return '관리자 수정';
      case 'create_product':
        return '상품 생성';
      case 'update_product':
        return '상품 수정';
      case 'delete_product':
        return '상품 삭제';
      case 'update_inventory':
        return '재고 수정';
      case 'confirm_order':
        return '주문 확인';
      case 'ship_order':
        return '배송 시작';
      case 'cancel_order':
        return '주문 취소';
      default:
        return action.replaceAll('_', ' '); // Default formatting
    }
  }

  String _getTargetTypeDisplayName(String targetType) {
    switch (targetType) {
      case 'admin':
        return '관리자';
      case 'product':
        return '상품';
      case 'order':
        return '주문';
      case 'customer':
        return '고객';
      default:
        return targetType;
    }
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'order':
        return Colors.blue;
      case 'product':
        return Colors.green;
      case 'customer':
        return Colors.purple;
      case 'admin':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'order':
        return Icons.shopping_cart;
      case 'product':
        return Icons.inventory;
      case 'customer':
        return Icons.person;
      case 'admin':
        return Icons.admin_panel_settings;
      default:
        return Icons.info;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inSeconds < 60) {
      return '방금 전';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return DateFormat('MM-dd HH:mm').format(time); // Slightly shorter format
    }
  }
}

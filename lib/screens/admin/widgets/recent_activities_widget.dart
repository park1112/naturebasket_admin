// lib/screens/admin/widgets/recent_activities_widget.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RecentActivitiesWidget extends StatelessWidget {
  const RecentActivitiesWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 실제 구현에서는 Firestore에서 데이터를 가져옵니다.
    // 여기서는 예시 데이터를 사용합니다.
    final activities = [
      {
        'id': '1',
        'type': 'order',
        'action': '주문 확인',
        'user': '김철수',
        'time': DateTime.now().subtract(const Duration(minutes: 15)),
        'details': '주문 #12345',
      },
      {
        'id': '2',
        'type': 'product',
        'action': '상품 수정',
        'user': '박관리자',
        'time': DateTime.now().subtract(const Duration(hours: 2)),
        'details': '유기농 당근 1kg',
      },
      {
        'id': '3',
        'type': 'customer',
        'action': '회원 등록',
        'user': '시스템',
        'time': DateTime.now().subtract(const Duration(hours: 4)),
        'details': '이영희 (010-1234-5678)',
      },
      {
        'id': '4',
        'type': 'order',
        'action': '주문 취소',
        'user': '김철수',
        'time': DateTime.now().subtract(const Duration(hours: 6)),
        'details': '주문 #12340',
      },
      {
        'id': '5',
        'type': 'product',
        'action': '상품 등록',
        'user': '박관리자',
        'time': DateTime.now().subtract(const Duration(hours: 8)),
        'details': '유기농 토마토 500g',
      },
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activities.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final activity = activities[index];
        return _buildActivityItem(activity);
      },
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getActivityColor(activity['type']).withOpacity(0.1),
        child: Icon(
          _getActivityIcon(activity['type']),
          color: _getActivityColor(activity['type']),
          size: 18,
        ),
      ),
      title: Text(activity['action']),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(activity['details']),
          const SizedBox(height: 4),
          Text(
            '${activity['user']} · ${_formatTime(activity['time'])}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
      isThreeLine: true,
      contentPadding: EdgeInsets.zero,
    );
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
      case 'setting':
        return Colors.teal;
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
      case 'setting':
        return Icons.settings;
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
      return DateFormat('yyyy-MM-dd').format(time);
    }
  }
}

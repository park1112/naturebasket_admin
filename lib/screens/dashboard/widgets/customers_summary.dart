// lib/screens/dashboard/widgets/customers_summary.dart
import 'package:flutter/material.dart';
import '../../../models/dashboard_model.dart';

class CustomersSummary extends StatelessWidget {
  final CustomerStatistics stats;

  const CustomersSummary({Key? key, required this.stats}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 주요 지표
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: '신규 회원',
                value: '${stats.newUsers}명',
                icon: Icons.person_add,
                iconColor: Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: '활성 회원',
                value: '${stats.activeUsers}명',
                icon: Icons.people,
                iconColor: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: '평균 주문액',
                value: '${stats.averageOrderValue.toStringAsFixed(0)}원',
                icon: Icons.shopping_cart,
                iconColor: Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: '전환율',
                value: stats.activeUsers > 0
                    ? '${((stats.activeUsers / (stats.activeUsers + stats.newUsers)) * 100).toStringAsFixed(1)}%'
                    : '0%',
                icon: Icons.trending_up,
                iconColor: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: iconColor,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// lib/screens/dashboard/widgets/orders_summary.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class OrdersSummary extends StatelessWidget {
  final Map<String, dynamic> orderStatusCounts;

  const OrdersSummary({Key? key, required this.orderStatusCounts})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (orderStatusCounts.isEmpty) {
      return const Center(
        child: Text('데이터가 없습니다.'),
      );
    }

    // 상태별 색상 지정
    final statusColors = {
      'pending': Colors.blue,
      'confirmed': Colors.green,
      'processing': Colors.purple,
      'shipping': Colors.orange,
      'delivered': Colors.teal,
      'cancelled': Colors.red,
      'refunded': Colors.grey,
    };

    // 상태별 이름 지정
    final statusNames = {
      'pending': '주문 접수',
      'confirmed': '주문 확인',
      'processing': '처리 중',
      'shipping': '배송 중',
      'delivered': '배송 완료',
      'cancelled': '주문 취소',
      'refunded': '환불 완료',
    };

    // 차트 데이터 생성
    List<PieChartSectionData> sections = [];
    int totalOrders = 0;

    orderStatusCounts.forEach((status, count) {
      totalOrders += count as int;
    });

    orderStatusCounts.forEach((status, count) {
      final double percentage =
          totalOrders > 0 ? (count as int) / totalOrders * 100 : 0;

      sections.add(
        PieChartSectionData(
          color: statusColors[status] ?? Colors.grey,
          value: count.toDouble(),
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 60,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    });

    return Column(
      children: [
        // 파이 차트
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  // 터치 이벤트 처리 (필요시)
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // 범례
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: orderStatusCounts.entries.map((entry) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: statusColors[entry.key] ?? Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${statusNames[entry.key] ?? entry.key}: ${entry.value}',
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

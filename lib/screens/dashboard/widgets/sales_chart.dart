// lib/screens/dashboard/widgets/sales_chart.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SalesChart extends StatelessWidget {
  final List<Map<String, dynamic>> salesData;

  const SalesChart({Key? key, required this.salesData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (salesData.isEmpty) {
      return const Center(
        child: Text('데이터가 없습니다.'),
      );
    }

    // 최대값 계산
    double maxY = 0;
    for (var data in salesData) {
      double amount = data['amount'];
      if (amount > maxY) {
        maxY = amount;
      }
    }

    // 여유 공간을 위해 최대값 조정
    maxY *= 1.2;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: maxY / 5,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: salesData.length > 10
                  ? (salesData.length / 5).ceil().toDouble()
                  : 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value.toInt() < 0 || value.toInt() >= salesData.length) {
                  return const SizedBox.shrink();
                }

                final data = salesData[value.toInt()];
                String dateStr = data['date'];

                // 날짜 표시 형식 간소화
                if (dateStr.length > 7) {
                  dateStr = dateStr.substring(dateStr.length - 5);
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    dateStr,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: maxY / 5,
              getTitlesWidget: (double value, TitleMeta meta) {
                String text = '';
                if (value >= 1000000) {
                  text = '${(value / 1000000).toStringAsFixed(1)}M';
                } else if (value >= 1000) {
                  text = '${(value / 1000).toStringAsFixed(1)}K';
                } else {
                  text = value.toStringAsFixed(0);
                }

                return Text(
                  text,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withOpacity(0.5)),
        ),
        minX: 0,
        maxX: (salesData.length - 1).toDouble(),
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(salesData.length, (index) {
              return FlSpot(index.toDouble(), salesData[index]['amount']);
            }),
            isCurved: true,
            color: Theme.of(context).primaryColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: salesData.length < 20,
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).primaryColor.withOpacity(0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.shade800,
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final index = barSpot.x.toInt();
                final data = salesData[index];
                final dateStr = data['date'];
                final amount = data['amount'];

                return LineTooltipItem(
                  '${dateStr}\n',
                  const TextStyle(color: Colors.white, fontSize: 12),
                  children: [
                    TextSpan(
                      text: '${amount.toStringAsFixed(0)}원',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}

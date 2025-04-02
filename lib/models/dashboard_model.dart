// lib/models/dashboard_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

// 대시보드 요약 데이터 모델
class DashboardSummary {
  final int totalOrders;
  final double totalSales;
  final int newUsers;
  final int productsSold;
  final Map<String, dynamic> salesByCategory;
  final Map<String, dynamic> topProducts;
  final Map<String, dynamic> orderStatusCounts;

  DashboardSummary({
    required this.totalOrders,
    required this.totalSales,
    required this.newUsers,
    required this.productsSold,
    required this.salesByCategory,
    required this.topProducts,
    required this.orderStatusCounts,
  });
}

// 매출 통계 모델
class SalesStatistics {
  final String period; // daily, weekly, monthly
  final DateTime startDate;
  final DateTime endDate;
  final List<Map<String, dynamic>> data; // 날짜별 매출 데이터
  final double totalSales;
  final double averageSales;

  SalesStatistics({
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.data,
    required this.totalSales,
    required this.averageSales,
  });
}

// 상품 통계 모델
class ProductStatistics {
  final String period;
  final DateTime startDate;
  final DateTime endDate;
  final List<Map<String, dynamic>> topSellingProducts;
  final Map<String, dynamic> salesByCategory;
  final Map<String, dynamic> inventoryStatus;

  ProductStatistics({
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.topSellingProducts,
    required this.salesByCategory,
    required this.inventoryStatus,
  });
}

// 고객 통계 모델
class CustomerStatistics {
  final String period;
  final DateTime startDate;
  final DateTime endDate;
  final int newUsers;
  final int activeUsers;
  final double averageOrderValue;
  final Map<String, dynamic> userDemographics;

  CustomerStatistics({
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.newUsers,
    required this.activeUsers,
    required this.averageOrderValue,
    required this.userDemographics,
  });
}

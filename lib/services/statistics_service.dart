// lib/services/statistics_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StatisticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 특정 기간의 매출 데이터 조회
  Future<Map<String, dynamic>> getSalesData({
    required DateTime startDate,
    required DateTime endDate,
    String groupBy = 'day',
  }) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('orders')
          .where('orderDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('orderDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      // 날짜별 매출 집계
      Map<String, double> dailySales = {};
      double totalSales = 0;
      int totalOrders = snapshot.docs.length;

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        DateTime orderDate = (data['orderDate'] as Timestamp).toDate();

        String dateKey;
        switch (groupBy) {
          case 'day':
            dateKey =
                '${orderDate.year}-${orderDate.month.toString().padLeft(2, '0')}-${orderDate.day.toString().padLeft(2, '0')}';
            break;
          case 'week':
            // 주 단위 키 생성 (년-주차)
            int weekNumber = (orderDate.day / 7).ceil();
            dateKey =
                '${orderDate.year}-${orderDate.month.toString().padLeft(2, '0')}-W$weekNumber';
            break;
          case 'month':
            dateKey =
                '${orderDate.year}-${orderDate.month.toString().padLeft(2, '0')}';
            break;
          default:
            dateKey =
                '${orderDate.year}-${orderDate.month.toString().padLeft(2, '0')}-${orderDate.day.toString().padLeft(2, '0')}';
        }

        double amount = (data['total'] ?? 0).toDouble();
        dailySales[dateKey] = (dailySales[dateKey] ?? 0) + amount;
        totalSales += amount;
      }

      // 일별 매출 데이터 리스트로 변환
      List<Map<String, dynamic>> salesData = dailySales.entries
          .map((entry) => {
                'date': entry.key,
                'amount': entry.value,
              })
          .toList();

      // 정렬
      salesData.sort((a, b) => a['date'].compareTo(b['date']));

      return {
        'salesData': salesData,
        'totalSales': totalSales,
        'totalOrders': totalOrders,
        'averageSales': totalOrders > 0 ? totalSales / totalOrders : 0,
      };
    } catch (e) {
      print('매출 데이터 조회 오류: $e');
      Get.snackbar(
        '오류',
        '매출 데이터를 조회하는 중 문제가 발생했습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
      );
      return {
        'salesData': [],
        'totalSales': 0,
        'totalOrders': 0,
        'averageSales': 0,
      };
    }
  }

  // 상품 판매 데이터 조회
  Future<List<Map<String, dynamic>>> getProductSalesData({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 10,
  }) async {
    try {
      // 기간 내 주문 데이터 가져오기
      QuerySnapshot orderSnapshot = await _firestore
          .collection('orders')
          .where('orderDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('orderDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      // 상품별 판매량 집계
      Map<String, Map<String, dynamic>> productSales = {};

      for (var doc in orderSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        List<dynamic> items = data['items'] ?? [];

        for (var item in items) {
          String productId = item['productId'] ?? '';
          if (productId.isEmpty) continue;

          String productName = item['productName'] ?? 'Unknown Product';
          int quantity = item['quantity'] ?? 0;
          double price = (item['price'] ?? 0).toDouble();
          double totalAmount = price * quantity;
          String category = item['category'] ?? 'uncategorized';

          // 상품별 판매 정보 업데이트
          if (!productSales.containsKey(productId)) {
            productSales[productId] = {
              'id': productId,
              'name': productName,
              'category': category,
              'quantity': 0,
              'totalAmount': 0.0,
            };
          }

          productSales[productId]!['quantity'] =
              (productSales[productId]!['quantity'] as int) + quantity;
          productSales[productId]!['totalAmount'] =
              (productSales[productId]!['totalAmount'] as double) + totalAmount;
        }
      }

      // 상위 판매 상품 선별
      var sortedProducts = productSales.values.toList()
        ..sort((a, b) =>
            (b['totalAmount'] as double).compareTo(a['totalAmount'] as double));

      return sortedProducts.take(limit).toList();
    } catch (e) {
      print('상품 판매 데이터 조회 오류: $e');
      Get.snackbar(
        '오류',
        '상품 판매 데이터를 조회하는 중 문제가 발생했습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
      );
      return [];
    }
  }

  // 카테고리별 매출 데이터 조회
  Future<Map<String, double>> getCategorySalesData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // 기간 내 주문 데이터 가져오기
      QuerySnapshot orderSnapshot = await _firestore
          .collection('orders')
          .where('orderDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('orderDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      // 카테고리별 매출 집계
      Map<String, double> categorySales = {};

      for (var doc in orderSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        List<dynamic> items = data['items'] ?? [];

        for (var item in items) {
          String category = item['category'] ?? 'uncategorized';
          int quantity = item['quantity'] ?? 0;
          double price = (item['price'] ?? 0).toDouble();
          double totalAmount = price * quantity;

          categorySales[category] =
              (categorySales[category] ?? 0) + totalAmount;
        }
      }

      return categorySales;
    } catch (e) {
      print('카테고리별 매출 데이터 조회 오류: $e');
      Get.snackbar(
        '오류',
        '카테고리별 매출 데이터를 조회하는 중 문제가 발생했습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
      );
      return {};
    }
  }

  // 사용자 통계 데이터 조회
  Future<Map<String, dynamic>> getUserStatistics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // 신규 사용자
      QuerySnapshot newUserSnapshot = await _firestore
          .collection('users')
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      int newUsers = newUserSnapshot.docs.length;

      // 활성 사용자 (기간 내 주문한 사용자)
      QuerySnapshot orderSnapshot = await _firestore
          .collection('orders')
          .where('orderDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('orderDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      Set<String> activeUserIds = {};
      double totalOrderAmount = 0;

      for (var doc in orderSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String userId = data['userId'] ?? '';

        if (userId.isNotEmpty) {
          activeUserIds.add(userId);
          totalOrderAmount += (data['total'] ?? 0).toDouble();
        }
      }

      int activeUsers = activeUserIds.length;
      double averageOrderValue =
          activeUsers > 0 ? totalOrderAmount / orderSnapshot.docs.length : 0;

      return {
        'newUsers': newUsers,
        'activeUsers': activeUsers,
        'totalOrderAmount': totalOrderAmount,
        'averageOrderValue': averageOrderValue,
      };
    } catch (e) {
      print('사용자 통계 데이터 조회 오류: $e');
      Get.snackbar(
        '오류',
        '사용자 통계 데이터를 조회하는 중 문제가 발생했습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
      );
      return {
        'newUsers': 0,
        'activeUsers': 0,
        'totalOrderAmount': 0.0,
        'averageOrderValue': 0.0,
      };
    }
  }
}

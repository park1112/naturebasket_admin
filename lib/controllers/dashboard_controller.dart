// lib/controllers/dashboard_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:csv/csv.dart';
import '../models/dashboard_model.dart';

class DashboardController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Rx<DashboardSummary?> summary = Rx<DashboardSummary?>(null);
  Rx<SalesStatistics?> salesStats = Rx<SalesStatistics?>(null);
  Rx<ProductStatistics?> productStats = Rx<ProductStatistics?>(null);
  Rx<CustomerStatistics?> customerStats = Rx<CustomerStatistics?>(null);

  RxBool isLoading = false.obs;
  RxString selectedPeriod = 'weekly'.obs; // daily, weekly, monthly

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
  }

  // 대시보드 데이터 로드
  Future<void> loadDashboardData() async {
    isLoading.value = true;

    try {
      // 요약 데이터 로드
      await _loadSummaryData();

      // 선택된 기간에 따른 통계 로드
      await _loadStatistics(selectedPeriod.value);
    } catch (e) {
      print('대시보드 데이터 로드 오류: $e');
      Get.snackbar(
        '오류',
        '데이터를 불러오는 중 문제가 발생했습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // 기간 변경 시 통계 다시 로드
  void changePeriod(String period) {
    selectedPeriod.value = period;
    _loadStatistics(period);
  }

  // 요약 데이터 로드
  Future<void> _loadSummaryData() async {
    try {
      // 주문 총계
      QuerySnapshot orderSnapshot = await _firestore.collection('orders').get();

      int totalOrders = orderSnapshot.docs.length;

      // 총 매출
      double totalSales = 0;
      for (var doc in orderSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        totalSales += (data['total'] ?? 0).toDouble();
      }

      // 신규 사용자 (지난 7일)
      DateTime lastWeek = DateTime.now().subtract(Duration(days: 7));
      QuerySnapshot newUserSnapshot = await _firestore
          .collection('users')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(lastWeek))
          .get();

      int newUsers = newUserSnapshot.docs.length;

      // 판매된 상품 수량
      int productsSold = 0;
      Map<String, double> salesByCategory = {};
      Map<String, int> orderStatusCounts = {};
      Map<String, int> topProducts = {};

      for (var doc in orderSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // 주문 상태 카운트
        String status = data['status'] ?? 'pending';
        orderStatusCounts[status] = (orderStatusCounts[status] ?? 0) + 1;

        // 주문 상품 세부 정보
        List<dynamic> items = data['items'] ?? [];
        for (var item in items) {
          productsSold += int.parse((item['quantity'] ?? 0).toString());

          // 카테고리별 매출
          String category = item['category'] ?? 'uncategorized';
          double itemTotal =
              ((item['price'] ?? 0) * (item['quantity'] ?? 0)).toDouble();
          salesByCategory[category] =
              (salesByCategory[category] ?? 0) + itemTotal;

          // 인기 상품
          String productId = item['productId'] ?? '';
          if (productId.isNotEmpty) {
            topProducts[productId] = (topProducts[productId] ?? 0) +
                int.parse((item['quantity'] ?? 0).toString());
          }
        }
      }

      // 상위 5개 상품만 선택
      var sortedProducts = topProducts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      Map<String, int> top5Products = {};
      for (var i = 0; i < sortedProducts.length && i < 5; i++) {
        top5Products[sortedProducts[i].key] = sortedProducts[i].value;
      }

      // 요약 데이터 생성
      summary.value = DashboardSummary(
        totalOrders: totalOrders,
        totalSales: totalSales,
        newUsers: newUsers,
        productsSold: productsSold,
        salesByCategory: salesByCategory,
        topProducts: top5Products,
        orderStatusCounts: orderStatusCounts,
      );
    } catch (e) {
      print('요약 데이터 로드 오류: $e');
      throw e;
    }
  }

  // 기간별 통계 로드
  Future<void> _loadStatistics(String period) async {
    try {
      DateTime now = DateTime.now();
      DateTime startDate;
      String groupBy;

      // 기간 설정
      switch (period) {
        case 'daily':
          startDate = DateTime(now.year, now.month, now.day - 30);
          groupBy = 'day';
          break;
        case 'weekly':
          startDate = DateTime(now.year, now.month, now.day - 90);
          groupBy = 'week';
          break;
        case 'monthly':
          startDate = DateTime(now.year - 1, now.month, 1);
          groupBy = 'month';
          break;
        default:
          startDate = DateTime(now.year, now.month, now.day - 30);
          groupBy = 'day';
      }

      // 매출 통계 로드
      await _loadSalesStatistics(startDate, now, groupBy);

      // 상품 통계 로드
      await _loadProductStatistics(startDate, now);

      // 고객 통계 로드
      await _loadCustomerStatistics(startDate, now);
    } catch (e) {
      print('통계 데이터 로드 오류: $e');
      throw e;
    }
  }

  // 매출 통계 로드
  Future<void> _loadSalesStatistics(
      DateTime startDate, DateTime endDate, String groupBy) async {
    try {
      // 기간 내 주문 데이터 가져오기
      QuerySnapshot orderSnapshot = await _firestore
          .collection('orders')
          .where('orderDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('orderDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('orderDate')
          .get();

      // 날짜별 매출 집계
      Map<String, double> dailySales = {};
      for (var doc in orderSnapshot.docs) {
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

      // 총 매출 및 평균 매출 계산
      double totalSales =
          dailySales.values.fold(0, (sum, amount) => sum + amount);
      double averageSales =
          dailySales.isEmpty ? 0 : totalSales / dailySales.length;

      // 매출 통계 모델 생성
      salesStats.value = SalesStatistics(
        period: groupBy,
        startDate: startDate,
        endDate: endDate,
        data: salesData,
        totalSales: totalSales,
        averageSales: averageSales,
      );
    } catch (e) {
      print('매출 통계 로드 오류: $e');
      throw e;
    }
  }

  // 상품 통계 로드
  Future<void> _loadProductStatistics(
      DateTime startDate, DateTime endDate) async {
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
      Map<String, double> categoryTotals = {};

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

          // 카테고리별 매출 업데이트
          categoryTotals[category] =
              (categoryTotals[category] ?? 0) + totalAmount;
        }
      }

      // 상위 판매 상품 선별
      var sortedProducts = productSales.values.toList()
        ..sort((a, b) =>
            (b['totalAmount'] as double).compareTo(a['totalAmount'] as double));

      List<Map<String, dynamic>> topProducts = sortedProducts.take(10).toList();

      // 재고 상태 가져오기
      QuerySnapshot productSnapshot =
          await _firestore.collection('products').get();

      Map<String, dynamic> inventoryStatus = {
        'inStock': 0,
        'lowStock': 0,
        'outOfStock': 0,
      };

      for (var doc in productSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        int stockQuantity = data['stockQuantity'] ?? 0;

        if (stockQuantity <= 0) {
          inventoryStatus['outOfStock'] =
              (inventoryStatus['outOfStock'] as int) + 1;
        } else if (stockQuantity < 10) {
          inventoryStatus['lowStock'] =
              (inventoryStatus['lowStock'] as int) + 1;
        } else {
          inventoryStatus['inStock'] = (inventoryStatus['inStock'] as int) + 1;
        }
      }

      // 상품 통계 모델 생성
      productStats.value = ProductStatistics(
        period: selectedPeriod.value,
        startDate: startDate,
        endDate: endDate,
        topSellingProducts: topProducts,
        salesByCategory: categoryTotals,
        inventoryStatus: inventoryStatus,
      );
    } catch (e) {
      print('상품 통계 로드 오류: $e');
      throw e;
    }
  }

  // 고객 통계 로드
  Future<void> _loadCustomerStatistics(
      DateTime startDate, DateTime endDate) async {
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

      // 사용자 인구통계 정보 (예시)
      Map<String, dynamic> userDemographics = {
        'gender': {'male': 45, 'female': 55},
        'ageGroup': {
          '18-24': 20,
          '25-34': 35,
          '35-44': 25,
          '45-54': 15,
          '55+': 5
        },
        'region': {'서울': 40, '경기': 30, '부산': 10, '기타': 20},
      };

      // 고객 통계 모델 생성
      customerStats.value = CustomerStatistics(
        period: selectedPeriod.value,
        startDate: startDate,
        endDate: endDate,
        newUsers: newUsers,
        activeUsers: activeUsers,
        averageOrderValue: averageOrderValue,
        userDemographics: userDemographics,
      );
    } catch (e) {
      print('고객 통계 로드 오류: $e');
      throw e;
    }
  }

  // 데이터 내보내기 (CSV)
  Future<String?> exportSalesDataToCsv() async {
    try {
      if (salesStats.value == null || salesStats.value!.data.isEmpty) {
        throw Exception('내보낼 데이터가 없습니다.');
      }

      // 헤더 및 데이터 행 생성
      List<List<dynamic>> csvData = [];
      csvData.add(['날짜', '매출액']); // 헤더

      // 데이터 행 추가
      for (var item in salesStats.value!.data) {
        csvData.add([item['date'], item['amount']]);
      }

      // CSV 형식으로 변환
      String csv = const ListToCsvConverter().convert(csvData);

      return csv;
    } catch (e) {
      print('CSV 내보내기 오류: $e');

      Get.snackbar(
        '내보내기 실패',
        '데이터를 CSV로 내보내는 중 오류가 발생했습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
      );

      return null;
    }
  }

  // 상품 판매 데이터 내보내기 (CSV)
  Future<String?> exportProductSalesDataToCsv() async {
    try {
      if (productStats.value == null ||
          productStats.value!.topSellingProducts.isEmpty) {
        throw Exception('내보낼 데이터가 없습니다.');
      }

      // 헤더 및 데이터 행 생성
      List<List<dynamic>> csvData = [];
      csvData.add(['상품 ID', '상품명', '카테고리', '판매수량', '매출액']); // 헤더

      // 데이터 행 추가
      for (var product in productStats.value!.topSellingProducts) {
        csvData.add([
          product['id'],
          product['name'],
          product['category'],
          product['quantity'],
          product['totalAmount'],
        ]);
      }

      // CSV 형식으로 변환
      String csv = const ListToCsvConverter().convert(csvData);

      return csv;
    } catch (e) {
      print('CSV 내보내기 오류: $e');

      Get.snackbar(
        '내보내기 실패',
        '데이터를 CSV로 내보내는 중 오류가 발생했습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
      );

      return null;
    }
  }
}

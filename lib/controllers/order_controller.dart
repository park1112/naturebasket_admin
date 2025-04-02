// lib/controllers/order_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';
import 'admin_auth_controller.dart';

class OrderController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AdminAuthController _authController = Get.find<AdminAuthController>();

  RxList<OrderModel> orders = <OrderModel>[].obs;
  RxBool isLoading = false.obs;

  // 필터링
  RxString searchQuery = ''.obs;
  RxString statusFilter = 'all'.obs;
  Rx<DateTime?> startDate = Rx<DateTime?>(null);
  Rx<DateTime?> endDate = Rx<DateTime?>(null);
  RxString sortBy = 'orderDate'.obs;
  RxBool sortAscending = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadOrders();
  }

  // 주문 목록 로드
  Future<void> loadOrders() async {
    try {
      isLoading.value = true;

      // Firestore에서 주문 데이터 가져오기
      Query query = _firestore.collection('orders');

      // 필터 적용
      if (searchQuery.isNotEmpty) {
        // 주문 ID, 사용자 이름, 이메일 등으로 검색
        query = query.where('orderNumber', isEqualTo: searchQuery.value);
        // 주의: 실제로는 여러 필드로 OR 검색이 필요할 수 있음
      }

      if (statusFilter.value != 'all') {
        query = query.where('status', isEqualTo: statusFilter.value);
      }

      if (startDate.value != null) {
        query = query.where('orderDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate.value!));
      }

      if (endDate.value != null) {
        // 종료일의 끝까지 포함하기 위해 다음날 00:00:00으로 설정
        final nextDay = DateTime(
          endDate.value!.year,
          endDate.value!.month,
          endDate.value!.day + 1,
        );
        query =
            query.where('orderDate', isLessThan: Timestamp.fromDate(nextDay));
      }

      // 정렬 적용
      switch (sortBy.value) {
        case 'orderDate':
          query = query.orderBy('orderDate', descending: !sortAscending.value);
          break;
        case 'total':
          query = query.orderBy('total', descending: !sortAscending.value);
          break;
        case 'status':
          query = query.orderBy('status', descending: !sortAscending.value);
          break;
        default:
          query = query.orderBy('orderDate', descending: !sortAscending.value);
      }

      QuerySnapshot snapshot = await query.get();

      // 주문 목록 생성
      List<OrderModel> loadedOrders =
          snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();

      // 주문 목록 업데이트
      orders.value = loadedOrders;
    } catch (e) {
      print('주문 목록 로드 오류: $e');
      Get.snackbar(
        '오류',
        '주문 목록을 불러오는 중 문제가 발생했습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // 주문 상세 정보 로드
  Future<OrderModel?> getOrderDetails(String orderId) async {
    try {
      isLoading.value = true;

      DocumentSnapshot doc =
          await _firestore.collection('orders').doc(orderId).get();

      if (!doc.exists) {
        throw Exception('주문 정보를 찾을 수 없습니다.');
      }

      return OrderModel.fromFirestore(doc);
    } catch (e) {
      print('주문 상세 정보 로드 오류: $e');

      Get.snackbar(
        '오류',
        '주문 정보를 불러오는 중 문제가 발생했습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
      );

      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // 주문 상태 업데이트
  Future<bool> updateOrderStatus(String orderId, OrderStatus newStatus,
      {String? reason, String? trackingNumber, String? trackingCompany}) async {
    try {
      isLoading.value = true;

      // 현재 관리자 정보 확인
      if (_authController.currentAdmin.value == null) {
        throw Exception('인증 정보가 없습니다.');
      }

      // 현재 주문 정보 가져오기
      DocumentSnapshot doc =
          await _firestore.collection('orders').doc(orderId).get();

      if (!doc.exists) {
        throw Exception('주문 정보를 찾을 수 없습니다.');
      }

      OrderModel order = OrderModel.fromFirestore(doc);
      Map<String, dynamic> updateData = {
        'status': newStatus.toString().split('.').last,
      };

      // 상태에 따른 추가 정보 업데이트
      switch (newStatus) {
        case OrderStatus.confirmed:
          updateData['processedDate'] = Timestamp.fromDate(DateTime.now());
          break;
        case OrderStatus.shipping:
          updateData['shippedDate'] = Timestamp.fromDate(DateTime.now());
          if (trackingNumber != null) {
            updateData['trackingNumber'] = trackingNumber;
          }
          if (trackingCompany != null) {
            updateData['trackingCompany'] = trackingCompany;
          }
          break;
        case OrderStatus.delivered:
          updateData['deliveredDate'] = Timestamp.fromDate(DateTime.now());
          break;
        case OrderStatus.cancelled:
        case OrderStatus.refunded:
          updateData['cancelledDate'] = Timestamp.fromDate(DateTime.now());
          if (reason != null) {
            updateData['cancelReason'] = reason;
          }
          break;
        default:
          break;
      }

      // 업데이트 시간 및 수정자 추가
      updateData['updatedAt'] = Timestamp.fromDate(DateTime.now());
      updateData['updatedBy'] = _authController.currentAdmin.value!.name;

      // Firestore 업데이트
      await _firestore.collection('orders').doc(orderId).update(updateData);

      // 활동 로그 기록
      Map<String, dynamic> beforeData = {
        'status': order.status.toString().split('.').last,
      };

      Map<String, dynamic> afterData = {
        'status': newStatus.toString().split('.').last,
      };

      String actionType;
      switch (newStatus) {
        case OrderStatus.confirmed:
          actionType = 'confirm_order';
          break;
        case OrderStatus.processing:
          actionType = 'process_order';
          break;
        case OrderStatus.shipping:
          actionType = 'ship_order';
          break;
        case OrderStatus.delivered:
          actionType = 'deliver_order';
          break;
        case OrderStatus.cancelled:
          actionType = 'cancel_order';
          break;
        case OrderStatus.refunded:
          actionType = 'refund_order';
          break;
        default:
          actionType = 'update_order';
      }

      await _authController.logActivity(
        actionType,
        orderId,
        'order',
        beforeData,
        afterData,
      );

      // 주문 목록 새로고침
      await loadOrders();

      Get.snackbar(
        '주문 상태 업데이트',
        '주문 상태가 성공적으로 업데이트되었습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.1),
      );

      return true;
    } catch (e) {
      print('주문 상태 업데이트 오류: $e');

      String errorMessage = '주문 상태 업데이트 중 오류가 발생했습니다.';
      if (e is Exception) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }

      Get.snackbar(
        '주문 상태 업데이트 실패',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
      );

      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // 송장 정보 업데이트
  Future<bool> updateTrackingInfo(
      String orderId, String trackingNumber, String trackingCompany) async {
    try {
      isLoading.value = true;

      // 현재 관리자 정보 확인
      if (_authController.currentAdmin.value == null) {
        throw Exception('인증 정보가 없습니다.');
      }

      // 현재 주문 정보 가져오기
      DocumentSnapshot doc =
          await _firestore.collection('orders').doc(orderId).get();

      if (!doc.exists) {
        throw Exception('주문 정보를 찾을 수 없습니다.');
      }

      OrderModel order = OrderModel.fromFirestore(doc);

      // 배송 중 상태가 아니면 상태도 업데이트
      bool updateStatus = order.status != OrderStatus.shipping;

      Map<String, dynamic> updateData = {
        'trackingNumber': trackingNumber,
        'trackingCompany': trackingCompany,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'updatedBy': _authController.currentAdmin.value!.name,
      };

      if (updateStatus) {
        updateData['status'] = OrderStatus.shipping.toString().split('.').last;
        updateData['shippedDate'] = Timestamp.fromDate(DateTime.now());
      }

      // Firestore 업데이트
      await _firestore.collection('orders').doc(orderId).update(updateData);

      // 활동 로그 기록
      Map<String, dynamic> beforeData = {
        'trackingNumber': order.trackingNumber,
        'trackingCompany': order.trackingCompany,
      };

      Map<String, dynamic> afterData = {
        'trackingNumber': trackingNumber,
        'trackingCompany': trackingCompany,
      };

      await _authController.logActivity(
        'update_tracking_info',
        orderId,
        'order',
        beforeData,
        afterData,
      );

      // 주문 목록 새로고침
      await loadOrders();

      Get.snackbar(
        '송장 정보 업데이트',
        '송장 정보가 성공적으로 업데이트되었습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.1),
      );

      return true;
    } catch (e) {
      print('송장 정보 업데이트 오류: $e');

      String errorMessage = '송장 정보 업데이트 중 오류가 발생했습니다.';
      if (e is Exception) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }

      Get.snackbar(
        '송장 정보 업데이트 실패',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
      );

      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // 주문 메모 업데이트
  Future<bool> updateOrderNote(String orderId, String note) async {
    try {
      isLoading.value = true;

      // 현재 관리자 정보 확인
      if (_authController.currentAdmin.value == null) {
        throw Exception('인증 정보가 없습니다.');
      }

      // 현재 주문 정보 가져오기
      DocumentSnapshot doc =
          await _firestore.collection('orders').doc(orderId).get();

      if (!doc.exists) {
        throw Exception('주문 정보를 찾을 수 없습니다.');
      }

      OrderModel order = OrderModel.fromFirestore(doc);

      // Firestore 업데이트
      await _firestore.collection('orders').doc(orderId).update({
        'note': note,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'updatedBy': _authController.currentAdmin.value!.name,
      });

      // 활동 로그 기록
      await _authController.logActivity(
        'update_order_note',
        orderId,
        'order',
        {'note': order.note},
        {'note': note},
      );

      Get.snackbar(
        '메모 업데이트',
        '주문 메모가 성공적으로 업데이트되었습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.1),
      );

      return true;
    } catch (e) {
      print('주문 메모 업데이트 오류: $e');

      String errorMessage = '주문 메모 업데이트 중 오류가 발생했습니다.';
      if (e is Exception) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }

      Get.snackbar(
        '메모 업데이트 실패',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
      );

      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // 일괄 송장 입력 처리
  Future<Map<String, dynamic>> bulkUpdateTrackingInfo(
      Map<String, Map<String, String>> trackingInfos) async {
    try {
      isLoading.value = true;

      // 현재 관리자 정보 확인
      if (_authController.currentAdmin.value == null) {
        throw Exception('인증 정보가 없습니다.');
      }

      int successCount = 0;
      int errorCount = 0;
      List<String> errorOrders = [];

      // 일괄 업데이트
      WriteBatch batch = _firestore.batch();

      for (String orderId in trackingInfos.keys) {
        try {
          DocumentReference orderRef =
              _firestore.collection('orders').doc(orderId);
          DocumentSnapshot orderDoc = await orderRef.get();

          if (orderDoc.exists) {
            Map<String, String> info = trackingInfos[orderId]!;
            String trackingNumber = info['trackingNumber'] ?? '';
            String trackingCompany = info['trackingCompany'] ?? '';

            if (trackingNumber.isNotEmpty && trackingCompany.isNotEmpty) {
              OrderModel order = OrderModel.fromFirestore(orderDoc);

              // 배송 중 상태가 아니면 상태도 업데이트
              bool updateStatus = order.status != OrderStatus.shipping;

              Map<String, dynamic> updateData = {
                'trackingNumber': trackingNumber,
                'trackingCompany': trackingCompany,
                'updatedAt': Timestamp.fromDate(DateTime.now()),
                'updatedBy': _authController.currentAdmin.value!.name,
              };

              if (updateStatus) {
                updateData['status'] =
                    OrderStatus.shipping.toString().split('.').last;
                updateData['shippedDate'] = Timestamp.fromDate(DateTime.now());
              }

              batch.update(orderRef, updateData);

              // 활동 로그 기록
              await _authController.logActivity(
                'bulk_update_tracking_info',
                orderId,
                'order',
                {
                  'trackingNumber': order.trackingNumber,
                  'trackingCompany': order.trackingCompany,
                },
                {
                  'trackingNumber': trackingNumber,
                  'trackingCompany': trackingCompany,
                },
              );

              successCount++;
            } else {
              errorCount++;
              errorOrders.add(orderId);
            }
          } else {
            errorCount++;
            errorOrders.add(orderId);
          }
        } catch (e) {
          print('개별 주문 처리 오류: $e');
          errorCount++;
          errorOrders.add(orderId);
        }
      }

      // 배치 커밋
      await batch.commit();

      // 주문 목록 새로고침
      await loadOrders();

      return {
        'success': successCount,
        'error': errorCount,
        'errorOrders': errorOrders,
      };
    } catch (e) {
      print('일괄 송장 입력 오류: $e');

      Get.snackbar(
        '일괄 송장 입력 실패',
        '일괄 송장 입력 중 오류가 발생했습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
      );

      return {
        'success': 0,
        'error': 0,
        'errorOrders': [],
      };
    } finally {
      isLoading.value = false;
    }
  }

  // 검색어 변경
  void setSearchQuery(String query) {
    searchQuery.value = query;
    loadOrders();
  }

  // 상태 필터 변경
  void setStatusFilter(String status) {
    statusFilter.value = status;
    loadOrders();
  }

  // 날짜 필터 변경
  void setDateFilter(DateTime? start, DateTime? end) {
    startDate.value = start;
    endDate.value = end;
    loadOrders();
  }

  // 정렬 변경
  void setSortBy(String field) {
    if (sortBy.value == field) {
      // 같은 필드로 정렬 중이면 오름차순/내림차순 전환
      sortAscending.value = !sortAscending.value;
    } else {
      // 다른 필드로 정렬 시 기본 내림차순
      sortBy.value = field;
      sortAscending.value = false;
    }
    loadOrders();
  }

  // 주문 통계 조회
  Future<Map<String, dynamic>> getOrderStatistics(
      {DateTime? start, DateTime? end}) async {
    try {
      isLoading.value = true;

      DateTime startDate =
          start ?? DateTime.now().subtract(const Duration(days: 30));
      DateTime endDate = end ?? DateTime.now();

      // 종료일의 끝까지 포함하기 위해 다음날 00:00:00으로 설정
      final nextDay = DateTime(
        endDate.year,
        endDate.month,
        endDate.day + 1,
      );

      Map<String, dynamic> statistics = {
        'totalOrders': 0,
        'totalSales': 0.0,
        'averageOrderValue': 0.0,
        'statusCounts': <String, int>{},
        'dailySales': <String, double>{},
      };

      // 기간 내 주문 데이터 조회
      QuerySnapshot snapshot = await _firestore
          .collection('orders')
          .where('orderDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('orderDate', isLessThan: Timestamp.fromDate(nextDay))
          .get();

      if (snapshot.docs.isEmpty) {
        return statistics;
      }

      // 통계 계산
      double totalSales = 0.0;
      Map<String, int> statusCounts = {};
      Map<String, double> dailySales = {};

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // 총 매출
        double orderTotal = (data['total'] ?? 0.0).toDouble();
        totalSales += orderTotal;

        // 상태별 주문 수
        String status = data['status'] ?? 'pending';
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;

        // 일별 매출
        DateTime orderDate = (data['orderDate'] as Timestamp).toDate();
        String dateKey = DateFormat('yyyy-MM-dd').format(orderDate);
        dailySales[dateKey] = (dailySales[dateKey] ?? 0.0) + orderTotal;
      }

      // 통계 결과
      statistics['totalOrders'] = snapshot.docs.length;
      statistics['totalSales'] = totalSales;
      statistics['averageOrderValue'] =
          snapshot.docs.isEmpty ? 0.0 : totalSales / snapshot.docs.length;
      statistics['statusCounts'] = statusCounts;
      statistics['dailySales'] = dailySales;

      return statistics;
    } catch (e) {
      print('주문 통계 조회 오류: $e');

      Get.snackbar(
        '오류',
        '주문 통계를 조회하는 중 문제가 발생했습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
      );

      return {
        'totalOrders': 0,
        'totalSales': 0.0,
        'averageOrderValue': 0.0,
        'statusCounts': <String, int>{},
        'dailySales': <String, double>{},
      };
    } finally {
      isLoading.value = false;
    }
  }

  // 주문 데이터 CSV 내보내기
  Future<String> exportOrdersCSV(
      {DateTime? start, DateTime? end, String? status}) async {
    try {
      isLoading.value = true;

      // CSV 헤더
      List<String> headers = [
        '주문번호',
        '주문일자',
        '상태',
        '고객명',
        '연락처',
        '상품명',
        '수량',
        '가격',
        '결제방법',
        '배송지',
        '송장번호',
        '배송사',
      ];

      // 쿼리 생성
      Query query = _firestore.collection('orders');

      if (start != null) {
        query = query.where('orderDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start));
      }

      if (end != null) {
        // 종료일의 끝까지 포함하기 위해 다음날 00:00:00으로 설정
        final nextDay = DateTime(
          end.year,
          end.month,
          end.day + 1,
        );
        query =
            query.where('orderDate', isLessThan: Timestamp.fromDate(nextDay));
      }

      if (status != null && status != 'all') {
        query = query.where('status', isEqualTo: status);
      }

      // 기본 정렬 (최신순)
      query = query.orderBy('orderDate', descending: true);

      // 데이터 조회
      QuerySnapshot snapshot = await query.get();

      // CSV 데이터 생성
      List<List<String>> rows = [headers];

      for (var doc in snapshot.docs) {
        OrderModel order = OrderModel.fromFirestore(doc);

        // 각 주문 아이템별로 행 생성
        for (var item in order.items) {
          List<String> row = [
            order.id,
            DateFormat('yyyy-MM-dd HH:mm').format(order.orderDate),
            _getStatusName(order.status),
            order.userName,
            order.userPhone,
            item.productName,
            item.quantity.toString(),
            item.price.toString(),
            _getPaymentMethodName(order.payment.method),
            '${order.shippingAddress.address1} ${order.shippingAddress.address2}',
            order.trackingNumber ?? '',
            order.trackingCompany ?? '',
          ];

          rows.add(row);
        }
      }

      // CSV 형식으로 변환
      String csv = '';
      for (var row in rows) {
        csv += row.map((cell) => '"$cell"').join(',') + '\n';
      }

      return csv;
    } catch (e) {
      print('CSV 내보내기 오류: $e');

      Get.snackbar(
        '내보내기 실패',
        'CSV 내보내기 중 오류가 발생했습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
      );

      return '';
    } finally {
      isLoading.value = false;
    }
  }

  // 상태 이름 가져오기
  String _getStatusName(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return '주문 접수';
      case OrderStatus.confirmed:
        return '주문 확인';
      case OrderStatus.processing:
        return '처리 중';
      case OrderStatus.shipping:
        return '배송 중';
      case OrderStatus.delivered:
        return '배송 완료';
      case OrderStatus.cancelled:
        return '주문 취소';
      case OrderStatus.refunded:
        return '환불 완료';
      default:
        return '알 수 없음';
    }
  }

  // 결제 방법 이름 가져오기
  String _getPaymentMethodName(String method) {
    switch (method) {
      case 'card':
        return '신용카드';
      case 'bank_transfer':
        return '계좌이체';
      case 'virtual_account':
        return '가상계좌';
      case 'mobile':
        return '휴대폰 결제';
      case 'cash':
        return '현금';
      default:
        return method;
    }
  }
}

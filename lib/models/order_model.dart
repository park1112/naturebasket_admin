// lib/models/order_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  pending, // 주문 접수
  confirmed, // 주문 확인
  processing, // 처리 중
  shipping, // 배송 중
  delivered, // 배송 완료
  cancelled, // 주문 취소
  refunded // 환불 완료
}

class OrderModel {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String userPhone;
  final List<OrderItem> items;
  final OrderAddress shippingAddress;
  final OrderPayment payment;
  final double subtotal;
  final double shippingFee;
  final double discount;
  final double total;
  final OrderStatus status;
  final String? cancelReason;
  final DateTime orderDate;
  final DateTime? processedDate;
  final DateTime? shippedDate;
  final DateTime? deliveredDate;
  final DateTime? cancelledDate;
  final String? trackingNumber;
  final String? trackingCompany;
  final String? note;
  final Map<String, dynamic>? metadata;

  OrderModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    required this.items,
    required this.shippingAddress,
    required this.payment,
    required this.subtotal,
    required this.shippingFee,
    required this.discount,
    required this.total,
    required this.status,
    this.cancelReason,
    required this.orderDate,
    this.processedDate,
    this.shippedDate,
    this.deliveredDate,
    this.cancelledDate,
    this.trackingNumber,
    this.trackingCompany,
    this.note,
    this.metadata,
  });

  // Firestore에서 데이터 로드
  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // 주문 상태 문자열을 enum으로 변환
    OrderStatus orderStatus = OrderStatus.pending;
    if (data['status'] != null) {
      orderStatus = OrderStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => OrderStatus.pending,
      );
    }

    // 주문 아이템 파싱
    List<OrderItem> orderItems = [];
    if (data['items'] != null) {
      for (var item in data['items']) {
        orderItems.add(OrderItem.fromMap(item));
      }
    }

    // 배송 주소 파싱
    OrderAddress shippingAddress = OrderAddress.fromMap(
      data['shippingAddress'] ?? {},
    );

    // 결제 정보 파싱
    OrderPayment payment = OrderPayment.fromMap(
      data['payment'] ?? {},
    );

    return OrderModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      userPhone: data['userPhone'] ?? '',
      items: orderItems,
      shippingAddress: shippingAddress,
      payment: payment,
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      shippingFee: (data['shippingFee'] ?? 0).toDouble(),
      discount: (data['discount'] ?? 0).toDouble(),
      total: (data['total'] ?? 0).toDouble(),
      status: orderStatus,
      cancelReason: data['cancelReason'],
      orderDate: (data['orderDate'] as Timestamp).toDate(),
      processedDate: data['processedDate'] != null
          ? (data['processedDate'] as Timestamp).toDate()
          : null,
      shippedDate: data['shippedDate'] != null
          ? (data['shippedDate'] as Timestamp).toDate()
          : null,
      deliveredDate: data['deliveredDate'] != null
          ? (data['deliveredDate'] as Timestamp).toDate()
          : null,
      cancelledDate: data['cancelledDate'] != null
          ? (data['cancelledDate'] as Timestamp).toDate()
          : null,
      trackingNumber: data['trackingNumber'],
      trackingCompany: data['trackingCompany'],
      note: data['note'],
      metadata: data['metadata'],
    );
  }

  // Firestore에 저장하기 위한 Map 변환
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'items': items.map((item) => item.toMap()).toList(),
      'shippingAddress': shippingAddress.toMap(),
      'payment': payment.toMap(),
      'subtotal': subtotal,
      'shippingFee': shippingFee,
      'discount': discount,
      'total': total,
      'status': status.toString().split('.').last,
      'cancelReason': cancelReason,
      'orderDate': Timestamp.fromDate(orderDate),
      'processedDate':
          processedDate != null ? Timestamp.fromDate(processedDate!) : null,
      'shippedDate':
          shippedDate != null ? Timestamp.fromDate(shippedDate!) : null,
      'deliveredDate':
          deliveredDate != null ? Timestamp.fromDate(deliveredDate!) : null,
      'cancelledDate':
          cancelledDate != null ? Timestamp.fromDate(cancelledDate!) : null,
      'trackingNumber': trackingNumber,
      'trackingCompany': trackingCompany,
      'note': note,
      'metadata': metadata,
    };
  }

  // 주문 상태 업데이트를 위한 복사본 생성
  OrderModel copyWith({
    String? userId,
    String? userName,
    String? userEmail,
    String? userPhone,
    List<OrderItem>? items,
    OrderAddress? shippingAddress,
    OrderPayment? payment,
    double? subtotal,
    double? shippingFee,
    double? discount,
    double? total,
    OrderStatus? status,
    String? cancelReason,
    DateTime? orderDate,
    DateTime? processedDate,
    DateTime? shippedDate,
    DateTime? deliveredDate,
    DateTime? cancelledDate,
    String? trackingNumber,
    String? trackingCompany,
    String? note,
    Map<String, dynamic>? metadata,
  }) {
    return OrderModel(
      id: this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userPhone: userPhone ?? this.userPhone,
      items: items ?? this.items,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      payment: payment ?? this.payment,
      subtotal: subtotal ?? this.subtotal,
      shippingFee: shippingFee ?? this.shippingFee,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      status: status ?? this.status,
      cancelReason: cancelReason ?? this.cancelReason,
      orderDate: orderDate ?? this.orderDate,
      processedDate: processedDate ?? this.processedDate,
      shippedDate: shippedDate ?? this.shippedDate,
      deliveredDate: deliveredDate ?? this.deliveredDate,
      cancelledDate: cancelledDate ?? this.cancelledDate,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      trackingCompany: trackingCompany ?? this.trackingCompany,
      note: note ?? this.note,
      metadata: metadata ?? this.metadata,
    );
  }
}

class OrderItem {
  final String productId;
  final String productName;
  final String? productImage;
  final String? category;
  final int quantity;
  final double price;
  final double? originalPrice;
  final Map<String, dynamic>? options;

  OrderItem({
    required this.productId,
    required this.productName,
    this.productImage,
    this.category,
    required this.quantity,
    required this.price,
    this.originalPrice,
    this.options,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productImage: map['productImage'],
      category: map['category'],
      quantity: map['quantity'] ?? 0,
      price: (map['price'] ?? 0).toDouble(),
      originalPrice: map['originalPrice'] != null
          ? (map['originalPrice'] as num).toDouble()
          : null,
      options: map['options'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'category': category,
      'quantity': quantity,
      'price': price,
      'originalPrice': originalPrice,
      'options': options,
    };
  }
}

class OrderAddress {
  final String recipientName;
  final String phoneNumber;
  final String postalCode;
  final String address1;
  final String address2;
  final String? city;
  final String? state;
  final String? country;
  final Map<String, dynamic>? metadata;

  OrderAddress({
    required this.recipientName,
    required this.phoneNumber,
    required this.postalCode,
    required this.address1,
    required this.address2,
    this.city,
    this.state,
    this.country = '대한민국',
    this.metadata,
  });

  factory OrderAddress.fromMap(Map<String, dynamic> map) {
    return OrderAddress(
      recipientName: map['recipientName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      postalCode: map['postalCode'] ?? '',
      address1: map['address1'] ?? '',
      address2: map['address2'] ?? '',
      city: map['city'],
      state: map['state'],
      country: map['country'] ?? '대한민국',
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recipientName': recipientName,
      'phoneNumber': phoneNumber,
      'postalCode': postalCode,
      'address1': address1,
      'address2': address2,
      'city': city,
      'state': state,
      'country': country,
      'metadata': metadata,
    };
  }
}

class OrderPayment {
  final String
      method; // 'card', 'bank_transfer', 'virtual_account', 'mobile', 'cash'
  final String? provider;
  final String? cardNumber;
  final String? cardType;
  final String? cardInstallment;
  final String? transactionId;
  final String? receiptUrl;
  final String? status; // 'pending', 'completed', 'failed', 'refunded'
  final DateTime? paidAt;
  final Map<String, dynamic>? metadata;

  OrderPayment({
    required this.method,
    this.provider,
    this.cardNumber,
    this.cardType,
    this.cardInstallment,
    this.transactionId,
    this.receiptUrl,
    this.status,
    this.paidAt,
    this.metadata,
  });

  factory OrderPayment.fromMap(Map<String, dynamic> map) {
    return OrderPayment(
      method: map['method'] ?? '',
      provider: map['provider'],
      cardNumber: map['cardNumber'],
      cardType: map['cardType'],
      cardInstallment: map['cardInstallment'],
      transactionId: map['transactionId'],
      receiptUrl: map['receiptUrl'],
      status: map['status'],
      paidAt:
          map['paidAt'] != null ? (map['paidAt'] as Timestamp).toDate() : null,
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'method': method,
      'provider': provider,
      'cardNumber': cardNumber,
      'cardType': cardType,
      'cardInstallment': cardInstallment,
      'transactionId': transactionId,
      'receiptUrl': receiptUrl,
      'status': status,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'metadata': metadata,
    };
  }
}

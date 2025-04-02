// lib/models/product_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? salePrice;
  final int stockQuantity;
  final String category;
  final List<String> images;
  final List<String> tags;
  final bool isOrganic;
  final bool isFeatured;
  final bool isActive;
  final Map<String, dynamic>? nutritionInfo;
  final Map<String, dynamic>? specifications;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.salePrice,
    required this.stockQuantity,
    required this.category,
    required this.images,
    required this.tags,
    required this.isOrganic,
    required this.isFeatured,
    required this.isActive,
    this.nutritionInfo,
    this.specifications,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
  });

  // 할인율 계산
  double get discountPercentage {
    if (salePrice == null || salePrice! >= price) return 0;
    return ((price - salePrice!) / price * 100).roundToDouble();
  }

  // 재고 상태 확인
  String get stockStatus {
    if (stockQuantity <= 0) return 'outOfStock';
    if (stockQuantity < 10) return 'lowStock';
    return 'inStock';
  }

  // Firestore에서 데이터 로드
  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return ProductModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      salePrice: data['salePrice'] != null
          ? (data['salePrice'] as num).toDouble()
          : null,
      stockQuantity: data['stockQuantity'] ?? 0,
      category: data['category'] ?? '미분류',
      images: List<String>.from(data['images'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      isOrganic: data['isOrganic'] ?? false,
      isFeatured: data['isFeatured'] ?? false,
      isActive: data['isActive'] ?? true,
      nutritionInfo: data['nutritionInfo'],
      specifications: data['specifications'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
      updatedBy: data['updatedBy'] ?? '',
    );
  }

  // Firestore에 저장하기 위한 Map 변환
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'salePrice': salePrice,
      'stockQuantity': stockQuantity,
      'category': category,
      'images': images,
      'tags': tags,
      'isOrganic': isOrganic,
      'isFeatured': isFeatured,
      'isActive': isActive,
      'nutritionInfo': nutritionInfo,
      'specifications': specifications,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
    };
  }

  // 제품 정보 일부 수정을 위한 복사본 생성
  ProductModel copyWith({
    String? name,
    String? description,
    double? price,
    double? salePrice,
    int? stockQuantity,
    String? category,
    List<String>? images,
    List<String>? tags,
    bool? isOrganic,
    bool? isFeatured,
    bool? isActive,
    Map<String, dynamic>? nutritionInfo,
    Map<String, dynamic>? specifications,
    String? updatedBy,
  }) {
    return ProductModel(
      id: this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      salePrice: salePrice ?? this.salePrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      category: category ?? this.category,
      images: images ?? this.images,
      tags: tags ?? this.tags,
      isOrganic: isOrganic ?? this.isOrganic,
      isFeatured: isFeatured ?? this.isFeatured,
      isActive: isActive ?? this.isActive,
      nutritionInfo: nutritionInfo ?? this.nutritionInfo,
      specifications: specifications ?? this.specifications,
      createdAt: this.createdAt,
      updatedAt: DateTime.now(),
      createdBy: this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}

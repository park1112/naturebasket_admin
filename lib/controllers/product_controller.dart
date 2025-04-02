// lib/controllers/product_controller.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../models/product_model.dart';
import 'admin_auth_controller.dart';

class ProductController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final AdminAuthController _authController = Get.find<AdminAuthController>();

  RxList<ProductModel> products = <ProductModel>[].obs;
  RxList<String> categories = <String>[].obs;
  RxBool isLoading = false.obs;
  RxString searchQuery = ''.obs;
  RxString categoryFilter = 'all'.obs;
  RxBool organicFilter = false.obs;
  RxString stockFilter = 'all'.obs;
  RxString sortBy = 'name'.obs;
  RxBool sortAscending = true.obs;

  // 이미지 업로드 관련
  RxList<File> selectedImages = <File>[].obs;
  RxList<String> currentImages = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadProducts();
    loadCategories();
  }

  // 제품 목록 로드
  Future<void> loadProducts() async {
    try {
      isLoading.value = true;

      // Firestore에서 제품 데이터 가져오기
      Query query = _firestore.collection('products');

      // 필터 적용
      if (searchQuery.isNotEmpty) {
        query = query
            .where('name', isGreaterThanOrEqualTo: searchQuery.value)
            .where('name', isLessThanOrEqualTo: searchQuery.value + '\uf8ff');
      }

      if (categoryFilter.value != 'all') {
        query = query.where('category', isEqualTo: categoryFilter.value);
      }

      if (organicFilter.value) {
        query = query.where('isOrganic', isEqualTo: true);
      }

      if (stockFilter.value != 'all') {
        if (stockFilter.value == 'inStock') {
          query = query.where('stockQuantity', isGreaterThan: 10);
        } else if (stockFilter.value == 'lowStock') {
          query = query
              .where('stockQuantity', isGreaterThan: 0)
              .where('stockQuantity', isLessThanOrEqualTo: 10);
        } else if (stockFilter.value == 'outOfStock') {
          query = query.where('stockQuantity', isLessThanOrEqualTo: 0);
        }
      }

      // 정렬 적용
      switch (sortBy.value) {
        case 'name':
          query = query.orderBy('name', descending: !sortAscending.value);
          break;
        case 'price':
          query = query.orderBy('price', descending: !sortAscending.value);
          break;
        case 'createdAt':
          query = query.orderBy('createdAt', descending: !sortAscending.value);
          break;
        case 'stockQuantity':
          query =
              query.orderBy('stockQuantity', descending: !sortAscending.value);
          break;
        default:
          query = query.orderBy('name', descending: !sortAscending.value);
      }

      QuerySnapshot snapshot = await query.get();

      // 제품 목록 생성
      List<ProductModel> loadedProducts =
          snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();

      // 제품 목록 업데이트
      products.value = loadedProducts;
    } catch (e) {
      print('제품 목록 로드 오류: $e');
      Get.snackbar(
        '오류',
        '제품 목록을 불러오는 중 문제가 발생했습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // 카테고리 목록 로드
  Future<void> loadCategories() async {
    try {
      isLoading.value = true;

      // 카테고리 컬렉션에서 데이터 가져오기
      QuerySnapshot snapshot = await _firestore.collection('categories').get();

      // 카테고리 목록 생성
      List<String> loadedCategories =
          snapshot.docs.map((doc) => doc['name'] as String).toList();

      // 카테고리가 없으면 기본 카테고리 추가
      if (loadedCategories.isEmpty) {
        loadedCategories = ['과일', '채소', '정육/계란', '유제품', '건강식품', '간식', '생활용품'];
      }

      // 카테고리 목록 업데이트
      categories.value = loadedCategories;
    } catch (e) {
      print('카테고리 로드 오류: $e');
      // 오류 발생 시 기본 카테고리 설정
      categories.value = ['과일', '채소', '정육/계란', '유제품', '건강식품', '간식', '생활용품'];
    } finally {
      isLoading.value = false;
    }
  }

  // 검색어 변경
  void setSearchQuery(String query) {
    searchQuery.value = query;
    loadProducts();
  }

  // 카테고리 필터 변경
  void setCategoryFilter(String category) {
    categoryFilter.value = category;
    loadProducts();
  }

  // 유기농 필터 변경
  void setOrganicFilter(bool value) {
    organicFilter.value = value;
    loadProducts();
  }

  // 재고 필터 변경
  void setStockFilter(String value) {
    stockFilter.value = value;
    loadProducts();
  }

  // 정렬 변경
  void setSortBy(String value) {
    if (sortBy.value == value) {
      // 같은 필드로 정렬 중이면 오름차순/내림차순 전환
      sortAscending.value = !sortAscending.value;
    } else {
      // 다른 필드로 정렬 시 기본 오름차순
      sortBy.value = value;
      sortAscending.value = true;
    }
    loadProducts();
  }

  // 이미지 선택
  Future<void> pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (images.isNotEmpty) {
        for (var image in images) {
          selectedImages.add(File(image.path));
        }
      }
    } catch (e) {
      print('이미지 선택 오류: $e');
      Get.snackbar(
        '오류',
        '이미지 선택 중 문제가 발생했습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
      );
    }
  }

  // 카메라로 이미지 촬영
  Future<void> takePicture() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        selectedImages.add(File(image.path));
      }
    } catch (e) {
      print('카메라 오류: $e');
      Get.snackbar(
        '오류',
        '사진 촬영 중 문제가 발생했습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
      );
    }
  }

  // 이미지 삭제 (선택된 이미지)
  void removeSelectedImage(int index) {
    if (index >= 0 && index < selectedImages.length) {
      selectedImages.removeAt(index);
    }
  }

  // 기존 이미지 삭제
  void removeCurrentImage(int index) {
    if (index >= 0 && index < currentImages.length) {
      currentImages.removeAt(index);
    }
  }

  // 모든 이미지 선택 취소
  void clearImages() {
    selectedImages.clear();
    currentImages.clear();
  }

  // 제품 상세 정보 로드
  Future<ProductModel?> getProductDetails(String productId) async {
    try {
      isLoading.value = true;

      DocumentSnapshot doc =
          await _firestore.collection('products').doc(productId).get();

      if (!doc.exists) {
        throw Exception('제품 정보를 찾을 수 없습니다.');
      }

      ProductModel product = ProductModel.fromFirestore(doc);

      // 현재 이미지 설정
      currentImages.value = List<String>.from(product.images);

      return product;
    } catch (e) {
      print('제품 상세 정보 로드 오류: $e');

      Get.snackbar(
        '오류',
        '제품 정보를 불러오는 중 문제가 발생했습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
      );

      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // 이미지 업로드
  Future<List<String>> _uploadImages(String productId) async {
    List<String> imageUrls = [];

    try {
      // 기존 이미지 URL 유지
      imageUrls.addAll(currentImages);

      // 새 이미지 업로드
      for (var image in selectedImages) {
        String fileName =
            '${productId}_${const Uuid().v4()}${path.extension(image.path)}';
        Reference ref = _storage.ref().child('product_images').child(fileName);

        await ref.putFile(image);
        String downloadUrl = await ref.getDownloadURL();

        imageUrls.add(downloadUrl);
      }

      return imageUrls;
    } catch (e) {
      print('이미지 업로드 오류: $e');
      throw '이미지 업로드 중 오류가 발생했습니다.';
    }
  }

  // 제품 생성
  Future<bool> createProduct({
    required String name,
    required String description,
    required double price,
    double? salePrice,
    required int stockQuantity,
    required String category,
    required List<String> tags,
    required bool isOrganic,
    required bool isFeatured,
    required bool isActive,
    Map<String, dynamic>? nutritionInfo,
    Map<String, dynamic>? specifications,
  }) async {
    try {
      isLoading.value = true;

      // 현재 관리자 정보 확인
      if (_authController.currentAdmin.value == null) {
        throw Exception('인증 정보가 없습니다.');
      }

      // 제품 ID 생성
      String productId = const Uuid().v4();

      // 이미지 업로드
      List<String> imageUrls = await _uploadImages(productId);

      // 제품 데이터 생성
      DateTime now = DateTime.now();

      Map<String, dynamic> productData = {
        'name': name,
        'description': description,
        'price': price,
        'salePrice': salePrice,
        'stockQuantity': stockQuantity,
        'category': category,
        'images': imageUrls,
        'tags': tags,
        'isOrganic': isOrganic,
        'isFeatured': isFeatured,
        'isActive': isActive,
        'nutritionInfo': nutritionInfo,
        'specifications': specifications,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'createdBy': _authController.currentAdmin.value!.name,
        'updatedBy': _authController.currentAdmin.value!.name,
      };

      // Firestore에 제품 정보 저장
      await _firestore.collection('products').doc(productId).set(productData);

      // 활동 로그 기록
      await _authController.logActivity(
        'create_product',
        productId,
        'product',
        {},
        productData,
      );

      // 제품 목록 새로고침
      await loadProducts();

      // 이미지 선택 초기화
      selectedImages.clear();
      currentImages.clear();

      Get.snackbar(
        '제품 생성',
        '제품이 성공적으로 등록되었습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.1),
      );

      return true;
    } catch (e) {
      print('제품 생성 오류: $e');

      String errorMessage = '제품 등록 중 오류가 발생했습니다.';
      if (e is Exception) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }

      Get.snackbar(
        '제품 등록 실패',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
      );

      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // 제품 업데이트
  Future<bool> updateProduct({
    required String productId,
    String? name,
    String? description,
    double? price,
    double? salePrice,
    int? stockQuantity,
    String? category,
    List<String>? tags,
    bool? isOrganic,
    bool? isFeatured,
    bool? isActive,
    Map<String, dynamic>? nutritionInfo,
    Map<String, dynamic>? specifications,
  }) async {
    try {
      isLoading.value = true;

      // 현재 관리자 정보 확인
      if (_authController.currentAdmin.value == null) {
        throw Exception('인증 정보가 없습니다.');
      }

      // 현재 데이터 가져오기 (변경 로그용)
      DocumentSnapshot doc =
          await _firestore.collection('products').doc(productId).get();

      if (!doc.exists) {
        throw Exception('제품 정보를 찾을 수 없습니다.');
      }

      Map<String, dynamic> beforeData = doc.data() as Map<String, dynamic>;
      Map<String, dynamic> updateData = {};

      // 이미지 업로드
      if (selectedImages.isNotEmpty || currentImages.isNotEmpty) {
        List<String> imageUrls = await _uploadImages(productId);
        updateData['images'] = imageUrls;
      }

      // 업데이트할 필드 설정
      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (price != null) updateData['price'] = price;
      if (salePrice != null) updateData['salePrice'] = salePrice;
      if (stockQuantity != null) updateData['stockQuantity'] = stockQuantity;
      if (category != null) updateData['category'] = category;
      if (tags != null) updateData['tags'] = tags;
      if (isOrganic != null) updateData['isOrganic'] = isOrganic;
      if (isFeatured != null) updateData['isFeatured'] = isFeatured;
      if (isActive != null) updateData['isActive'] = isActive;
      if (nutritionInfo != null) updateData['nutritionInfo'] = nutritionInfo;
      if (specifications != null) updateData['specifications'] = specifications;

      // 업데이트 시간 및 수정자 정보 추가
      updateData['updatedAt'] = Timestamp.fromDate(DateTime.now());
      updateData['updatedBy'] = _authController.currentAdmin.value!.name;

      // 변경사항이 없으면 종료
      if (updateData.isEmpty) {
        return true;
      }

      // Firestore 업데이트
      await _firestore.collection('products').doc(productId).update(updateData);

      // 활동 로그 기록
      Map<String, dynamic> afterData = {...beforeData, ...updateData};

      await _authController.logActivity(
        'update_product',
        productId,
        'product',
        beforeData,
        afterData,
      );

      // 제품 목록 새로고침
      await loadProducts();

      // 이미지 선택 초기화
      selectedImages.clear();
      currentImages.clear();

      Get.snackbar(
        '제품 업데이트',
        '제품 정보가 성공적으로 업데이트되었습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.1),
      );

      return true;
    } catch (e) {
      print('제품 업데이트 오류: $e');

      String errorMessage = '제품 정보 업데이트 중 오류가 발생했습니다.';
      if (e is Exception) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }

      Get.snackbar(
        '제품 업데이트 실패',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
      );

      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // 제품 삭제
  Future<bool> deleteProduct(String productId) async {
    try {
      isLoading.value = true;

      // 현재 관리자 정보 확인
      if (_authController.currentAdmin.value == null) {
        throw Exception('인증 정보가 없습니다.');
      }

      // 현재 데이터 가져오기 (변경 로그용)
      DocumentSnapshot doc =
          await _firestore.collection('products').doc(productId).get();

      if (!doc.exists) {
        throw Exception('제품 정보를 찾을 수 없습니다.');
      }

      Map<String, dynamic> beforeData = doc.data() as Map<String, dynamic>;

      // 이미지 삭제
      List<String> images = List<String>.from(beforeData['images'] ?? []);
      for (String imageUrl in images) {
        try {
          // Firebase Storage에서 이미지 URL 추출
          String filePath =
              Uri.decodeFull(imageUrl.split('/o/')[1].split('?')[0]);
          await _storage.ref(filePath).delete();
        } catch (e) {
          print('이미지 삭제 오류 (무시): $e');
        }
      }

      // Firestore에서 제품 삭제
      await _firestore.collection('products').doc(productId).delete();

      // 활동 로그 기록
      await _authController.logActivity(
        'delete_product',
        productId,
        'product',
        beforeData,
        {},
      );

      // 제품 목록 새로고침
      await loadProducts();

      Get.snackbar(
        '제품 삭제',
        '제품이 성공적으로 삭제되었습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.1),
      );

      return true;
    } catch (e) {
      print('제품 삭제 오류: $e');

      String errorMessage = '제품 삭제 중 오류가 발생했습니다.';
      if (e is Exception) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }

      Get.snackbar(
        '제품 삭제 실패',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
      );

      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // 재고 업데이트
  Future<bool> updateStock(String productId, int stockQuantity) async {
    try {
      isLoading.value = true;

      // 현재 관리자 정보 확인
      if (_authController.currentAdmin.value == null) {
        throw Exception('인증 정보가 없습니다.');
      }

      // 현재 데이터 가져오기 (변경 로그용)
      DocumentSnapshot doc =
          await _firestore.collection('products').doc(productId).get();

      if (!doc.exists) {
        throw Exception('제품 정보를 찾을 수 없습니다.');
      }

      Map<String, dynamic> beforeData = doc.data() as Map<String, dynamic>;
      Map<String, dynamic> updateData = {
        'stockQuantity': stockQuantity,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'updatedBy': _authController.currentAdmin.value!.name,
      };

      // Firestore 업데이트
      await _firestore.collection('products').doc(productId).update(updateData);

      // 활동 로그 기록
      Map<String, dynamic> afterData = {...beforeData, ...updateData};

      await _authController.logActivity(
        'update_inventory',
        productId,
        'product',
        beforeData,
        afterData,
      );

      // 제품 목록 새로고침
      await loadProducts();

      Get.snackbar(
        '재고 업데이트',
        '재고 수량이 성공적으로 업데이트되었습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.1),
      );

      return true;
    } catch (e) {
      print('재고 업데이트 오류: $e');

      String errorMessage = '재고 업데이트 중 오류가 발생했습니다.';
      if (e is Exception) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }

      Get.snackbar(
        '재고 업데이트 실패',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
      );

      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // 제품 활성/비활성 전환
  Future<bool> toggleProductStatus(String productId, bool isActive) async {
    try {
      isLoading.value = true;

      // 현재 관리자 정보 확인
      if (_authController.currentAdmin.value == null) {
        throw Exception('인증 정보가 없습니다.');
      }

      // 현재 데이터 가져오기 (변경 로그용)
      DocumentSnapshot doc =
          await _firestore.collection('products').doc(productId).get();

      if (!doc.exists) {
        throw Exception('제품 정보를 찾을 수 없습니다.');
      }

      Map<String, dynamic> beforeData = doc.data() as Map<String, dynamic>;
      Map<String, dynamic> updateData = {
        'isActive': isActive,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'updatedBy': _authController.currentAdmin.value!.name,
      };

      // Firestore 업데이트
      await _firestore.collection('products').doc(productId).update(updateData);

      // 활동 로그 기록
      Map<String, dynamic> afterData = {...beforeData, ...updateData};

      await _authController.logActivity(
        isActive ? 'activate_product' : 'deactivate_product',
        productId,
        'product',
        beforeData,
        afterData,
      );

      // 제품 목록 새로고침
      await loadProducts();

      Get.snackbar(
        '제품 상태 변경',
        '제품이 성공적으로 ${isActive ? '활성화' : '비활성화'}되었습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.1),
      );

      return true;
    } catch (e) {
      print('제품 상태 변경 오류: $e');

      String errorMessage = '제품 상태 변경 중 오류가 발생했습니다.';
      if (e is Exception) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }

      Get.snackbar(
        '제품 상태 변경 실패',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
      );

      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // 카테고리 추가
  Future<bool> addCategory(String category) async {
    try {
      isLoading.value = true;

      // 현재 관리자 정보 확인
      if (_authController.currentAdmin.value == null) {
        throw Exception('인증 정보가 없습니다.');
      }

      // 이미 존재하는지 확인
      if (categories.contains(category)) {
        throw Exception('이미 존재하는 카테고리입니다.');
      }

      // 카테고리 추가
      await _firestore.collection('categories').add({
        'name': category,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'createdBy': _authController.currentAdmin.value!.name,
      });

      // 카테고리 목록 새로고침
      await loadCategories();

      Get.snackbar(
        '카테고리 추가',
        '카테고리가 성공적으로 추가되었습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.1),
      );

      return true;
    } catch (e) {
      print('카테고리 추가 오류: $e');

      String errorMessage = '카테고리 추가 중 오류가 발생했습니다.';
      if (e is Exception) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }

      Get.snackbar(
        '카테고리 추가 실패',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
      );

      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // 일괄 재고 업데이트 (CSV 파일 또는 수동 입력)
  Future<bool> bulkUpdateStock(Map<String, int> stockUpdates) async {
    try {
      isLoading.value = true;

      // 현재 관리자 정보 확인
      if (_authController.currentAdmin.value == null) {
        throw Exception('인증 정보가 없습니다.');
      }

      // 재고 업데이트
      WriteBatch batch = _firestore.batch();
      int successCount = 0;
      int errorCount = 0;

      for (String productId in stockUpdates.keys) {
        int newStock = stockUpdates[productId]!;

        try {
          DocumentReference docRef =
              _firestore.collection('products').doc(productId);
          DocumentSnapshot doc = await docRef.get();

          if (doc.exists) {
            batch.update(docRef, {
              'stockQuantity': newStock,
              'updatedAt': Timestamp.fromDate(DateTime.now()),
              'updatedBy': _authController.currentAdmin.value!.name,
            });

            // 활동 로그 기록
            Map<String, dynamic> beforeData =
                doc.data() as Map<String, dynamic>;
            Map<String, dynamic> afterData = {
              ...beforeData,
              'stockQuantity': newStock,
              'updatedAt': Timestamp.fromDate(DateTime.now()),
              'updatedBy': _authController.currentAdmin.value!.name,
            };

            await _authController.logActivity(
              'bulk_update_inventory',
              productId,
              'product',
              {'stockQuantity': beforeData['stockQuantity']},
              {'stockQuantity': newStock},
            );

            successCount++;
          } else {
            errorCount++;
          }
        } catch (e) {
          print('개별 제품 재고 업데이트 오류: $e');
          errorCount++;
        }
      }

      // 배치 커밋
      await batch.commit();

      // 제품 목록 새로고침
      await loadProducts();

      String resultMessage = '재고 업데이트 완료: $successCount건 성공';
      if (errorCount > 0) {
        resultMessage += ', $errorCount건 실패';
      }

      Get.snackbar(
        '일괄 재고 업데이트',
        resultMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.1),
      );

      return errorCount == 0;
    } catch (e) {
      print('일괄 재고 업데이트 오류: $e');

      String errorMessage = '일괄 재고 업데이트 중 오류가 발생했습니다.';
      if (e is Exception) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }

      Get.snackbar(
        '일괄 재고 업데이트 실패',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
      );

      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // 재고 부족 제품 조회
  Future<List<ProductModel>> getLowStockProducts() async {
    try {
      isLoading.value = true;

      QuerySnapshot snapshot = await _firestore
          .collection('products')
          .where('stockQuantity', isLessThanOrEqualTo: 10)
          .where('isActive', isEqualTo: true)
          .orderBy('stockQuantity')
          .get();

      List<ProductModel> lowStockProducts =
          snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();

      return lowStockProducts;
    } catch (e) {
      print('재고 부족 제품 조회 오류: $e');

      Get.snackbar(
        '오류',
        '재고 부족 제품을 조회하는 중 문제가 발생했습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
      );

      return [];
    } finally {
      isLoading.value = false;
    }
  }

  // 제품 통계 조회
  Future<Map<String, dynamic>> getProductStatistics() async {
    try {
      isLoading.value = true;

      Map<String, dynamic> statistics = {
        'totalProducts': 0,
        'activeProducts': 0,
        'organicProducts': 0,
        'featuredProducts': 0,
        'outOfStockProducts': 0,
        'lowStockProducts': 0,
        'categoryCounts': <String, int>{},
      };

      QuerySnapshot snapshot = await _firestore.collection('products').get();

      statistics['totalProducts'] = snapshot.docs.length;

      // 통계 계산
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // 활성 제품 수
        if (data['isActive'] == true) {
          statistics['activeProducts'] =
              (statistics['activeProducts'] as int) + 1;
        }

        // 유기농 제품 수
        if (data['isOrganic'] == true) {
          statistics['organicProducts'] =
              (statistics['organicProducts'] as int) + 1;
        }

        // 특별 상품 수
        if (data['isFeatured'] == true) {
          statistics['featuredProducts'] =
              (statistics['featuredProducts'] as int) + 1;
        }

        // 재고 없는 제품 수
        if ((data['stockQuantity'] ?? 0) <= 0) {
          statistics['outOfStockProducts'] =
              (statistics['outOfStockProducts'] as int) + 1;
        }

        // 재고 부족 제품 수
        if ((data['stockQuantity'] ?? 0) > 0 &&
            (data['stockQuantity'] ?? 0) <= 10) {
          statistics['lowStockProducts'] =
              (statistics['lowStockProducts'] as int) + 1;
        }

        // 카테고리별 제품 수
        String category = data['category'] ?? '미분류';
        statistics['categoryCounts'][category] =
            (statistics['categoryCounts'][category] ?? 0) + 1;
      }

      return statistics;
    } catch (e) {
      print('제품 통계 조회 오류: $e');

      Get.snackbar(
        '오류',
        '제품 통계를 조회하는 중 문제가 발생했습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
      );

      return {};
    } finally {
      isLoading.value = false;
    }
  }
}

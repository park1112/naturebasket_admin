// lib/screens/admin/product/add_product_screen.dart 수정사항

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/product_controller.dart';
import '../../../controllers/admin_auth_controller.dart';
import '../../../models/product_model.dart';
import '../../../config/theme.dart';
import '../../../utils/custom_loading.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({Key? key}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final ProductController _productController = Get.find<ProductController>();
  final AdminAuthController _authController = Get.find<AdminAuthController>();

  // 폼 컨트롤러
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountPriceController = TextEditingController();
  final _stockController = TextEditingController();
  String _selectedCategory = ProductCategory.eco.toString().split('.').last;
  final _tagsController = TextEditingController();
  final _ecoLabelsController = TextEditingController();
  bool _isEco = false;
  bool _isOrganic = false;
  bool _isFeatured = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    // ProductController가 이미 초기화되어 있는지 확인
    try {
      _productController.loadCategories();
      _productController.clearImages();

      // 재고 기본값 설정
      _stockController.text = '0';

      // 카테고리 초기화를 비동기로 처리
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_productController.categories.isNotEmpty) {
          setState(() {
            _selectedCategory =
                _productController.categories.first.toString().split('.').last;
          });
        }
      });
    } catch (e) {
      // ProductController가 없는 경우 처리
      Get.back(); // 이전 화면으로 돌아가기
      Get.snackbar(
        '오류',
        '상품 관리 초기화에 실패했습니다.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _discountPriceController.dispose();
    _stockController.dispose();
    _tagsController.dispose();
    _ecoLabelsController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      try {
        if (_productController.selectedImages.isEmpty) {
          Get.dialog(
            AlertDialog(
              title: const Text('알림'),
              content: const Text('최소 1개 이상의 상품 이미지를 추가해주세요.'),
              actions: [
                TextButton(
                    onPressed: () => Get.back(), child: const Text('확인')),
              ],
            ),
          );
          return;
        }

        if (_selectedCategory == null) {
          Get.snackbar('알림', '카테고리를 선택해주세요.',
              snackPosition: SnackPosition.BOTTOM);
          return;
        }

        double? discountPrice;
        if (_discountPriceController.text.isNotEmpty) {
          discountPrice = double.tryParse(_discountPriceController.text);
        }

        double originalPrice = double.parse(_priceController.text);
        double sellingPrice = discountPrice ?? originalPrice;

        List<String> tags = _tagsController.text
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList();

        List<String> ecoLabels = _ecoLabelsController.text
            .split(',')
            .map((label) => label.trim())
            .where((label) => label.isNotEmpty)
            .toList();

        bool success = await _productController.createProduct(
          name: _nameController.text,
          description: _descriptionController.text,
          price: originalPrice,
          salePrice: discountPrice,
          sellingPrice: sellingPrice,
          stockQuantity: int.parse(_stockController.text),
          category: _selectedCategory,
          tags: tags,
          isEco: _isEco,
          isOrganic: _isOrganic,
          isFeatured: _isFeatured,
          isActive: _isActive,
          averageRating: 0.0,
          reviewCount: 0,
        );

        if (success) {
          Get.back();
        }
      } catch (e) {
        Get.snackbar(
          '오류',
          '상품 등록 중 문제가 발생했습니다: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.1),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('상품 등록'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isSmallScreen = width < 600;
          final padding = isSmallScreen ? 16.0 : 24.0;

          return Obx(() {
            if (_productController.isLoading.value) {
              return const Center(child: CustomLoading());
            }

            return SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // 이미지 섹션
                    _buildImageSection(isSmallScreen),
                    const SizedBox(height: 24),

                    // 콘텐츠 섹션
                    if (width >= 900)
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildBasicInfoSection(isSmallScreen),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                children: [
                                  _buildDescriptionSection(),
                                  const SizedBox(height: 24),
                                  _buildAdditionalInfoSection(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: [
                          _buildBasicInfoSection(isSmallScreen),
                          const SizedBox(height: 24),
                          _buildDescriptionSection(),
                          const SizedBox(height: 24),
                          _buildAdditionalInfoSection(),
                        ],
                      ),
                    const SizedBox(height: 24),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            );
          });
        },
      ),
    );
  }

  Widget _buildImageSection(bool isSmallScreen) {
    return SizedBox(
      // height를 더 여유있게 조정하거나 아예 높이를 없애서 유동적으로 조절되게 만드세요.
      // 예: height 제거 또는 더 크게 (400 정도 추천)
      height: isSmallScreen ? null : 400, // 이렇게 변경하거나 아예 삭제 추천
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // 여기를 추가하여 높이를 최소화
            children: [
              const Text(
                '상품 이미지',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              AspectRatio(
                aspectRatio: 3 / 2, // 이미지 영역의 비율을 고정하여 일관된 표시
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Obx(() {
                      final hasImages =
                          _productController.selectedImages.isNotEmpty;
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: hasImages
                            ? _buildImagePreview(isSmallScreen, constraints)
                            : _buildEmptyImagePlaceholder(),
                      );
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              _buildImageButtons(isSmallScreen),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview(bool isSmallScreen, BoxConstraints constraints) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: constraints.maxWidth,
        height: constraints.maxHeight,
        child: PageView.builder(
          itemCount: _productController.selectedImages.length,
          itemBuilder: (context, index) {
            return Stack(
              fit: StackFit.expand,
              children: [
                Image.file(
                  _productController.selectedImages[index],
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(Icons.error_outline,
                          color: Colors.red, size: 48),
                    );
                  },
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    radius: isSmallScreen ? 16 : 20,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      iconSize: isSmallScreen ? 16 : 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () =>
                          _productController.removeSelectedImage(index),
                    ),
                  ),
                ),
                if (_productController.selectedImages.length > 1)
                  _buildPageIndicator(index),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPageIndicator(int currentIndex) {
    return Positioned(
      bottom: 8,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _productController.selectedImages.length,
            (index) => Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index == currentIndex
                    ? Colors.white
                    : Colors.white.withOpacity(0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyImagePlaceholder() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey),
          SizedBox(height: 8),
          Text('이미지를 추가해주세요', style: TextStyle(color: Colors.grey)),
          SizedBox(height: 4),
          Text('(상품 이미지는 필수입니다)',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildImageButtons(bool isSmallScreen) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        SizedBox(
          width: isSmallScreen ? double.infinity : 200,
          child: ElevatedButton.icon(
            onPressed: () => _productController.pickImages(),
            icon: const Icon(Icons.photo_library),
            label: const Text('이미지 추가'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        SizedBox(
          width: isSmallScreen ? double.infinity : 200,
          child: ElevatedButton.icon(
            onPressed: () => _productController.takePicture(),
            icon: const Icon(Icons.camera_alt),
            label: const Text('사진 촬영'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection(bool isSmallScreen) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '기본 정보',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '상품명',
                border: OutlineInputBorder(),
                hintText: '예: 유기농 당근 1kg',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '상품명을 입력해주세요.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            if (isSmallScreen) ...[
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: '정상가(원)',
                  border: OutlineInputBorder(),
                  hintText: '예: 5000',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '가격을 입력해주세요.';
                  }
                  if (double.tryParse(value) == null) {
                    return '유효한 숫자를 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _discountPriceController,
                decoration: const InputDecoration(
                  labelText: '할인가(원)',
                  border: OutlineInputBorder(),
                  helperText: '미입력 시 할인 없음',
                  hintText: '예: 4500',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (double.tryParse(value) == null) {
                      return '유효한 숫자를 입력해주세요.';
                    }
                    if (_priceController.text.isNotEmpty &&
                        double.parse(value) >=
                            double.parse(_priceController.text)) {
                      return '할인가는 정상가보다 작아야 합니다.';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(
                  labelText: '재고 수량',
                  border: OutlineInputBorder(),
                  hintText: '예: 100',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '재고 수량을 입력해주세요.';
                  }
                  if (int.tryParse(value) == null) {
                    return '유효한 숫자를 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildCategoryDropdown(),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: '정상가(원)',
                        border: OutlineInputBorder(),
                        hintText: '예: 5000',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '가격을 입력해주세요.';
                        }
                        if (double.tryParse(value) == null) {
                          return '유효한 숫자를 입력해주세요.';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _discountPriceController,
                      decoration: const InputDecoration(
                        labelText: '할인가(원)',
                        border: OutlineInputBorder(),
                        helperText: '미입력 시 할인 없음',
                        hintText: '예: 4500',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (double.tryParse(value) == null) {
                            return '유효한 숫자를 입력해주세요.';
                          }
                          if (_priceController.text.isNotEmpty &&
                              double.parse(value) >=
                                  double.parse(_priceController.text)) {
                            return '할인가는 정상가보다 작아야 합니다.';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      decoration: const InputDecoration(
                        labelText: '재고 수량',
                        border: OutlineInputBorder(),
                        hintText: '예: 100',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '재고 수량을 입력해주세요.';
                        }
                        if (int.tryParse(value) == null) {
                          return '유효한 숫자를 입력해주세요.';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildCategoryDropdown(),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _ecoLabelsController,
              decoration: const InputDecoration(
                labelText: '친환경 인증 정보',
                border: OutlineInputBorder(),
                helperText: '쉼표(,)로 구분하여 입력',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('친환경'),
                    value: _isEco,
                    onChanged: (value) {
                      setState(() {
                        _isEco = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('유기농'),
                    value: _isOrganic,
                    onChanged: (value) {
                      setState(() {
                        _isOrganic = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // GetX의 자주 발생하는 오류(Improper use of GetX)를 방지하기 위해 체크박스 부분 분리
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: isSmallScreen ? double.infinity : 140,
                  child: CheckboxListTile(
                    title: const Text('추천 상품'),
                    value: _isFeatured,
                    onChanged: (value) {
                      setState(() {
                        _isFeatured = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                SizedBox(
                  width: isSmallScreen ? double.infinity : 150,
                  child: CheckboxListTile(
                    title: const Text('판매 활성화'),
                    value: _isActive,
                    onChanged: (value) {
                      setState(() {
                        _isActive = value ?? true;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '상품 설명',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '상품 설명',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
                hintText: '상품의 특징, 원산지, 보관방법 등을 입력해주세요.',
              ),
              maxLines: 10,
              minLines: 5,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '상품 설명을 입력해주세요.';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfoSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '추가 정보',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tagsController, // _tagsController가 선언되어 있어야 합니다.
              decoration: const InputDecoration(
                labelText: '태그',
                border: OutlineInputBorder(),
                helperText: '쉼표(,)로 구분하여 입력 (예: 신선식품, 제철, 유기농)',
              ),
            ),
            const SizedBox(height: 16),
            // --- Row 대신 Wrap 사용 ---
            Wrap(
              alignment: WrapAlignment.spaceBetween, // 최대한 양 끝으로 배치 시도
              crossAxisAlignment: WrapCrossAlignment.center, // 세로 중앙 정렬
              spacing: 16.0, // 가로 여백 (줄바꿈 안될 때)
              runSpacing: 8.0, // 세로 여백 (줄바꿈될 때)
              children: [
                // 왼쪽 텍스트 (크기 제한이 없으므로 그대로 둠)
                const Text(
                  '신규 카테고리 추가',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // 오른쪽 버튼 (크기가 고정될 수 있으므로 그대로 둠)
                ElevatedButton.icon(
                  onPressed:
                      _showAddCategoryDialog, // _showAddCategoryDialog 함수가 정의되어 있어야 함
                  icon: const Icon(Icons.add, size: 18), // 아이콘 크기 조정 가능
                  label: const Text('카테고리 추가'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8), // 버튼 내부 패딩 조정 가능
                    textStyle: const TextStyle(fontSize: 14), // 버튼 텍스트 크기 조정 가능
                  ),
                ),
              ],
            ),
            // --- Wrap 사용 끝 ---
          ],
        ),
      ),
    );
  }

  void _showAddCategoryDialog() {
    final TextEditingController categoryController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('카테고리 추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: categoryController,
              decoration: const InputDecoration(
                labelText: '카테고리명',
                border: OutlineInputBorder(),
                hintText: '예: 유제품, 건강식품',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '카테고리명을 입력해주세요.';
                }
                return null;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (categoryController.text.isNotEmpty) {
                await _productController.addCategory(categoryController.text);

                if (_selectedCategory == null &&
                    _productController.categories.isNotEmpty) {
                  setState(() {
                    _selectedCategory = _productController.categories.first
                        .toString()
                        .split('.')
                        .last;
                  });
                }

                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Obx(() => ElevatedButton(
            onPressed: _productController.isLoading.value ? null : _saveProduct,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _productController.isLoading.value
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    '상품 등록',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          )),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<ProductCategory>(
      value: ProductCategory.values.firstWhere(
        (e) => e.toString().split('.').last == _selectedCategory,
        orElse: () => ProductCategory.values.first,
      ),
      decoration: const InputDecoration(
        labelText: '카테고리',
        border: OutlineInputBorder(),
      ),
      items: ProductCategory.values.map((category) {
        return DropdownMenuItem<ProductCategory>(
          value: category,
          child: Text(category.toString().split('.').last),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedCategory = value.toString().split('.').last;
          });
        }
      },
      validator: (value) {
        if (value == null) {
          return '카테고리를 선택해주세요.';
        }
        return null;
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
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
  final _maxOrderQuantityController = TextEditingController();
  final _originController = TextEditingController();
  final _tagsController = TextEditingController();
  final _ecoLabelsController = TextEditingController();
  final _shippingOriginController = TextEditingController();
  final _shippingFeeController = TextEditingController();

  // 판매 기간 컨트롤러
  final _salesStartDateController = TextEditingController();
  final _salesEndDateController = TextEditingController();

  // 옵션 관련 컨트롤러
  final List<Map<String, dynamic>> _options = [];
  final _optionNameController = TextEditingController();
  final _optionPriceController = TextEditingController();
  final _optionStockController = TextEditingController();

  // 선택 상태 변수
  String _selectedCategory = ProductCategory.food.toString().split('.').last;
  TaxType _selectedTaxType = TaxType.taxable;
  bool _hasShipping = true;
  ShippingMethod _selectedShippingMethod = ShippingMethod.standardDelivery;
  ShippingType _selectedShippingType = ShippingType.standard;
  ShippingFeeType _selectedShippingFeeType = ShippingFeeType.free;
  List<int> _selectedHolidayDays = [];
  DateTime? _salesStartDate;
  DateTime? _salesEndDate;

  // 체크박스 상태
  bool _isEco = false;
  bool _isOrganic = false;
  bool _isFeatured = false;
  bool _isActive = true;
  bool _isSameDayShipping = false;

  // 상품 설명 이미지
  final RxList<String> _descriptionImages = <String>[].obs;

  @override
  void initState() {
    super.initState();
    // ProductController가 이미 초기화되어 있는지 확인
    try {
      _productController.loadCategories();
      _productController.clearImages();

      // 기본값 설정
      _stockController.text = '0';
      _maxOrderQuantityController.text = '10';
      _originController.text = '국내산';
      _shippingFeeController.text = '0';

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
    _maxOrderQuantityController.dispose();
    _originController.dispose();
    _tagsController.dispose();
    _ecoLabelsController.dispose();
    _salesStartDateController.dispose();
    _salesEndDateController.dispose();
    _shippingOriginController.dispose();
    _shippingFeeController.dispose();
    _optionNameController.dispose();
    _optionPriceController.dispose();
    _optionStockController.dispose();
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

        // 가격 정보 처리
        double originalPrice = double.parse(_priceController.text);
        double? discountPrice;
        if (_discountPriceController.text.isNotEmpty) {
          discountPrice = double.tryParse(_discountPriceController.text);
        }
        double sellingPrice = discountPrice ?? originalPrice;

        // 태그 및 라벨 처리
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

        // 배송 정보 생성
        Map<String, dynamic> sameDaySettings = {};
        if (_selectedShippingType == ShippingType.sameDay &&
            _isSameDayShipping) {
          sameDaySettings = {
            'cutoffTime': '13:00', // 기본값으로 13시 설정
            'availableOnWeekends': false,
          };
        }

        double? shippingFee;
        if (_selectedShippingFeeType == ShippingFeeType.paid &&
            _shippingFeeController.text.isNotEmpty) {
          shippingFee = double.tryParse(_shippingFeeController.text);
        }

        // 옵션 처리
        List<ProductOption> productOptions = _options.map((option) {
          return ProductOption(
            id: const Uuid().v4(), // 새 옵션은 고유 ID 생성
            name: option['name'],
            additionalPrice: option['price'],
            stockQuantity: option['stock'],
            isAvailable: option['isAvailable'],
          );
        }).toList();

        // 배송 정보 생성
        ShippingInfo shippingInfo = ShippingInfo(
          hasShipping: _hasShipping,
          method: _selectedShippingMethod,
          type: _selectedShippingType,
          sameDaySettings: _isSameDayShipping ? sameDaySettings : null,
          holidayDays: _selectedHolidayDays,
          feeType: _selectedShippingFeeType,
          feeAmount: shippingFee,
          shippingOrigin: _shippingOriginController.text.isNotEmpty
              ? _shippingOriginController.text
              : null,
        );

        bool success = await _productController.createProductExtended(
          name: _nameController.text,
          description: _descriptionController.text,
          descriptionImages: _descriptionImages.toList(),
          price: originalPrice,
          discountPrice: discountPrice,
          sellingPrice: sellingPrice,
          stockQuantity: int.parse(_stockController.text),
          maxOrderQuantity: int.parse(_maxOrderQuantityController.text),
          origin: _originController.text,
          category: _selectedCategory,
          options: productOptions,
          tags: tags,
          isEco: _isEco,
          ecoLabels: ecoLabels.isEmpty ? null : ecoLabels,
          isOrganic: _isOrganic,
          isFeatured: _isFeatured,
          isActive: _isActive,
          salesStartDate: _salesStartDate,
          salesEndDate: _salesEndDate,
          taxType: _selectedTaxType,
          shippingInfo: shippingInfo,
          averageRating: 0.0,
          reviewCount: 0,
        );

        if (success) {
          Get.back();
          Get.snackbar(
            '성공',
            '상품이 성공적으로 등록되었습니다.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.withOpacity(0.1),
          );
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

  // 판매 시작일 선택
  Future<void> _selectSalesStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _salesStartDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        _salesStartDate = picked;
        _salesStartDateController.text =
            DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // 판매 종료일 선택
  Future<void> _selectSalesEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _salesEndDate ??
          (_salesStartDate ?? DateTime.now()).add(const Duration(days: 30)),
      firstDate: _salesStartDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        _salesEndDate = picked;
        _salesEndDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // 옵션 추가 다이얼로그
  void _showAddOptionDialog() {
    _optionNameController.text = '';
    _optionPriceController.text = '0';
    _optionStockController.text = '0';
    bool isAvailable = true;

    Get.dialog(
      AlertDialog(
        title: const Text('옵션 추가'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _optionNameController,
                decoration: const InputDecoration(
                  labelText: '옵션명',
                  hintText: '예: 사이즈, 색상 등',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _optionPriceController,
                decoration: const InputDecoration(
                  labelText: '추가 금액',
                  hintText: '예: 1000',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _optionStockController,
                decoration: const InputDecoration(
                  labelText: '재고 수량',
                  hintText: '예: 10',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setState) {
                  return SizedBox(
                    width: 200,
                    child: CheckboxListTile(
                      title: const Text('판매 가능'),
                      value: isAvailable,
                      onChanged: (value) {
                        setState(() {
                          isAvailable = value ?? true;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              // 옵션 추가
              if (_optionNameController.text.isNotEmpty) {
                setState(() {
                  _options.add({
                    'name': _optionNameController.text,
                    'price':
                        double.tryParse(_optionPriceController.text) ?? 0.0,
                    'stock': int.tryParse(_optionStockController.text) ?? 0,
                    'isAvailable': isAvailable,
                  });
                });
                Get.back();
              } else {
                Get.snackbar(
                  '알림',
                  '옵션명을 입력해주세요.',
                  snackPosition: SnackPosition.BOTTOM,
                );
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

  // 옵션 삭제
  void _removeOption(int index) {
    setState(() {
      _options.removeAt(index);
    });
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 이미지 섹션
                    _buildImageSection(isSmallScreen),
                    const SizedBox(height: 24),

                    // 콘텐츠 섹션 (반응형 레이아웃)
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

                    // 옵션 섹션
                    _buildOptionsSection(),
                    const SizedBox(height: 24),

                    // 판매 기간 섹션
                    _buildSalesPeriodSection(),
                    const SizedBox(height: 24),

                    // 배송 정보 섹션
                    _buildShippingInfoSection(),
                    const SizedBox(height: 24),

                    // 등록 버튼
                    _buildSubmitButton(),

                    // 여백 추가
                    const SizedBox(height: 60),
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
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '상품 이미지',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 3 / 2,
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

            // 상품명 입력
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

            // 원산지와 부가세 유형
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _originController,
                    decoration: const InputDecoration(
                      labelText: '원산지',
                      border: OutlineInputBorder(),
                      hintText: '예: 국내산, 중국산 등',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '원산지를 입력해주세요.';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<TaxType>(
                    decoration: const InputDecoration(
                      labelText: '부가세 유형',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedTaxType,
                    items: TaxType.values.map((type) {
                      String label;
                      switch (type) {
                        case TaxType.taxable:
                          label = '과세상품';
                          break;
                        case TaxType.taxFree:
                          label = '면세상품';
                          break;
                        case TaxType.zeroTax:
                          label = '영세상품';
                          break;
                      }
                      return DropdownMenuItem<TaxType>(
                        value: type,
                        child: Text(label),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedTaxType = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 가격 정보
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

            // 재고 및 주문 수량
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
                  child: TextFormField(
                    controller: _maxOrderQuantityController,
                    decoration: const InputDecoration(
                      labelText: '최대 주문 수량',
                      border: OutlineInputBorder(),
                      hintText: '예: 10',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '최대 주문 수량을 입력해주세요.';
                      }
                      if (int.tryParse(value) == null) {
                        return '유효한 숫자를 입력해주세요.';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 카테고리 선택
            _buildCategoryDropdown(),
            const SizedBox(height: 16),

            // 친환경 인증 정보
            TextFormField(
              controller: _ecoLabelsController,
              decoration: const InputDecoration(
                labelText: '친환경 인증 정보',
                border: OutlineInputBorder(),
                helperText: '쉼표(,)로 구분하여 입력',
              ),
            ),
            const SizedBox(height: 16),

            // 체크박스 그룹
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: 200,
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
                SizedBox(
                  width: 200,
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
                SizedBox(
                  width: 200,
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
                  width: 200,
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
            const SizedBox(height: 16),
            const Text(
              '설명 이미지 추가',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      // 이미지 선택 후 설명 이미지 목록에 추가
                      final result = await _productController.pickSingleImage();
                      if (result != null) {
                        _descriptionImages.add(result);
                      }
                    },
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('이미지 추가'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Obx(
              () => _descriptionImages.isEmpty
                  ? const Text('설명 이미지가 없습니다.',
                      style: TextStyle(color: Colors.grey))
                  : SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _descriptionImages.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    _descriptionImages[index],
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Center(
                                      child:
                                          Icon(Icons.error, color: Colors.red),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 8,
                                top: 0,
                                child: InkWell(
                                  onTap: () =>
                                      _descriptionImages.removeAt(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
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
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: '태그',
                border: OutlineInputBorder(),
                helperText: '쉼표(,)로 구분하여 입력 (예: 신선식품, 제철, 유기농)',
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16.0,
              runSpacing: 8.0,
              children: [
                const Text(
                  '신규 카테고리 추가',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showAddCategoryDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('카테고리 추가'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsSection() {
    // 가격 포맷터 (필요에 따라 사용)
    final currencyFormat = NumberFormat('#,##0');

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    '상품 옵션',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showAddOptionDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('옵션 추가'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor, // AppTheme 사용 확인
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _options.isEmpty
                ? const Center(
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 16.0), // 위아래 여백 추가
                      child: Text('등록된 옵션이 없습니다.'),
                    ),
                  )
                // --- 변경된 부분 시작 ---
                : ListView.builder(
                    shrinkWrap:
                        true, // 중요: Column 내부에서 ListView가 자신의 콘텐츠 크기만큼만 차지하도록 함
                    physics:
                        const NeverScrollableScrollPhysics(), // 중요: 부모 스크롤뷰와 스크롤 충돌 방지
                    itemCount: _options.length,
                    itemBuilder: (context, index) {
                      final option = _options[index];
                      // 옵션 데이터 타입 확인 (Map<String, dynamic> 가정)
                      final String name = option['name'] ?? '이름 없음';
                      final double price = (option['price'] is num)
                          ? (option['price'] as num).toDouble()
                          : 0.0;
                      final int stock = (option['stock'] is num)
                          ? (option['stock'] as num).toInt()
                          : 0;
                      final bool isAvailable = (option['isAvailable'] is bool)
                          ? option['isAvailable']
                          : false;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(name),
                          subtitle: Text(
                            '추가 금액: ${currencyFormat.format(price)}원 | 재고: ${stock}개 | 판매 상태: ${isAvailable ? '판매중' : '품절'}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            // _removeOption 함수가 index를 받도록 수정되었다고 가정
                            // 만약 option 객체를 받는다면: onPressed: () => _removeOption(option),
                            onPressed: () => _removeOption(index),
                          ),
                        ),
                      );
                    },
                  ),
            // --- 변경된 부분 끝 ---
          ],
        ),
      ),
    );
  }

  Widget _buildSalesPeriodSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '판매 기간',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '미입력 시 상시 판매 상품으로 등록됩니다.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _salesStartDateController,
                    readOnly: true,
                    onTap: _selectSalesStartDate,
                    decoration: InputDecoration(
                      labelText: '판매 시작일',
                      border: const OutlineInputBorder(),
                      hintText: '선택하기',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: _selectSalesStartDate,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _salesEndDateController,
                    readOnly: true,
                    onTap: _selectSalesEndDate,
                    decoration: InputDecoration(
                      labelText: '판매 종료일',
                      border: const OutlineInputBorder(),
                      hintText: '선택하기',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: _selectSalesEndDate,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShippingInfoSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '배송 정보',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('배송 여부'),
              subtitle: Text(_hasShipping ? '배송함' : '배송 없음'),
              value: _hasShipping,
              onChanged: (value) {
                setState(() {
                  _hasShipping = value;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            if (_hasShipping) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<ShippingMethod>(
                      decoration: const InputDecoration(
                        labelText: '배송 방법',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedShippingMethod,
                      items: ShippingMethod.values.map((method) {
                        String label;
                        switch (method) {
                          case ShippingMethod.standardDelivery:
                            label = '일반택배';
                            break;
                          case ShippingMethod.directDelivery:
                            label = '직접배송';
                            break;
                        }
                        return DropdownMenuItem<ShippingMethod>(
                          value: method,
                          child: Text(label),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedShippingMethod = value;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<ShippingType>(
                      decoration: const InputDecoration(
                        labelText: '배송 속성',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedShippingType,
                      items: ShippingType.values.map((type) {
                        String label;
                        switch (type) {
                          case ShippingType.standard:
                            label = '일반배송';
                            break;
                          case ShippingType.sameDay:
                            label = '오늘출발';
                            break;
                        }
                        return DropdownMenuItem<ShippingType>(
                          value: type,
                          child: Text(label),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedShippingType = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_selectedShippingType == ShippingType.sameDay) ...[
                SwitchListTile(
                  title: const Text('오늘출발 설정'),
                  subtitle: const Text('13시 이전 주문 시 당일 출고'),
                  value: _isSameDayShipping,
                  onChanged: (value) {
                    setState(() {
                      _isSameDayShipping = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
              ],
              const Text('휴무일 지정',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildDayCheckbox(1, '월'),
                  _buildDayCheckbox(2, '화'),
                  _buildDayCheckbox(3, '수'),
                  _buildDayCheckbox(4, '목'),
                  _buildDayCheckbox(5, '금'),
                  _buildDayCheckbox(6, '토'),
                  _buildDayCheckbox(7, '일'),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<ShippingFeeType>(
                      decoration: const InputDecoration(
                        labelText: '배송비 유형',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedShippingFeeType,
                      items: ShippingFeeType.values.map((feeType) {
                        String label;
                        switch (feeType) {
                          case ShippingFeeType.free:
                            label = '무료배송';
                            break;
                          case ShippingFeeType.paid:
                            label = '유료배송';
                            break;
                        }
                        return DropdownMenuItem<ShippingFeeType>(
                          value: feeType,
                          child: Text(label),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedShippingFeeType = value;
                          });
                        }
                      },
                    ),
                  ),
                  if (_selectedShippingFeeType == ShippingFeeType.paid) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _shippingFeeController,
                        decoration: const InputDecoration(
                          labelText: '배송비(원)',
                          border: OutlineInputBorder(),
                          hintText: '예: 3000',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (_selectedShippingFeeType ==
                                  ShippingFeeType.paid &&
                              (value == null || value.isEmpty)) {
                            return '배송비를 입력해주세요.';
                          }
                          if (value != null &&
                              value.isNotEmpty &&
                              double.tryParse(value) == null) {
                            return '유효한 숫자를 입력해주세요.';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _shippingOriginController,
                decoration: const InputDecoration(
                  labelText: '출고지 주소',
                  border: OutlineInputBorder(),
                  hintText: '예: 서울특별시 강남구 테헤란로 123',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDayCheckbox(int day, String label) {
    return FilterChip(
      label: Text(label),
      selected: _selectedHolidayDays.contains(day),
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedHolidayDays.add(day);
          } else {
            _selectedHolidayDays.remove(day);
          }
        });
      },
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryColor,
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
        String label;
        switch (category) {
          case ProductCategory.food:
            label = '식품';
            break;
          case ProductCategory.living:
            label = '생활용품';
            break;
          case ProductCategory.beauty:
            label = '뷰티';
            break;
          case ProductCategory.fashion:
            label = '패션';
            break;
          case ProductCategory.home:
            label = '가정용품';
            break;
          case ProductCategory.eco:
            label = '친환경/자연';
            break;
        }
        return DropdownMenuItem<ProductCategory>(
          value: category,
          child: Text(label),
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

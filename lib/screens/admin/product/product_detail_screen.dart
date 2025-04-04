// lib/screens/admin/product/product_detail_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/product_controller.dart';
import '../../../controllers/admin_auth_controller.dart';
import '../../../models/product_model.dart';
import '../../../config/theme.dart';
import '../../../utils/custom_loading.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final bool isEditMode;

  const ProductDetailScreen({
    Key? key,
    required this.productId,
    this.isEditMode = false,
  }) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ProductController _productController = Get.find<ProductController>();
  final AdminAuthController _authController = Get.find<AdminAuthController>();

  ProductModel? _product;
  bool _isLoading = true;
  bool _isEditing = false;

  // 폼 컨트롤러
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _stockController = TextEditingController();
  String _selectedCategory = '';
  final _tagsController = TextEditingController();
  bool _isOrganic = false;
  bool _isFeatured = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.isEditMode;
    _loadProductDetails();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _salePriceController.dispose();
    _stockController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _loadProductDetails() async {
    // 로딩 상태를 먼저 설정
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // 상품 정보 로드
      final product =
          await _productController.getProductDetails(widget.productId);

      // 위젯이 여전히 마운트되어 있는지 확인
      if (!mounted) return;

      if (product != null) {
        setState(() {
          _product = product;
          // 폼 초기화
          _nameController.text = product.name;
          _descriptionController.text = product.description;
          _priceController.text = product.price.toString();
          _salePriceController.text = product.discountPrice?.toString() ?? '';
          _stockController.text = product.stockQuantity.toString();
          _selectedCategory = product.category.toString().split('.').last;
          _tagsController.text = product.tags?.join(', ') ?? '';
          _isOrganic = product.isOrganic;
          _isFeatured = product.isFeatured;
          _isActive = product.isActive;
          _isLoading = false;
        });
      } else {
        setState(() {
          _product = null;
          _isLoading = false;
        });

        Get.snackbar(
          '알림',
          '상품 정보를 찾을 수 없습니다.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.withOpacity(0.1),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      Get.snackbar(
        '오류',
        '상품 정보를 불러오는 중 문제가 발생했습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
      );
    }
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      try {
        double? salePrice;
        if (_salePriceController.text.isNotEmpty) {
          salePrice = double.tryParse(_salePriceController.text);
        }

        List<String> tags = _tagsController.text
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList();

        bool success = await _productController.updateProduct(
          productId: widget.productId,
          name: _nameController.text,
          description: _descriptionController.text,
          price: double.parse(_priceController.text),
          salePrice: salePrice,
          stockQuantity: int.parse(_stockController.text),
          category: _selectedCategory,
          tags: tags,
          isOrganic: _isOrganic,
          isFeatured: _isFeatured,
          isActive: _isActive,
        );

        if (success) {
          setState(() {
            _isEditing = false;
          });

          // 화면 새로고침
          _loadProductDetails();
        }
      } catch (e) {
        Get.snackbar(
          '오류',
          '상품 정보 저장 중 문제가 발생했습니다: $e',
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
        title: Text(_isEditing ? '상품 수정' : '상품 상세'),
        actions: [
          if (!_isEditing && _authController.hasPermission('edit_product'))
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isEditing = false;

                  // 폼 초기화
                  if (_product != null) {
                    _nameController.text = _product!.name;
                    _descriptionController.text = _product!.description;
                    _priceController.text = _product!.price.toString();
                    _salePriceController.text =
                        _product!.discountPrice?.toString() ?? '';
                    _stockController.text = _product!.stockQuantity.toString();
                    _selectedCategory =
                        _product!.category.toString().split('.').last;
                    _tagsController.text = _product!.tags?.join(', ') ?? '';
                    _isOrganic = _product!.isOrganic;
                    _isFeatured = _product!.isFeatured;
                    _isActive = _product!.isActive;
                  }

                  // 이미지 선택 초기화
                  _productController.clearImages();
                  if (_product != null) {
                    _productController.currentImages.value =
                        List<String>.from(_product!.images);
                  }
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CustomLoading())
          : _product == null
              ? const Center(child: Text('상품 정보를 찾을 수 없습니다.'))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    bool isSmallScreen = constraints.maxWidth < 600;

                    return SingleChildScrollView(
                      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                      child: _buildContent(isSmallScreen),
                    );
                  },
                ),
      bottomNavigationBar: _isEditing
          ? BottomAppBar(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isEditing = false;

                            // 폼 초기화
                            if (_product != null) {
                              _nameController.text = _product!.name;
                              _descriptionController.text =
                                  _product!.description;
                              _priceController.text =
                                  _product!.price.toString();
                              _salePriceController.text =
                                  _product!.discountPrice?.toString() ?? '';
                              _stockController.text =
                                  _product!.stockQuantity.toString();
                              _selectedCategory =
                                  _product!.category.toString().split('.').last;
                              _tagsController.text =
                                  _product!.tags?.join(', ') ?? '';
                              _isOrganic = _product!.isOrganic;
                              _isFeatured = _product!.isFeatured;
                              _isActive = _product!.isActive;
                            }

                            // 이미지 선택 초기화
                            _productController.clearImages();
                            if (_product != null) {
                              _productController.currentImages.value =
                                  List<String>.from(_product!.images);
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('취소'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Obx(() => ElevatedButton(
                            onPressed: _productController.isLoading.value
                                ? null
                                : _saveProduct,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            child: _productController.isLoading.value
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('저장'),
                          )),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildContent(bool isSmallScreen) {
    if (isSmallScreen) {
      return Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSection(),
            const SizedBox(height: 24),
            _buildBasicInfoSection(),
            const SizedBox(height: 24),
            _buildDescriptionSection(),
            const SizedBox(height: 24),
            _buildAdditionalInfoSection(),
          ],
        ),
      );
    } else {
      return Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _buildImageSection(),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBasicInfoSection(),
                      const SizedBox(height: 24),
                      _buildDescriptionSection(),
                      const SizedBox(height: 24),
                      _buildAdditionalInfoSection(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  Widget _buildImageSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '상품 이미지',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Obx(() {
              final List<String> images = _productController.currentImages;
              final List<Widget> imageWidgets = [];

              for (String image in images) {
                imageWidgets.add(
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          image,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 300,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: double.infinity,
                              height: 300,
                              color: Colors.grey.shade200,
                              child: const Center(
                                child:
                                    Icon(Icons.image_not_supported, size: 48),
                              ),
                            );
                          },
                        ),
                      ),
                      if (_isEditing)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: CircleAvatar(
                            backgroundColor: Colors.black.withOpacity(0.5),
                            child: IconButton(
                              icon:
                                  const Icon(Icons.close, color: Colors.white),
                              onPressed: () {
                                int index = images.indexOf(image);
                                if (index != -1) {
                                  _productController.removeCurrentImage(index);
                                }
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }

              final List<Widget> selectedImages = [];
              for (var i = 0;
                  i < _productController.selectedImages.length;
                  i++) {
                selectedImages.add(
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _productController.selectedImages[i],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 300,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: CircleAvatar(
                          backgroundColor: Colors.black.withOpacity(0.5),
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () {
                              _productController.removeSelectedImage(i);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final List<Widget> allImages = [
                ...imageWidgets,
                ...selectedImages
              ];

              if (allImages.isEmpty) {
                return Container(
                  width: double.infinity,
                  height: 300,
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: Text('등록된 이미지가 없습니다.'),
                  ),
                );
              }

              if (allImages.length == 1) {
                return allImages.first;
              }

              return Column(
                children: [
                  SizedBox(
                    height: 300,
                    child: PageView.builder(
                      itemCount: allImages.length,
                      itemBuilder: (context, index) {
                        return allImages[index];
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isEditing)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
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
                        const SizedBox(width: 16),
                        Expanded(
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
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
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
            if (_isEditing) ...[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '상품명',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '상품명을 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: '정상가(원)',
                        border: OutlineInputBorder(),
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
                      controller: _salePriceController,
                      decoration: const InputDecoration(
                        labelText: '할인가(원)',
                        border: OutlineInputBorder(),
                        helperText: '미입력 시 할인 없음',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (double.tryParse(value) == null) {
                            return '유효한 숫자를 입력해주세요.';
                          }
                          if (double.parse(value) >=
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
                    child: Obx(() => DropdownButtonFormField<String>(
                          value: _selectedCategory.isEmpty
                              ? _productController.categories.isNotEmpty
                                  ? _productController.categories[0]
                                  : ''
                              : _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: '카테고리',
                            border: OutlineInputBorder(),
                          ),
                          items: _productController.categories
                              .map((category) => DropdownMenuItem<String>(
                                    value: category,
                                    child: Text(category),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedCategory = value;
                              });
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '카테고리를 선택해주세요.';
                            }
                            return null;
                          },
                        )),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
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
                  Expanded(
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
                  Expanded(
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
            ] else ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('상품명'),
                subtitle: Text(
                  _product!.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('가격'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_product!.price.toStringAsFixed(0)}원',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration: _product!.discountPrice != null
                            ? TextDecoration.lineThrough
                            : null,
                        color: _product!.discountPrice != null
                            ? Colors.grey.shade500
                            : Colors.black,
                      ),
                    ),
                    if (_product!.discountPrice != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${_product!.discountPrice!.toStringAsFixed(0)}원',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${_product!.discountRate.toStringAsFixed(0)}% 할인',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('재고 수량'),
                subtitle: Text(
                  '${_product!.stockQuantity}개',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _product!.stockQuantity <= 0
                        ? Colors.red
                        : _product!.stockQuantity <= 10
                            ? Colors.orange
                            : Colors.black,
                  ),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('카테고리'),
                subtitle: Text(
                  _product!.category.toString().split('.').last,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
              Row(
                children: [
                  if (_product!.isOrganic)
                    Card(
                      color: Colors.green.withOpacity(0.1),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Text(
                          '유기농',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (_product!.isFeatured)
                    Card(
                      color: Colors.orange.withOpacity(0.1),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Text(
                          '추천 상품',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  if (!_product!.isActive)
                    Card(
                      color: Colors.red.withOpacity(0.1),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Text(
                          '비활성화',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
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
            if (_isEditing)
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '상품 설명',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 10,
                minLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '상품 설명을 입력해주세요.';
                  }
                  return null;
                },
              )
            else
              Text(
                _product!.description,
                style: const TextStyle(
                  fontSize: 16,
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
            if (_isEditing)
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: '태그',
                  border: OutlineInputBorder(),
                  helperText: '쉼표(,)로 구분하여 입력',
                ),
              )
            else if (_product!.tags != null && _product!.tags!.isNotEmpty) ...[
              const Text(
                '태그',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _product!.tags
                        ?.map((tag) => Chip(
                              label: Text(tag),
                              backgroundColor: Colors.grey.shade200,
                            ))
                        .toList() ??
                    [],
              ),
            ],
            const SizedBox(height: 16),
            if (!_isEditing) ...[
              const Text(
                '등록 정보',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('등록자: ${_product!.createdBy}'),
              Text('등록일: ${_formatDateTime(_product!.createdAt)}'),
              Text('최종 수정자: ${_product!.updatedBy}'),
              Text(
                  '최종 수정일: ${_formatDateTime(_product!.updatedAt ?? DateTime.now())}'),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

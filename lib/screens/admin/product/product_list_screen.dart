// lib/screens/admin/product/product_list_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/product_controller.dart';
import '../../../controllers/admin_auth_controller.dart';
import '../../../models/product_model.dart';
import '../../../config/theme.dart';
import '../../../utils/custom_loading.dart';
import 'product_detail_screen.dart';
import 'add_product_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({Key? key}) : super(key: key);

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ProductController _productController = Get.find<ProductController>();
  final AdminAuthController _authController = Get.find<AdminAuthController>();

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _productController.loadProducts();
    _productController.loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('상품 관리'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _productController.loadProducts(),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isSmallScreen = constraints.maxWidth < 600;

          return Column(
            children: [
              _buildSearchAndFilters(isSmallScreen),
              Expanded(
                child: Obx(() {
                  if (_productController.isLoading.value) {
                    return const Center(
                      child: CustomLoading(),
                    );
                  }

                  if (_productController.products.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '등록된 상품이 없습니다.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_authController.hasPermission('create_product'))
                            ElevatedButton.icon(
                              onPressed: () =>
                                  Get.to(() => const AddProductScreen()),
                              icon: const Icon(Icons.add),
                              label: const Text('상품 등록'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    );
                  }

                  return isSmallScreen
                      ? _buildMobileProductList()
                      : _buildDesktopProductTable();
                }),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Obx(() {
        if (_authController.hasPermission('create_product')) {
          return FloatingActionButton(
            onPressed: () => Get.to(() => const AddProductScreen()),
            backgroundColor: AppTheme.primaryColor,
            child: const Icon(Icons.add),
          );
        }
        return const SizedBox.shrink();
      }),
    );
  }

  Widget _buildSearchAndFilters(bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '상품명 검색',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _productController.setSearchQuery('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 0,
                    ),
                  ),
                  onSubmitted: (value) {
                    _productController.setSearchQuery(value);
                  },
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  _productController.setSearchQuery(_searchController.text);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(50, 48),
                ),
                child: const Icon(Icons.search),
              ),
            ],
          ),
          if (!isSmallScreen) ...[
            const SizedBox(height: 16),
            Obx(() => Row(
                  children: [
                    // 카테고리 필터
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _productController.categoryFilter.value == 'all'
                            ? 'all'
                            : _productController.categoryFilter.value,
                        decoration: InputDecoration(
                          labelText: '카테고리',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 0,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: 'all',
                            child: Text('전체 카테고리'),
                          ),
                          ..._productController.categories
                              .map((category) => DropdownMenuItem<String>(
                                    value: category,
                                    child: Text(category),
                                  ))
                              .toList(),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            _productController.setCategoryFilter(value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 재고 필터
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _productController.stockFilter.value,
                        decoration: InputDecoration(
                          labelText: '재고 상태',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 0,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem<String>(
                            value: 'all',
                            child: Text('전체 재고'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'inStock',
                            child: Text('재고 있음'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'lowStock',
                            child: Text('재고 부족'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'outOfStock',
                            child: Text('품절'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            _productController.setStockFilter(value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 유기농 여부
                    FilterChip(
                      label: const Text('유기농 제품'),
                      selected: _productController.organicFilter.value,
                      onSelected: (selected) {
                        _productController.setOrganicFilter(selected);
                      },
                      backgroundColor: Colors.transparent,
                      selectedColor: AppTheme.primaryColor.withOpacity(0.1),
                      checkmarkColor: AppTheme.primaryColor,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildMobileProductList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _productController.products.length,
      itemBuilder: (context, index) {
        final product = _productController.products[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => Get.to(() => ProductDetailScreen(productId: product.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상품 이미지
            AspectRatio(
              aspectRatio: 16 / 9,
              child: product.images.isNotEmpty
                  ? Image.network(
                      product.images.first,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Icon(Icons.image_not_supported, size: 48),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.image, size: 48),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상품명과 상태 표시
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildStatusBadge(
                          product.isActive, product.stockQuantity.toString()),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 가격 정보
                  Row(
                    children: [
                      Text(
                        '${product.price.toStringAsFixed(0)}원',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: product.discountPrice != null
                              ? Colors.grey.shade500
                              : Colors.black,
                          decoration: product.discountPrice != null
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (product.discountPrice != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '${product.discountPrice!.toStringAsFixed(0)}원',
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
                            '${product.discountRate.toStringAsFixed(0)}% 할인',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 카테고리 및 태그
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          product.category.toString().split('.').last,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (product.isOrganic)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '유기농',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 재고 정보
                  Row(
                    children: [
                      Icon(
                        Icons.inventory,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '재고: ${product.stockQuantity}개',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 관리 버튼
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (_authController.hasPermission('edit_product'))
                        IconButton(
                          icon: const Icon(Icons.edit),
                          color: Colors.blue,
                          onPressed: () => Get.to(() => ProductDetailScreen(
                                productId: product.id,
                                isEditMode: true,
                              )),
                        ),
                      if (_authController.hasPermission('manage_inventory'))
                        IconButton(
                          icon: const Icon(Icons.inventory),
                          color: Colors.orange,
                          onPressed: () => _showStockUpdateDialog(product),
                        ),
                      if (_authController
                          .hasPermission('toggle_product_status'))
                        IconButton(
                          icon: Icon(product.isActive
                              ? Icons.visibility_off
                              : Icons.visibility),
                          color: product.isActive ? Colors.red : Colors.green,
                          onPressed: () =>
                              _showToggleStatusConfirmation(product),
                        ),
                      if (_authController.hasPermission('delete_product'))
                        IconButton(
                          icon: const Icon(Icons.delete),
                          color: Colors.red,
                          onPressed: () => _showDeleteConfirmation(product),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopProductTable() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 1,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              DataColumn(
                label: const Text('상품'),
                onSort: (columnIndex, ascending) {
                  _productController.setSortBy('name');
                },
              ),
              DataColumn(
                label: const Text('가격'),
                onSort: (columnIndex, ascending) {
                  _productController.setSortBy('price');
                },
              ),
              const DataColumn(label: Text('카테고리')),
              DataColumn(
                label: const Text('재고'),
                onSort: (columnIndex, ascending) {
                  _productController.setSortBy('stockQuantity');
                },
              ),
              const DataColumn(label: Text('상태')),
              const DataColumn(label: Text('작업')),
            ],
            rows: _productController.products.map((product) {
              return DataRow(
                cells: [
                  DataCell(
                    Row(
                      children: [
                        if (product.images.isNotEmpty)
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                product.images.first,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                  Icons.image_not_supported,
                                  size: 24,
                                ),
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.image, size: 24),
                          ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              product.isOrganic ? '유기농' : '',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    onTap: () => Get.to(
                        () => ProductDetailScreen(productId: product.id)),
                  ),
                  DataCell(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${product.price.toStringAsFixed(0)}원',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: product.discountPrice != null
                                ? TextDecoration.lineThrough
                                : null,
                            color: product.discountPrice != null
                                ? Colors.grey.shade500
                                : Colors.black,
                          ),
                        ),
                        if (product.discountPrice != null)
                          Text(
                            '${product.discountPrice!.toStringAsFixed(0)}원 (${product.discountRate.toStringAsFixed(0)}%↓)',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                  DataCell(
                    Text(product.category.toString().split('.').last),
                  ),
                  DataCell(
                    Text(
                      '${product.stockQuantity}개',
                      style: TextStyle(
                        color: product.stockQuantity <= 0
                            ? Colors.red
                            : product.stockQuantity <= 10
                                ? Colors.orange
                                : Colors.black,
                        fontWeight: product.stockQuantity <= 10
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  DataCell(
                    _buildStatusBadge(
                        product.isActive, product.stockQuantity.toString()),
                  ),
                  DataCell(
                    Row(
                      children: [
                        if (_authController.hasPermission('edit_product'))
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            color: Colors.blue,
                            tooltip: '편집',
                            onPressed: () => Get.to(() => ProductDetailScreen(
                                  productId: product.id,
                                  isEditMode: true,
                                )),
                          ),
                        if (_authController.hasPermission('manage_inventory'))
                          IconButton(
                            icon: const Icon(Icons.inventory, size: 20),
                            color: Colors.orange,
                            tooltip: '재고 관리',
                            onPressed: () => _showStockUpdateDialog(product),
                          ),
                        if (_authController
                            .hasPermission('toggle_product_status'))
                          IconButton(
                            icon: Icon(
                              product.isActive
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: 20,
                            ),
                            color: product.isActive ? Colors.red : Colors.green,
                            tooltip: product.isActive ? '비활성화' : '활성화',
                            onPressed: () =>
                                _showToggleStatusConfirmation(product),
                          ),
                        if (_authController.hasPermission('delete_product'))
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20),
                            color: Colors.red,
                            tooltip: '삭제',
                            onPressed: () => _showDeleteConfirmation(product),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive, String stockStatus) {
    String text;
    Color color;

    if (!isActive) {
      text = '비활성';
      color = Colors.grey;
    } else if (stockStatus == 'outOfStock') {
      text = '품절';
      color = Colors.red;
    } else if (stockStatus == 'lowStock') {
      text = '부족';
      color = Colors.orange;
    } else {
      text = '판매중';
      color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  void _showFilterDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('필터 설정'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 카테고리 필터
              const Text('카테고리'),
              const SizedBox(height: 8),
              Obx(() => DropdownButtonFormField<String>(
                    value: _productController.categoryFilter.value == 'all'
                        ? 'all'
                        : _productController.categoryFilter.value,
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 0,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: 'all',
                        child: Text('전체 카테고리'),
                      ),
                      ..._productController.categories
                          .map((category) => DropdownMenuItem<String>(
                                value: category,
                                child: Text(category),
                              ))
                          .toList(),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        _productController.setCategoryFilter(value);
                      }
                    },
                  )),
              const SizedBox(height: 16),

              // 재고 필터
              const Text('재고 상태'),
              const SizedBox(height: 8),
              Obx(() => DropdownButtonFormField<String>(
                    value: _productController.stockFilter.value,
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 0,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem<String>(
                        value: 'all',
                        child: Text('전체 재고'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'inStock',
                        child: Text('재고 있음'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'lowStock',
                        child: Text('재고 부족'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'outOfStock',
                        child: Text('품절'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        _productController.setStockFilter(value);
                      }
                    },
                  )),
              const SizedBox(height: 16),

              // 유기농 여부
              Row(
                children: [
                  Obx(() => Checkbox(
                        value: _productController.organicFilter.value,
                        onChanged: (value) {
                          if (value != null) {
                            _productController.setOrganicFilter(value);
                          }
                        },
                      )),
                  const Text('유기농 제품만 보기'),
                ],
              ),
              const SizedBox(height: 16),

              // 정렬 기준
              const Text('정렬 기준'),
              const SizedBox(height: 8),
              Obx(() {
                final sortFields = [
                  {'value': 'name', 'label': '상품명'},
                  {'value': 'price', 'label': '가격'},
                  {'value': 'createdAt', 'label': '등록일'},
                  {'value': 'stockQuantity', 'label': '재고 수량'},
                ];

                return Column(
                  children: sortFields
                      .map((field) => RadioListTile<String>(
                            title: Text(field['label'] as String),
                            value: field['value'] as String,
                            groupValue: _productController.sortBy.value,
                            onChanged: (value) {
                              if (value != null) {
                                _productController.setSortBy(value);
                              }
                            },
                            secondary: IconButton(
                              icon: Icon(
                                _productController.sortBy.value ==
                                        field['value']
                                    ? _productController.sortAscending.value
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward
                                    : Icons.swap_vert,
                                size: 20,
                              ),
                              onPressed: () {
                                if (_productController.sortBy.value ==
                                    field['value']) {
                                  _productController.sortAscending.value =
                                      !_productController.sortAscending.value;
                                  _productController.loadProducts();
                                } else {
                                  _productController
                                      .setSortBy(field['value'] as String);
                                }
                              },
                            ),
                          ))
                      .toList(),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // 필터 초기화
              _productController.setCategoryFilter('all');
              _productController.setStockFilter('all');
              _productController.setOrganicFilter(false);
              _productController.setSortBy('name');
              _productController.sortAscending.value = true;
              _productController.loadProducts();
              Get.back();
            },
            child: const Text('초기화'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('적용'),
          ),
        ],
      ),
    );
  }

  void _showStockUpdateDialog(ProductModel product) {
    final TextEditingController stockController = TextEditingController(
      text: product.stockQuantity.toString(),
    );

    Get.dialog(
      AlertDialog(
        title: const Text('재고 수정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              product.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: stockController,
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (int.tryParse(stockController.text) != null) {
                await _productController.updateStock(
                  product.id,
                  int.parse(stockController.text),
                );
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  void _showToggleStatusConfirmation(ProductModel product) {
    final bool isDeactivating = product.isActive;

    Get.dialog(
      AlertDialog(
        title: Text(isDeactivating ? '상품 비활성화' : '상품 활성화'),
        content: Text(isDeactivating
            ? '${product.name} 상품을 비활성화하시겠습니까? 비활성화된 상품은 고객에게 표시되지 않습니다.'
            : '${product.name} 상품을 활성화하시겠습니까? 활성화된 상품은 고객에게 표시됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _productController.toggleProductStatus(
                product.id,
                !product.isActive,
              );
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDeactivating ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(isDeactivating ? '비활성화' : '활성화'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(ProductModel product) {
    Get.dialog(
      AlertDialog(
        title: const Text('상품 삭제'),
        content: Text('${product.name} 상품을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _productController.deleteProduct(product.id);
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}

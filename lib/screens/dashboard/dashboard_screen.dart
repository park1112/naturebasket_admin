// lib/screens/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/dashboard_controller.dart';
import 'widgets/sales_chart.dart';
import 'widgets/top_products_list.dart';
import 'widgets/orders_summary.dart';
import 'widgets/customers_summary.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final DashboardController controller = Get.find<DashboardController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('대시보드'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadDashboardData(),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'export_sales') {
                controller.exportSalesDataToCsv();
              } else if (value == 'export_products') {
                controller.exportProductSalesDataToCsv();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'export_sales',
                child: Text('매출 데이터 내보내기 (CSV)'),
              ),
              const PopupMenuItem<String>(
                value: 'export_products',
                child: Text('상품 판매 데이터 내보내기 (CSV)'),
              ),
            ],
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            bool isSmallScreen = constraints.maxWidth < 600;
            bool isMediumScreen = constraints.maxWidth < 1200;

            if (isSmallScreen) {
              // 모바일 레이아웃
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 기간 선택 탭
                    _buildPeriodSelector(controller),
                    const SizedBox(height: 16),

                    // 요약 정보
                    _buildSummaryCards(controller),
                    const SizedBox(height: 24),

                    // 매출 차트
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '매출 추이',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 300,
                              child: SalesChart(
                                salesData:
                                    controller.salesStats.value?.data ?? [],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 인기 상품
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '인기 상품',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (controller.productStats.value != null)
                              TopProductsList(
                                products: controller
                                    .productStats.value!.topSellingProducts,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 주문 요약
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '주문 현황',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // lib/screens/dashboard/dashboard_screen.dart (계속)
                            if (controller.summary.value != null)
                              OrdersSummary(
                                orderStatusCounts:
                                    controller.summary.value!.orderStatusCounts,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 고객 요약
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '고객 현황',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (controller.customerStats.value != null)
                              CustomersSummary(
                                stats: controller.customerStats.value!,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            } else if (isMediumScreen) {
              // 태블릿 레이아웃
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 기간 선택 탭
                    _buildPeriodSelector(controller),
                    const SizedBox(height: 24),

                    // 요약 정보
                    _buildSummaryCards(controller),
                    const SizedBox(height: 32),

                    // 매출 차트와 인기 상품 (2열)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 매출 차트
                        Expanded(
                          flex: 3,
                          child: Card(
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '매출 추이',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: 300,
                                    child: SalesChart(
                                      salesData:
                                          controller.salesStats.value?.data ??
                                              [],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),

                        // 인기 상품
                        Expanded(
                          flex: 2,
                          child: Card(
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '인기 상품',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  if (controller.productStats.value != null)
                                    TopProductsList(
                                      products: controller.productStats.value!
                                          .topSellingProducts,
                                      maxItems: 5,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 주문 현황과 고객 현황 (2열)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 주문 현황
                        Expanded(
                          child: Card(
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '주문 현황',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  if (controller.summary.value != null)
                                    OrdersSummary(
                                      orderStatusCounts: controller
                                          .summary.value!.orderStatusCounts,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),

                        // 고객 현황
                        Expanded(
                          child: Card(
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '고객 현황',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  if (controller.customerStats.value != null)
                                    CustomersSummary(
                                      stats: controller.customerStats.value!,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            } else {
              // 데스크톱 레이아웃
              return SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 기간 선택 탭
                    _buildPeriodSelector(controller),
                    const SizedBox(height: 32),

                    // 요약 정보
                    _buildSummaryCards(controller),
                    const SizedBox(height: 40),

                    // 매출 차트와 인기 상품 (2열)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 매출 차트
                        Expanded(
                          flex: 7,
                          child: Card(
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '매출 추이',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    height: 400,
                                    child: SalesChart(
                                      salesData:
                                          controller.salesStats.value?.data ??
                                              [],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 32),

                        // 인기 상품
                        Expanded(
                          flex: 3,
                          child: Card(
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '인기 상품',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  if (controller.productStats.value != null)
                                    TopProductsList(
                                      products: controller.productStats.value!
                                          .topSellingProducts,
                                      maxItems: 10,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // 주문 현황과 고객 현황 (2열)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 주문 현황
                        Expanded(
                          child: Card(
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '주문 현황',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  if (controller.summary.value != null)
                                    OrdersSummary(
                                      orderStatusCounts: controller
                                          .summary.value!.orderStatusCounts,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 32),

                        // 고객 현황
                        Expanded(
                          child: Card(
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '고객 현황',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  if (controller.customerStats.value != null)
                                    CustomersSummary(
                                      stats: controller.customerStats.value!,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }
          },
        );
      }),
    );
  }

  Widget _buildPeriodSelector(DashboardController controller) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('기간: '),
            Obx(() => SegmentedButton<String>(
                  segments: const [
                    ButtonSegment<String>(
                      value: 'daily',
                      label: Text('일별'),
                    ),
                    ButtonSegment<String>(
                      value: 'weekly',
                      label: Text('주별'),
                    ),
                    ButtonSegment<String>(
                      value: 'monthly',
                      label: Text('월별'),
                    ),
                  ],
                  selected: {controller.selectedPeriod.value},
                  onSelectionChanged: (Set<String> selection) {
                    controller.changePeriod(selection.first);
                  },
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(DashboardController controller) {
    if (controller.summary.value == null) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isSmallScreen = constraints.maxWidth < 600;
        bool isMediumScreen = constraints.maxWidth < 1200;

        // 카드 크기 및 배치 조정
        int crossAxisCount = isSmallScreen ? 2 : (isMediumScreen ? 4 : 4);

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // 총 주문 건수
            _buildSummaryCard(
              title: '총 주문 건수',
              value: '${controller.summary.value!.totalOrders}건',
              icon: Icons.shopping_bag,
              iconColor: Colors.blue,
            ),

            // 총 매출액
            _buildSummaryCard(
              title: '총 매출액',
              value:
                  '${controller.summary.value!.totalSales.toStringAsFixed(0)}원',
              icon: Icons.attach_money,
              iconColor: Colors.green,
            ),

            // 신규 회원 수
            _buildSummaryCard(
              title: '신규 회원 수',
              value: '${controller.summary.value!.newUsers}명',
              icon: Icons.person_add,
              iconColor: Colors.purple,
            ),

            // 판매 상품 수
            _buildSummaryCard(
              title: '판매 상품 수',
              value: '${controller.summary.value!.productsSold}개',
              icon: Icons.inventory,
              iconColor: Colors.orange,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: iconColor,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

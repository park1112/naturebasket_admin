// lib/screens/dashboard/widgets/top_products_list.dart
import 'package:flutter/material.dart';

class TopProductsList extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  final int? maxItems;

  const TopProductsList({
    Key? key,
    required this.products,
    this.maxItems,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Center(
        child: Text('데이터가 없습니다.'),
      );
    }

    final displayProducts = maxItems != null && products.length > maxItems!
        ? products.sublist(0, maxItems)
        : products;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayProducts.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final product = displayProducts[index];

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            product['name'],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${product['quantity']}개 판매',
            style: const TextStyle(
              fontSize: 12,
            ),
          ),
          trailing: Text(
            '${product['totalAmount'].toStringAsFixed(0)}원',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

class ProductInputCard extends StatelessWidget {
  final String product;
  final VoidCallback onDelete;

  const ProductInputCard({
    super.key,
    required this.product,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              product,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDelete,
              child: Icon(
                Icons.close,
                size: 16,
                color: Colors.red[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

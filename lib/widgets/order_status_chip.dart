import 'package:flutter/material.dart';

import '../models/order_model.dart';
import '../utils/constants.dart';

class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({super.key, required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final Color color = _colorFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Color _colorFor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return AppConstants.accentColor;
      case OrderStatus.accepted:
        return const Color(0xFF1976D2);
      case OrderStatus.completed:
        return AppConstants.primaryColor;
      case OrderStatus.cancelled:
        return AppConstants.textLight;
      case OrderStatus.rejected:
        return AppConstants.errorColor;
    }
  }
}

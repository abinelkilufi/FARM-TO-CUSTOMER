import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/order_model.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../utils/quantity.dart';
import 'order_status_chip.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    required this.subtitle,
    this.onTap,
    this.actions,
  });

  final OrderModel order;
  final String subtitle;
  final VoidCallback? onTap;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: order.productImageUrl.isEmpty
                          ? _placeholder()
                          : CachedNetworkImage(
                              imageUrl: order.productImageUrl,
                              fit: BoxFit.cover,
                              placeholder: (BuildContext context, String url) =>
                                  _placeholder(),
                              errorWidget:
                                  (
                                    BuildContext context,
                                    String url,
                                    Object error,
                                  ) => _placeholder(),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                order.productName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppConstants.textDark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OrderStatusChip(status: order.status),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppConstants.textLight,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${formatQuantityValue(order.quantity)} ${order.unit} '
                          '• ${formatTsh(order.totalPrice)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatDate(order.createdAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppConstants.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (actions != null && actions!.isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(spacing: 8, runSpacing: 8, children: actions!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppConstants.primaryColor.withValues(alpha: 0.08),
      child: const Icon(Icons.eco_rounded, color: AppConstants.primaryColor),
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/order_service.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../utils/quantity.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/order_status_chip.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late final Stream<OrderModel?> _orderStream;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _orderStream = OrderService().watchOrder(widget.orderId);
  }

  Future<void> _changeStatus({
    required OrderModel order,
    required OrderStatus status,
    required String successMessage,
    String? confirmTitle,
    String? confirmMessage,
  }) async {
    if (confirmTitle != null) {
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text(confirmTitle),
            content: Text(
              confirmMessage ?? 'Are you sure you want to continue?',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Go back'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor:
                      status == OrderStatus.cancelled ||
                          status == OrderStatus.rejected
                      ? AppConstants.errorColor
                      : AppConstants.primaryColor,
                ),
                child: const Text('Yes, continue'),
              ),
            ],
          );
        },
      );

      if (confirmed != true || !mounted) {
        return;
      }
    }

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    setState(() {
      _isUpdating = true;
    });

    try {
      await OrderService().updateStatus(order.id, status);
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not update the order: $error'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: SafeArea(
        child: StreamBuilder<OrderModel?>(
          stream: _orderStream,
          builder: (BuildContext context, AsyncSnapshot<OrderModel?> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const LoadingView(message: 'Loading order...');
            }

            if (snapshot.hasError) {
              return const ErrorView(
                message: 'Could not load this order. Please try again later.',
              );
            }

            final OrderModel? order = snapshot.data;
            if (order == null) {
              return const EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Order not found',
                message: 'This order may have been removed.',
              );
            }

            final String? uid =
                authProvider.user?.uid ?? authProvider.userModel?.uid;
            final List<Widget> actions = _buildActions(order, uid);

            return ListView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              children: <Widget>[
                _StatusBanner(order: order),
                const SizedBox(height: 16),
                _ProductSummary(order: order),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Order information',
                  children: <Widget>[
                    _DetailRow(
                      icon: Icons.tag_outlined,
                      label: 'Order number',
                      value: order.id,
                    ),
                    _DetailRow(
                      icon: Icons.schedule_outlined,
                      label: 'Placed on',
                      value: formatDate(order.createdAt),
                    ),
                    _DetailRow(
                      icon: Icons.update_outlined,
                      label: 'Last updated',
                      value: formatDate(order.updatedAt),
                    ),
                    _DetailRow(
                      icon: Icons.payments_outlined,
                      label: 'Payment',
                      value: 'Cash on delivery',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Buyer',
                  children: <Widget>[
                    _DetailRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Name',
                      value: order.buyerName,
                    ),
                    _DetailRow(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: order.buyerPhone,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Farmer',
                  children: <Widget>[
                    _DetailRow(
                      icon: Icons.agriculture_outlined,
                      label: 'Name',
                      value: order.farmerName,
                    ),
                    _DetailRow(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: order.farmerPhone,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Delivery',
                  children: <Widget>[
                    _DetailRow(
                      icon: Icons.location_on_outlined,
                      label: 'Location',
                      value: order.deliveryLocation,
                    ),
                  ],
                ),
                if (actions.isNotEmpty) const SizedBox(height: 8),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: StreamBuilder<OrderModel?>(
        stream: _orderStream,
        builder: (BuildContext context, AsyncSnapshot<OrderModel?> snapshot) {
          final OrderModel? order = snapshot.data;
          if (order == null) {
            return const SizedBox.shrink();
          }

          final String? uid = context.select<AuthProvider, String?>(
            (AuthProvider provider) =>
                provider.user?.uid ?? provider.userModel?.uid,
          );
          final List<Widget> actions = _buildActions(order, uid);
          if (actions.isEmpty) {
            return const SizedBox.shrink();
          }

          return SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (_isUpdating) ...<Widget>[
                    const LinearProgressIndicator(
                      minHeight: 2,
                      color: AppConstants.primaryColor,
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: <Widget>[
                      for (int index = 0; index < actions.length; index++) ...[
                        if (index > 0) const SizedBox(width: 10),
                        Expanded(child: actions[index]),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildActions(OrderModel order, String? uid) {
    if (uid == null) {
      return const <Widget>[];
    }

    final bool isFarmer = uid == order.farmerId;
    final bool isBuyer = uid == order.buyerId;

    if (isFarmer && order.status == OrderStatus.pending) {
      return <Widget>[
        OutlinedButton(
          onPressed: _isUpdating
              ? null
              : () => _changeStatus(
                  order: order,
                  status: OrderStatus.rejected,
                  successMessage: 'Order rejected.',
                  confirmTitle: 'Reject this order?',
                  confirmMessage:
                      'The buyer will see that you cannot fulfill this order.',
                ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppConstants.errorColor,
            side: const BorderSide(color: AppConstants.errorColor),
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
            ),
          ),
          child: const Text('Reject'),
        ),
        ElevatedButton(
          onPressed: _isUpdating
              ? null
              : () => _changeStatus(
                  order: order,
                  status: OrderStatus.accepted,
                  successMessage: 'Order accepted.',
                ),
          child: const Text('Accept order'),
        ),
      ];
    }

    if (isFarmer && order.status == OrderStatus.accepted) {
      return <Widget>[
        ElevatedButton.icon(
          onPressed: _isUpdating
              ? null
              : () => _changeStatus(
                  order: order,
                  status: OrderStatus.completed,
                  successMessage: 'Order marked as completed.',
                  confirmTitle: 'Mark as completed?',
                  confirmMessage:
                      'Confirm that the buyer has received the produce.',
                ),
          icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
          label: const Text('Mark as completed'),
        ),
      ];
    }

    if (isBuyer && order.status == OrderStatus.pending) {
      return <Widget>[
        OutlinedButton(
          onPressed: _isUpdating
              ? null
              : () => _changeStatus(
                  order: order,
                  status: OrderStatus.cancelled,
                  successMessage: 'Order cancelled.',
                  confirmTitle: 'Cancel this order?',
                  confirmMessage:
                      'This action cannot be undone. The stock will be '
                      'returned to the farmer.',
                ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppConstants.errorColor,
            side: const BorderSide(color: AppConstants.errorColor),
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
            ),
          ),
          child: const Text('Cancel order'),
        ),
      ];
    }

    return const <Widget>[];
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final Color color = _statusColor(order.status);
    final IconData icon = _statusIcon(order.status);
    final String title = _statusTitle(order.status);
    final String message = _statusMessage(order.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
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
                        title,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    OrderStatusChip(status: order.status),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppConstants.textLight,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(OrderStatus status) {
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

  IconData _statusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.hourglass_top_rounded;
      case OrderStatus.accepted:
        return Icons.inventory_2_outlined;
      case OrderStatus.completed:
        return Icons.check_circle_outline_rounded;
      case OrderStatus.cancelled:
        return Icons.cancel_outlined;
      case OrderStatus.rejected:
        return Icons.block_outlined;
    }
  }

  String _statusTitle(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Waiting for confirmation';
      case OrderStatus.accepted:
        return 'Order accepted';
      case OrderStatus.completed:
        return 'Order completed';
      case OrderStatus.cancelled:
        return 'Order cancelled';
      case OrderStatus.rejected:
        return 'Order rejected';
    }
  }

  String _statusMessage(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'The farmer has been notified and will confirm your order soon.';
      case OrderStatus.accepted:
        return 'The farmer is preparing your produce for delivery.';
      case OrderStatus.completed:
        return 'This order has been delivered. Thank you for buying local.';
      case OrderStatus.cancelled:
        return 'This order is no longer active.';
      case OrderStatus.rejected:
        return 'The farmer could not fulfill this order.';
    }
  }
}

class _ProductSummary extends StatelessWidget {
  const _ProductSummary({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 76,
                height: 76,
                child: order.productImageUrl.isEmpty
                    ? _placeholder()
                    : CachedNetworkImage(
                        imageUrl: order.productImageUrl,
                        fit: BoxFit.cover,
                        placeholder: (BuildContext context, String url) =>
                            _placeholder(),
                        errorWidget:
                            (BuildContext context, String url, Object error) =>
                                _placeholder(),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    order.productName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppConstants.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatQuantityValue(order.quantity)} ${order.unit} × '
                    '${formatTsh(order.unitPrice)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppConstants.textLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatTsh(order.totalPrice),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppConstants.textDark,
              ),
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 17, color: AppConstants.textLight),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppConstants.textLight,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(
                fontSize: 13,
                color: AppConstants.textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

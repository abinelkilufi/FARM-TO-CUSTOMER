import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/order_service.dart';
import '../../utils/constants.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/order_card.dart';
import '../orders/order_detail_screen.dart';

class FarmerOrdersView extends StatefulWidget {
  const FarmerOrdersView({super.key});

  @override
  State<FarmerOrdersView> createState() => _FarmerOrdersViewState();
}

class _FarmerOrdersViewState extends State<FarmerOrdersView> {
  String? _uid;
  Stream<List<OrderModel>>? _ordersStream;
  final Set<String> _busyOrderIds = <String>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final AuthProvider authProvider = Provider.of<AuthProvider>(context);
    final String? uid = authProvider.user?.uid ?? authProvider.userModel?.uid;
    if (uid == _uid) {
      return;
    }
    _uid = uid;
    _ordersStream = uid == null
        ? null
        : OrderService().watchFarmerOrders(uid);
  }

  Future<void> _updateStatus(OrderModel order, OrderStatus status) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    setState(() {
      _busyOrderIds.add(order.id);
    });

    try {
      await OrderService().updateStatus(order.id, status);
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            status == OrderStatus.accepted
                ? 'Order accepted.'
                : status == OrderStatus.rejected
                ? 'Order rejected.'
                : 'Order marked as completed.',
          ),
        ),
      );
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
          _busyOrderIds.remove(order.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null || _ordersStream == null) {
      return const EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'Not signed in',
        message: 'Please sign in again to view your orders.',
      );
    }

    return StreamBuilder<List<OrderModel>>(
      stream: _ordersStream,
      builder:
          (BuildContext context, AsyncSnapshot<List<OrderModel>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const LoadingView(message: 'Loading your orders...');
            }

            if (snapshot.hasError) {
              return const ErrorView(
                message: 'Could not load your orders. Please try again later.',
              );
            }

            final List<OrderModel> orders = snapshot.data ?? <OrderModel>[];
            if (orders.isEmpty) {
              return const EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'No orders yet',
                message:
                    'New orders from buyers will appear here as soon as '
                    'they place them.',
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              itemCount: orders.length,
              itemBuilder: (BuildContext context, int index) {
                final OrderModel order = orders[index];
                final bool isBusy = _busyOrderIds.contains(order.id);

                return OrderCard(
                  order: order,
                  subtitle: 'Buyer: ${order.buyerName}',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => OrderDetailScreen(orderId: order.id),
                      ),
                    );
                  },
                  actions: _buildActions(order, isBusy),
                );
              },
            );
          },
    );
  }

  List<Widget> _buildActions(OrderModel order, bool isBusy) {
    if (order.status == OrderStatus.pending) {
      return <Widget>[
        TextButton(
          onPressed: isBusy
              ? null
              : () => _updateStatus(order, OrderStatus.rejected),
          child: const Text(
            'Reject',
            style: TextStyle(color: AppConstants.errorColor),
          ),
        ),
        FilledButton(
          onPressed: isBusy
              ? null
              : () => _updateStatus(order, OrderStatus.accepted),
          child: Text(isBusy ? 'Updating...' : 'Accept'),
        ),
      ];
    }

    if (order.status == OrderStatus.accepted) {
      return <Widget>[
        FilledButton.icon(
          onPressed: isBusy
              ? null
              : () => _updateStatus(order, OrderStatus.completed),
          icon: const Icon(Icons.check_rounded, size: 16),
          label: Text(isBusy ? 'Updating...' : 'Mark completed'),
        ),
      ];
    }

    return const <Widget>[];
  }
}

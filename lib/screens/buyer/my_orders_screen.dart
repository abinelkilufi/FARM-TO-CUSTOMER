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

class MyOrdersView extends StatefulWidget {
  const MyOrdersView({super.key, this.onBrowse});

  final VoidCallback? onBrowse;

  @override
  State<MyOrdersView> createState() => _MyOrdersViewState();
}

class _MyOrdersViewState extends State<MyOrdersView> {
  String? _uid;
  Stream<List<OrderModel>>? _ordersStream;

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
        : OrderService().watchBuyerOrders(uid);
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
              return EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'No orders yet',
                message:
                    'Your placed orders will appear here so you can track '
                    'their progress.',
                actionLabel: 'Browse products',
                onAction:
                    widget.onBrowse ??
                    () {
                      Navigator.of(context).maybePop();
                    },
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              itemCount: orders.length,
              itemBuilder: (BuildContext context, int index) {
                final OrderModel order = orders[index];
                return OrderCard(
                  order: order,
                  subtitle: 'Farmer: ${order.farmerName}',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => OrderDetailScreen(orderId: order.id),
                      ),
                    );
                  },
                );
              },
            );
          },
    );
  }
}

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: SafeArea(
        child: MyOrdersView(
          onBrowse: () {
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}

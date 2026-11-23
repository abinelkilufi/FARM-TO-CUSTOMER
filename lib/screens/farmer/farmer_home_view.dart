import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order_model.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/order_service.dart';
import '../../services/product_service.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/order_card.dart';
import '../orders/order_detail_screen.dart';

class FarmerHomeView extends StatefulWidget {
  const FarmerHomeView({
    super.key,
    required this.onAddProduct,
    required this.onViewProducts,
    required this.onViewOrders,
  });

  final VoidCallback onAddProduct;
  final VoidCallback onViewProducts;
  final VoidCallback onViewOrders;

  @override
  State<FarmerHomeView> createState() => _FarmerHomeViewState();
}

class _FarmerHomeViewState extends State<FarmerHomeView> {
  String? _uid;
  Stream<List<ProductModel>>? _productsStream;
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
    if (uid == null) {
      _productsStream = null;
      _ordersStream = null;
    } else {
      _productsStream = ProductService().watchFarmerProducts(uid);
      _ordersStream = OrderService().watchFarmerOrders(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider authProvider = context.watch<AuthProvider>();
    final String name =
        authProvider.userModel?.name ??
        authProvider.user?.displayName ??
        'Farmer';

    if (_uid == null || _productsStream == null || _ordersStream == null) {
      return const ErrorView(
        message:
            'Your farmer profile is not available. '
            'Please sign in again.',
      );
    }

    return StreamBuilder<List<ProductModel>>(
      stream: _productsStream,
      builder:
          (
            BuildContext context,
            AsyncSnapshot<List<ProductModel>> productSnapshot,
          ) {
            if (productSnapshot.connectionState == ConnectionState.waiting &&
                !productSnapshot.hasData) {
              return const LoadingView(message: 'Loading your farm...');
            }
            if (productSnapshot.hasError) {
              return const ErrorView(
                message: 'Could not load your farm overview.',
              );
            }

            return StreamBuilder<List<OrderModel>>(
              stream: _ordersStream,
              builder:
                  (
                    BuildContext context,
                    AsyncSnapshot<List<OrderModel>> orderSnapshot,
                  ) {
                    if (orderSnapshot.connectionState ==
                            ConnectionState.waiting &&
                        !orderSnapshot.hasData) {
                      return const LoadingView(
                        message: 'Loading your orders...',
                      );
                    }
                    if (orderSnapshot.hasError) {
                      return const ErrorView(
                        message: 'Could not load your orders.',
                      );
                    }

                    final List<ProductModel> products =
                        productSnapshot.data ?? <ProductModel>[];
                    final List<OrderModel> orders =
                        orderSnapshot.data ?? <OrderModel>[];

                    return _buildContent(context, name, products, orders);
                  },
            );
          },
    );
  }

  Widget _buildContent(
    BuildContext context,
    String name,
    List<ProductModel> products,
    List<OrderModel> orders,
  ) {
    final int pendingOrders = orders
        .where((OrderModel order) => order.status == OrderStatus.pending)
        .length;
    final int completedOrders = orders
        .where((OrderModel order) => order.status == OrderStatus.completed)
        .length;
    final double earnings = orders
        .where((OrderModel order) => order.status == OrderStatus.completed)
        .fold<double>(
          0,
          (double sum, OrderModel order) => sum + order.totalPrice,
        );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980),
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          children: <Widget>[
            _WelcomeHeader(name: name),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool wide = constraints.maxWidth >= 700;
                return GridView.count(
                  crossAxisCount: wide ? 4 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: wide ? 2.1 : 1.6,
                  children: <Widget>[
                    _StatCard(
                      icon: Icons.inventory_2_outlined,
                      label: 'Listings',
                      value: '${products.length}',
                      color: AppConstants.primaryColor,
                    ),
                    _StatCard(
                      icon: Icons.hourglass_top_rounded,
                      label: 'Pending orders',
                      value: '$pendingOrders',
                      color: AppConstants.accentColor,
                    ),
                    _StatCard(
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Completed',
                      value: '$completedOrders',
                      color: const Color(0xFF1976D2),
                    ),
                    _StatCard(
                      icon: Icons.savings_outlined,
                      label: 'Earned',
                      value: formatTsh(earnings),
                      color: AppConstants.primaryColor,
                      compact: true,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                Expanded(
                  child: _QuickAction(
                    icon: Icons.add_circle_outline_rounded,
                    title: 'Add product',
                    onTap: widget.onAddProduct,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.receipt_long_outlined,
                    title: 'View orders',
                    onTap: widget.onViewOrders,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Recent orders',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textDark,
                    ),
                  ),
                ),
                if (orders.isNotEmpty)
                  TextButton(
                    onPressed: widget.onViewOrders,
                    child: const Text('View all'),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            if (orders.isEmpty)
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.defaultRadius,
                  ),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.receipt_long_outlined,
                        color: AppConstants.textLight,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No orders yet. Share your produce so buyers can '
                          'find you.',
                          style: TextStyle(
                            color: AppConstants.textLight,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              for (final OrderModel order in orders.take(3))
                OrderCard(
                  order: order,
                  subtitle: 'Buyer: ${order.buyerName}',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => OrderDetailScreen(orderId: order.id),
                      ),
                    );
                  },
                ),
            if (products.isEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                'Tip: add your first product to start receiving orders.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppConstants.textLight),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[
            AppConstants.primaryColor,
            AppConstants.secondaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Welcome back,',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Here is what is happening on your farm today.',
                  style: TextStyle(color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.agriculture_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: color, size: 22),
            const Spacer(),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 15 : 22,
                fontWeight: FontWeight.bold,
                color: AppConstants.textDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: AppConstants.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: AppConstants.primaryColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
          border: Border.all(
            color: AppConstants.primaryColor.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, color: AppConstants.primaryColor, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

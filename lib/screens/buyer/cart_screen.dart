import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/cart_provider.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../utils/quantity.dart';
import '../../widgets/empty_state.dart';
import 'checkout_screen.dart';

class CartView extends StatelessWidget {
  const CartView({super.key, this.onStartShopping});

  final VoidCallback? onStartShopping;

  @override
  Widget build(BuildContext context) {
    final CartProvider cart = context.watch<CartProvider>();

    if (cart.isEmpty) {
      return EmptyState(
        icon: Icons.shopping_basket_outlined,
        title: 'Your cart is empty',
        message:
            'Browse fresh produce from local farmers and add items '
            'to your cart.',
        actionLabel: 'Start shopping',
        onAction:
            onStartShopping ??
            () {
              Navigator.of(context).maybePop();
            },
      );
    }

    return Column(
      children: <Widget>[
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            itemCount: cart.items.length,
            itemBuilder: (BuildContext context, int index) {
              return _CartItemCard(item: cart.items[index]);
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      '${cart.itemCount} item${cart.itemCount == 1 ? '' : 's'}',
                      style: const TextStyle(color: AppConstants.textLight),
                    ),
                    const Spacer(),
                    const Text(
                      'Subtotal',
                      style: TextStyle(color: AppConstants.textLight),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatTsh(cart.subtotal),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const CheckoutScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Proceed to checkout'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final CartProvider cart = context.read<CartProvider>();
    final double step = quantityStepForUnit(item.product.unit);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 76,
                height: 76,
                child: item.product.imageUrl.isEmpty
                    ? _placeholder()
                    : CachedNetworkImage(
                        imageUrl: item.product.imageUrl,
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          item.product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppConstants.textDark,
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Remove',
                        onPressed: () => cart.removeProduct(item.product.id),
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppConstants.textLight,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    item.product.farmerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppConstants.textLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: () =>
                                  cart.decrement(item.product.id, step: step),
                              icon: const Icon(Icons.remove, size: 16),
                            ),
                            Text(
                              '${formatQuantityValue(item.quantity)} '
                              '${item.product.unit}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: () =>
                                  cart.increment(item.product.id, step: step),
                              icon: const Icon(Icons.add, size: 16),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        formatTsh(item.subtotal),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppConstants.primaryColor,
                        ),
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

  Widget _placeholder() {
    return Container(
      color: AppConstants.primaryColor.withValues(alpha: 0.08),
      child: const Icon(Icons.eco_rounded, color: AppConstants.primaryColor),
    );
  }
}

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Cart')),
      body: SafeArea(
        child: CartView(
          onStartShopping: () {
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}

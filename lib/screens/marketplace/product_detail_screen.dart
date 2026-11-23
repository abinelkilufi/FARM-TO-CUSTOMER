import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../utils/quantity.dart';
import '../buyer/checkout_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.product});

  final ProductModel product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late final double _step;
  late final double _minQuantity;
  late double _quantity;

  @override
  void initState() {
    super.initState();
    _step = quantityStepForUnit(widget.product.unit);
    _minQuantity = math.min(_step, widget.product.quantity);
    _quantity = _minQuantity;
  }

  bool get _canBuy => widget.product.isAvailable && widget.product.quantity > 0;

  void _addToCart({bool buyNow = false}) {
    if (!_canBuy) {
      return;
    }

    context.read<CartProvider>().addProduct(
      widget.product,
      quantity: _quantity,
    );

    if (buyNow) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const CheckoutScreen()));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${formatQuantityValue(_quantity)} ${widget.product.unit} of '
          '${widget.product.name} added to cart.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ProductModel product = widget.product;
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Product Details')),
      body: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          AspectRatio(
            aspectRatio: 16 / 10,
            child: product.imageUrl.isEmpty
                ? _imagePlaceholder()
                : CachedNetworkImage(
                    imageUrl: product.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (BuildContext context, String url) =>
                        _imagePlaceholder(),
                    errorWidget:
                        (BuildContext context, String url, Object error) =>
                            _imagePlaceholder(),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        product.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppConstants.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _canBuy
                            ? AppConstants.primaryColor.withValues(alpha: 0.1)
                            : AppConstants.errorColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _canBuy ? 'In stock' : 'Out of stock',
                        style: TextStyle(
                          color: _canBuy
                              ? AppConstants.primaryColor
                              : AppConstants.errorColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${formatTsh(product.price)} / ${product.unit}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    const Icon(
                      Icons.inventory_2_outlined,
                      size: 18,
                      color: AppConstants.textLight,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${formatQuantityValue(product.quantity)} ${product.unit} available',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppConstants.textLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.defaultRadius,
                    ),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: <Widget>[
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppConstants.primaryColor.withValues(
                            alpha: 0.1,
                          ),
                          child: const Icon(
                            Icons.agriculture_outlined,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                product.farmerName,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppConstants.textDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                product.farmerLocation.isEmpty
                                    ? 'Local farmer'
                                    : product.farmerLocation,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppConstants.textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (product.farmerPhone.isNotEmpty)
                          IconButton(
                            tooltip: product.farmerPhone,
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Call ${product.farmerName}: '
                                    '${product.farmerPhone}',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.phone_outlined,
                              color: AppConstants.primaryColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Description',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  product.description.isEmpty
                      ? 'No description provided for this product.'
                      : product.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppConstants.textLight,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.defaultRadius,
                    ),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Quantity',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppConstants.textDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Select how much you need',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppConstants.textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _QuantityStepper(
                          value: _quantity,
                          unit: product.unit,
                          canDecrease: _canBuy && _quantity > _minQuantity,
                          canIncrease: _canBuy && _quantity < product.quantity,
                          onDecrease: () {
                            setState(() {
                              _quantity = (_quantity - _step)
                                  .clamp(_minQuantity, product.quantity)
                                  .toDouble();
                            });
                          },
                          onIncrease: () {
                            setState(() {
                              _quantity = (_quantity + _step)
                                  .clamp(_minQuantity, product.quantity)
                                  .toDouble();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _canBuy ? () => _addToCart() : null,
                  icon: const Icon(Icons.add_shopping_cart_outlined, size: 18),
                  label: const Text('Add to cart'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    foregroundColor: AppConstants.primaryColor,
                    side: const BorderSide(color: AppConstants.primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.defaultRadius,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _canBuy ? () => _addToCart(buyNow: true) : null,
                  child: const Text('Buy now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: AppConstants.primaryColor.withValues(alpha: 0.08),
      child: const Center(
        child: Icon(
          Icons.eco_rounded,
          size: 72,
          color: AppConstants.primaryColor,
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.value,
    required this.unit,
    required this.canDecrease,
    required this.canIncrease,
    required this.onDecrease,
    required this.onIncrease,
  });

  final double value;
  final String unit;
  final bool canDecrease;
  final bool canIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: canDecrease ? onDecrease : null,
            icon: const Icon(Icons.remove, size: 18),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48),
            child: Text(
              '${formatQuantityValue(value)} $unit',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppConstants.textDark,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: canIncrease ? onIncrease : null,
            icon: const Icon(Icons.add, size: 18),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/order_service.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../utils/quantity.dart';
import '../../widgets/empty_state.dart';
import 'my_orders_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _prefilled = false;
  bool _isPlacingOrder = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_prefilled) {
      return;
    }
    _prefilled = true;

    final AuthProvider authProvider = context.read<AuthProvider>();
    final user = authProvider.userModel;
    if (user != null) {
      _locationController.text = user.location;
      _phoneController.text = user.phone;
    } else {
      authProvider.refreshUserModel().then((_) {
        if (!mounted) {
          return;
        }
        final refreshed = authProvider.userModel;
        if (refreshed == null) {
          return;
        }
        setState(() {
          _locationController.text = refreshed.location;
          _phoneController.text = refreshed.phone;
        });
      });
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final CartProvider cart = context.read<CartProvider>();
    final AuthProvider authProvider = context.read<AuthProvider>();

    if (authProvider.userModel == null) {
      await authProvider.refreshUserModel();
      if (!mounted) {
        return;
      }
    }

    final user = authProvider.userModel;

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final NavigatorState navigator = Navigator.of(context);

    if (user == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Your profile is not available. Please sign in again.'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
      return;
    }

    if (cart.isEmpty) {
      return;
    }

    setState(() {
      _isPlacingOrder = true;
    });

    try {
      await OrderService().placeOrder(
        items: cart.items,
        buyer: user,
        buyerPhone: _phoneController.text,
        deliveryLocation: _locationController.text,
      );

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            icon: const Icon(
              Icons.check_circle_outline_rounded,
              color: AppConstants.primaryColor,
              size: 42,
            ),
            title: const Text('Order placed'),
            content: const Text(
              'Your order has been sent to the farmer. '
              'You can track its status under My Orders.',
            ),
            actions: <Widget>[
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('View my orders'),
              ),
            ],
          );
        },
      );

      if (!mounted) {
        return;
      }

      navigator.pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const MyOrdersScreen()),
      );
      cart.clear();
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not place order: $error'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPlacingOrder = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final CartProvider cart = context.watch<CartProvider>();

    if (cart.isEmpty && !_isPlacingOrder) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: EmptyState(
          icon: Icons.shopping_basket_outlined,
          title: 'Nothing to check out',
          message: 'Add some fresh produce to your cart first.',
          actionLabel: 'Go back',
          onAction: () => Navigator.of(context).maybePop(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      'Delivery details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _locationController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Delivery location',
                        hintText: 'e.g. Kariakoo, Dar es Salaam',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter the delivery location';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Contact phone',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Order summary',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
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
                        child: Column(
                          children: <Widget>[
                            for (final CartItem item in cart.items)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            item.product.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: AppConstants.textDark,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${formatQuantityValue(item.quantity)} '
                                            '${item.product.unit} × '
                                            '${formatTsh(item.product.price)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppConstants.textLight,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      formatTsh(item.subtotal),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppConstants.textDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const Divider(height: 24),
                            Row(
                              children: <Widget>[
                                const Text(
                                  'Total',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppConstants.textDark,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  formatTsh(cart.subtotal),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppConstants.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppConstants.accentColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(
                          AppConstants.defaultRadius,
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          const Icon(
                            Icons.payments_outlined,
                            color: AppConstants.accentColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Payment is made on delivery. '
                              'The farmer will contact you to confirm.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppConstants.textDark,
                                    height: 1.4,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: ElevatedButton(
            onPressed: _isPlacingOrder ? null : _placeOrder,
            child: _isPlacingOrder
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text('Place order • ${formatTsh(cart.subtotal)}'),
          ),
        ),
      ),
    );
  }
}

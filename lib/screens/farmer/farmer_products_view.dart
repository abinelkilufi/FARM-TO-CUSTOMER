import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/product_service.dart';
import '../../utils/constants.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/product_card.dart';
import 'product_form_screen.dart';

class FarmerProductsView extends StatefulWidget {
  const FarmerProductsView({super.key});

  @override
  State<FarmerProductsView> createState() => _FarmerProductsViewState();
}

class _FarmerProductsViewState extends State<FarmerProductsView> {
  String? _uid;
  Stream<List<ProductModel>>? _productsStream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final AuthProvider authProvider = Provider.of<AuthProvider>(context);
    final String? uid = authProvider.user?.uid ?? authProvider.userModel?.uid;
    if (uid == _uid) {
      return;
    }
    _uid = uid;
    _productsStream = uid == null
        ? null
        : ProductService().watchFarmerProducts(uid);
  }

  Future<void> _setAvailability(ProductModel product) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    if (!product.isAvailable && product.quantity <= 0) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Add stock to this product before making it available.',
          ),
        ),
      );
      return;
    }

    try {
      await ProductService().setAvailability(product.id, !product.isAvailable);
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            product.isAvailable
                ? 'Product marked as out of stock.'
                : 'Product is now available.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not update availability: $error'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }

  Future<void> _delete(ProductModel product) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete product?'),
          content: Text(
            '${product.name} will be permanently removed from your listings.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppConstants.errorColor,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    try {
      await ProductService().deleteProduct(product.id);
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(const SnackBar(content: Text('Product deleted.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not delete product: $error'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }

  void _edit(ProductModel product) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductFormScreen(product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null || _productsStream == null) {
      return const EmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'Not signed in',
        message: 'Please sign in again to manage your products.',
      );
    }

    return StreamBuilder<List<ProductModel>>(
      stream: _productsStream,
      builder:
          (BuildContext context, AsyncSnapshot<List<ProductModel>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const LoadingView(message: 'Loading your products...');
            }

            if (snapshot.hasError) {
              return const ErrorView(
                message:
                    'Could not load your products. Please try again later.',
              );
            }

            final List<ProductModel> products =
                snapshot.data ?? <ProductModel>[];
            if (products.isEmpty) {
              return EmptyState(
                icon: Icons.inventory_2_outlined,
                title: 'No products yet',
                message:
                    'Publish your first product so buyers can start '
                    'ordering from your farm.',
                actionLabel: 'Add product',
                onAction: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ProductFormScreen(),
                    ),
                  );
                },
              );
            }

            return LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final int columns = constraints.maxWidth >= 1100
                    ? 4
                    : constraints.maxWidth >= 780
                    ? 3
                    : 2;
                final double ratio = columns == 2
                    ? 0.62
                    : columns == 3
                    ? 0.72
                    : 0.8;

                return GridView.builder(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: ratio,
                  ),
                  itemCount: products.length,
                  itemBuilder: (BuildContext context, int index) {
                    final ProductModel product = products[index];
                    return ProductCard(
                      product: product,
                      onTap: () => _edit(product),
                      trailing: _ProductMenu(
                        product: product,
                        onEdit: () => _edit(product),
                        onToggleAvailability: () => _setAvailability(product),
                        onDelete: () => _delete(product),
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

class _ProductMenu extends StatelessWidget {
  const _ProductMenu({
    required this.product,
    required this.onEdit,
    required this.onToggleAvailability,
    required this.onDelete,
  });

  final ProductModel product;
  final VoidCallback onEdit;
  final VoidCallback onToggleAvailability;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: PopupMenuButton<String>(
        tooltip: 'Product actions',
        iconSize: 18,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 190),
        onSelected: (String value) {
          switch (value) {
            case 'edit':
              onEdit();
              break;
            case 'toggle':
              onToggleAvailability();
              break;
            case 'delete':
              onDelete();
              break;
          }
        },
        itemBuilder: (BuildContext context) {
          return <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'edit',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.edit_outlined, size: 20),
                title: Text('Edit product'),
              ),
            ),
            PopupMenuItem<String>(
              value: 'toggle',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  product.isAvailable
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                ),
                title: Text(
                  product.isAvailable ? 'Mark out of stock' : 'Mark available',
                ),
              ),
            ),
            const PopupMenuItem<String>(
              value: 'delete',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: AppConstants.errorColor,
                ),
                title: Text(
                  'Delete product',
                  style: TextStyle(color: AppConstants.errorColor),
                ),
              ),
            ),
          ];
        },
      ),
    );
  }
}

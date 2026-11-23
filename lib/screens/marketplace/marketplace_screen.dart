import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../services/product_service.dart';
import '../../utils/constants.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/product_card.dart';
import '../buyer/cart_screen.dart';
import '../buyer/my_orders_screen.dart';
import '../profile/profile_screen.dart';
import 'product_detail_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  int _index = 0;

  static const List<String> _titles = <String>[
    'Marketplace',
    'My Orders',
    'My Cart',
    'My Profile',
  ];

  void _selectTab(int index) {
    setState(() {
      _index = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final CartProvider cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: <Widget>[
          if (_index != 2 && _index != 3)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: IconButton(
                tooltip: 'Cart',
                onPressed: () => _selectTab(2),
                icon: Badge.count(
                  count: cart.itemCount,
                  isLabelVisible: cart.itemCount > 0,
                  child: const Icon(Icons.shopping_cart_outlined),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _index,
          children: <Widget>[
            const _MarketplaceShopTab(),
            MyOrdersView(onBrowse: () => _selectTab(0)),
            CartView(onStartShopping: () => _selectTab(0)),
            const ProfileView(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _selectTab,
        destinations: <NavigationDestination>[
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront_rounded),
            label: 'Shop',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Badge.count(
              count: cart.itemCount,
              isLabelVisible: cart.itemCount > 0,
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            selectedIcon: Badge.count(
              count: cart.itemCount,
              isLabelVisible: cart.itemCount > 0,
              child: const Icon(Icons.shopping_cart_rounded),
            ),
            label: 'Cart',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _MarketplaceShopTab extends StatefulWidget {
  const _MarketplaceShopTab();

  @override
  State<_MarketplaceShopTab> createState() => _MarketplaceShopTabState();
}

class _MarketplaceShopTabState extends State<_MarketplaceShopTab> {
  late Stream<List<ProductModel>> _productsStream;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _productsStream = ProductService().watchAvailableProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _productsStream = ProductService().watchAvailableProducts();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _query = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onChanged: (String value) {
              setState(() {
                _query = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search produce or farmer...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: _clearSearch,
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<ProductModel>>(
            stream: _productsStream,
            builder:
                (
                  BuildContext context,
                  AsyncSnapshot<List<ProductModel>> snapshot,
                ) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const LoadingView(
                      message: 'Loading fresh produce...',
                    );
                  }

                  if (snapshot.hasError) {
                    return ErrorView(
                      message:
                          'Could not load the marketplace. '
                          'Check that the Firebase emulator is running.',
                      onRetry: _reload,
                    );
                  }

                  final List<ProductModel> allProducts =
                      snapshot.data ?? <ProductModel>[];
                  if (allProducts.isEmpty) {
                    return const EmptyState(
                      icon: Icons.storefront_outlined,
                      title: 'No produce yet',
                      message:
                          'Fresh products from local farmers will appear '
                          'here as soon as they are listed.',
                    );
                  }

                  final String query = _query.trim().toLowerCase();
                  final List<ProductModel> products = query.isEmpty
                      ? allProducts
                      : allProducts
                            .where(
                              (ProductModel product) =>
                                  product.name.toLowerCase().contains(query) ||
                                  product.farmerName.toLowerCase().contains(
                                    query,
                                  ) ||
                                  product.description.toLowerCase().contains(
                                    query,
                                  ),
                            )
                            .toList(growable: false);

                  if (products.isEmpty) {
                    return EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No matches found',
                      message: 'We could not find produce matching "$_query".',
                      actionLabel: 'Clear search',
                      onAction: _clearSearch,
                    );
                  }

                  return LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
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
                            padding: const EdgeInsets.all(
                              AppConstants.defaultPadding,
                            ),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
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
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          ProductDetailScreen(product: product),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                  );
                },
          ),
        ),
      ],
    );
  }
}

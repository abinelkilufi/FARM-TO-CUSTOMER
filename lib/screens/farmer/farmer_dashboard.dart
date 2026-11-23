import 'package:flutter/material.dart';

import '../../screens/profile/profile_screen.dart';
import '../../utils/constants.dart';
import 'farmer_home_view.dart';
import 'farmer_orders_view.dart';
import 'farmer_products_view.dart';
import 'product_form_screen.dart';

class FarmerDashboard extends StatefulWidget {
  const FarmerDashboard({super.key});

  @override
  State<FarmerDashboard> createState() => _FarmerDashboardState();
}

class _FarmerDashboardState extends State<FarmerDashboard> {
  int _index = 0;

  static const List<String> _titles = <String>[
    'Farm Dashboard',
    'My Products',
    'Orders',
    'My Profile',
  ];

  void _selectTab(int index) {
    setState(() {
      _index = index;
    });
  }

  void _openAddProduct() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ProductFormScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      body: SafeArea(
        child: IndexedStack(
          index: _index,
          children: <Widget>[
            FarmerHomeView(
              onAddProduct: _openAddProduct,
              onViewProducts: () => _selectTab(1),
              onViewOrders: () => _selectTab(2),
            ),
            const FarmerProductsView(),
            const FarmerOrdersView(),
            const ProfileView(),
          ],
        ),
      ),
      floatingActionButton: _index == 1
          ? FloatingActionButton.extended(
              onPressed: _openAddProduct,
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add product'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _selectTab,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2_rounded),
            label: 'Products',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

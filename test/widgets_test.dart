import 'package:farm_to_table/models/order_model.dart';
import 'package:farm_to_table/models/product_model.dart';
import 'package:farm_to_table/widgets/empty_state.dart';
import 'package:farm_to_table/widgets/loading_view.dart';
import 'package:farm_to_table/widgets/order_status_chip.dart';
import 'package:farm_to_table/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProductModel buildProduct({
  double quantity = 5,
  bool isAvailable = true,
  String imageUrl = '',
}) {
  final DateTime now = DateTime(2026, 1, 1);
  return ProductModel(
    id: 'p1',
    farmerId: 'f1',
    farmerName: 'Farmer John',
    farmerPhone: '0700000000',
    farmerLocation: 'Arusha',
    name: 'Spinach',
    description: 'Fresh greens',
    price: 1000,
    quantity: quantity,
    unit: 'kg',
    imageUrl: imageUrl,
    isAvailable: isAvailable,
    createdAt: now,
    updatedAt: now,
  );
}

Widget wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  testWidgets('EmptyState shows its content and action', (
    WidgetTester tester,
  ) async {
    bool tapped = false;

    await tester.pumpWidget(
      wrap(
        EmptyState(
          icon: Icons.shopping_basket_outlined,
          title: 'Your cart is empty',
          message: 'Add some produce.',
          actionLabel: 'Start shopping',
          onAction: () => tapped = true,
        ),
      ),
    );

    expect(find.text('Your cart is empty'), findsOneWidget);
    expect(find.text('Add some produce.'), findsOneWidget);

    await tester.tap(find.text('Start shopping'));
    expect(tapped, isTrue);
  });

  testWidgets('OrderStatusChip renders human readable labels', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const Column(
          children: <Widget>[
            OrderStatusChip(status: OrderStatus.pending),
            OrderStatusChip(status: OrderStatus.completed),
            OrderStatusChip(status: OrderStatus.rejected),
          ],
        ),
      ),
    );

    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Rejected'), findsOneWidget);
  });

  testWidgets('ProductCard shows product details', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 220,
          height: 360,
          child: ProductCard(product: buildProduct()),
        ),
      ),
    );

    expect(find.text('Spinach'), findsOneWidget);
    expect(find.text('Farmer John'), findsOneWidget);
    expect(find.text('5 kg available'), findsOneWidget);
    expect(find.text('Out of stock'), findsNothing);
  });

  testWidgets('ProductCard shows out of stock state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 220,
          height: 360,
          child: ProductCard(
            product: buildProduct(quantity: 0, isAvailable: false),
          ),
        ),
      ),
    );

    expect(find.text('Out of stock'), findsOneWidget);
    expect(find.text('0 kg available'), findsOneWidget);
  });

  testWidgets('LoadingView and ErrorView render messages', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const Column(
          children: <Widget>[
            LoadingView(message: 'Loading produce...'),
            ErrorView(message: 'Something went wrong.'),
          ],
        ),
      ),
    );

    expect(find.text('Loading produce...'), findsOneWidget);
    expect(find.text('Something went wrong.'), findsOneWidget);
  });
}

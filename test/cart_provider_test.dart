import 'package:farm_to_table/models/product_model.dart';
import 'package:farm_to_table/providers/cart_provider.dart';
import 'package:flutter_test/flutter_test.dart';

ProductModel buildProduct({
  String id = 'p1',
  String name = 'Spinach',
  double price = 1000,
  double quantity = 10,
  String unit = 'kg',
  bool isAvailable = true,
}) {
  final DateTime now = DateTime(2026, 1, 1);
  return ProductModel(
    id: id,
    farmerId: 'f1',
    farmerName: 'Farmer John',
    farmerPhone: '0700000000',
    farmerLocation: 'Arusha',
    name: name,
    description: 'Fresh greens',
    price: price,
    quantity: quantity,
    unit: unit,
    imageUrl: '',
    isAvailable: isAvailable,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('CartProvider', () {
    test('starts empty', () {
      final CartProvider cart = CartProvider();
      expect(cart.isEmpty, isTrue);
      expect(cart.itemCount, 0);
      expect(cart.subtotal, 0);
    });

    test('adds a product and calculates totals', () {
      final CartProvider cart = CartProvider();
      cart.addProduct(buildProduct(), quantity: 2);

      expect(cart.isEmpty, isFalse);
      expect(cart.itemCount, 1);
      expect(cart.items.single.quantity, 2);
      expect(cart.subtotal, 2000);
    });

    test('merges duplicate products and clamps to available stock', () {
      final CartProvider cart = CartProvider();
      final ProductModel product = buildProduct(quantity: 3);

      cart.addProduct(product, quantity: 2);
      cart.addProduct(product, quantity: 2);

      expect(cart.itemCount, 1);
      expect(cart.items.single.quantity, 3);
    });

    test('increments and decrements using the unit step', () {
      final CartProvider cart = CartProvider();
      final ProductModel product = buildProduct(quantity: 2);

      cart.addProduct(product, quantity: 1);
      cart.increment(product.id, step: 0.5);
      expect(cart.items.single.quantity, 1.5);

      cart.decrement(product.id, step: 0.5);
      expect(cart.items.single.quantity, 1.0);
    });

    test('removes an item when its quantity reaches zero', () {
      final CartProvider cart = CartProvider();
      final ProductModel product = buildProduct(quantity: 5);

      cart.addProduct(product, quantity: 1);
      cart.decrement(product.id, step: 1);

      expect(cart.isEmpty, isTrue);
    });

    test('setQuantity removes items at zero and clamps at stock', () {
      final CartProvider cart = CartProvider();
      final ProductModel product = buildProduct(quantity: 5);

      cart.addProduct(product);
      cart.setQuantity(product.id, 99);
      expect(cart.items.single.quantity, 5);

      cart.setQuantity(product.id, 0);
      expect(cart.isEmpty, isTrue);
    });

    test('does not add out-of-stock products', () {
      final CartProvider cart = CartProvider();
      cart.addProduct(buildProduct(quantity: 0, isAvailable: false));

      expect(cart.isEmpty, isTrue);
    });

    test('removeProduct and clear empty the cart', () {
      final CartProvider cart = CartProvider();
      cart.addProduct(buildProduct(id: 'p1'));
      cart.addProduct(buildProduct(id: 'p2', name: 'Kale'));

      cart.removeProduct('p1');
      expect(cart.itemCount, 1);
      expect(cart.contains('p2'), isTrue);

      cart.clear();
      expect(cart.isEmpty, isTrue);
    });

    test('notifies listeners on changes', () {
      final CartProvider cart = CartProvider();
      int notifications = 0;
      cart.addListener(() => notifications++);

      cart.addProduct(buildProduct());
      cart.increment('p1');
      cart.clear();

      expect(notifications, 3);
    });
  });
}

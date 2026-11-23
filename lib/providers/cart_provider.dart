import 'package:flutter/foundation.dart';

import '../models/product_model.dart';

class CartItem {
  CartItem({required this.product, required this.quantity});

  final ProductModel product;
  double quantity;

  double get subtotal => product.price * quantity;

  CartItem copyWith({double? quantity}) {
    return CartItem(product: product, quantity: quantity ?? this.quantity);
  }
}

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = <CartItem>[];

  List<CartItem> get items => List<CartItem>.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;
  int get itemCount => _items.length;
  double get subtotal => _items.fold<double>(
    0,
    (double sum, CartItem item) => sum + item.subtotal,
  );
  double get totalQuantity => _items.fold<double>(
    0,
    (double sum, CartItem item) => sum + item.quantity,
  );

  CartItem? itemFor(String productId) {
    for (final CartItem item in _items) {
      if (item.product.id == productId) {
        return item;
      }
    }
    return null;
  }

  bool contains(String productId) => itemFor(productId) != null;

  void addProduct(ProductModel product, {double quantity = 1}) {
    if (product.quantity <= 0 || quantity <= 0) {
      return;
    }

    final CartItem? existing = itemFor(product.id);
    if (existing != null) {
      existing.quantity = (existing.quantity + quantity)
          .clamp(0, product.quantity)
          .toDouble();
      if (existing.quantity <= 0) {
        _items.remove(existing);
      }
    } else {
      _items.add(
        CartItem(
          product: product,
          quantity: quantity.clamp(0, product.quantity).toDouble(),
        ),
      );
    }

    notifyListeners();
  }

  void increment(String productId, {double step = 1}) {
    final CartItem? item = itemFor(productId);
    if (item == null) {
      return;
    }

    item.quantity = (item.quantity + step)
        .clamp(0, item.product.quantity)
        .toDouble();
    notifyListeners();
  }

  void decrement(String productId, {double step = 1}) {
    final CartItem? item = itemFor(productId);
    if (item == null) {
      return;
    }

    item.quantity = (item.quantity - step)
        .clamp(0, item.product.quantity)
        .toDouble();
    if (item.quantity <= 0) {
      _items.remove(item);
    }
    notifyListeners();
  }

  void setQuantity(String productId, double quantity) {
    final CartItem? item = itemFor(productId);
    if (item == null) {
      return;
    }

    if (quantity <= 0) {
      _items.remove(item);
    } else {
      item.quantity = quantity.clamp(0, item.product.quantity).toDouble();
    }
    notifyListeners();
  }

  void removeProduct(String productId) {
    final CartItem? item = itemFor(productId);
    if (item == null) {
      return;
    }
    _items.remove(item);
    notifyListeners();
  }

  void clear() {
    if (_items.isEmpty) {
      return;
    }
    _items.clear();
    notifyListeners();
  }
}

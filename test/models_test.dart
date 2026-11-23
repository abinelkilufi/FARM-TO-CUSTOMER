import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:farm_to_table/models/order_model.dart';
import 'package:farm_to_table/models/product_model.dart';
import 'package:farm_to_table/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('userRoleFromString', () {
    test('normalizes supported role values', () {
      expect(userRoleFromString('farmer'), UserRole.farmer);
      expect(userRoleFromString('Farmer'), UserRole.farmer);
      expect(userRoleFromString('TRADER'), UserRole.trader);
      expect(userRoleFromString('traders'), UserRole.trader);
      expect(userRoleFromString('consumer'), UserRole.consumer);
    });

    test('defaults to consumer for missing or unknown values', () {
      expect(userRoleFromString(null), UserRole.consumer);
      expect(userRoleFromString(''), UserRole.consumer);
      expect(userRoleFromString('unknown'), UserRole.consumer);
    });
  });

  test('UserModel parses and serializes a profile', () {
    final DateTime createdAt = DateTime(2026, 2, 3, 4, 5);
    final UserModel model = UserModel(
      uid: 'u1',
      name: 'Asha',
      email: 'asha@example.com',
      phone: '0712345678',
      role: UserRole.farmer,
      location: 'Mbeya',
      profileImageUrl: 'https://example.com/a.jpg',
      createdAt: createdAt,
    );

    final Map<String, dynamic> map = model.toMap();
    expect(map['role'], 'farmer');

    final UserModel parsed = UserModel.fromMap(map, docId: 'u1');
    expect(parsed.uid, 'u1');
    expect(parsed.name, 'Asha');
    expect(parsed.role, UserRole.farmer);
    expect(parsed.location, 'Mbeya');
    expect(parsed.createdAt, createdAt);
  });

  group('orderStatusFromString', () {
    test('parses every status', () {
      expect(orderStatusFromString('pending'), OrderStatus.pending);
      expect(orderStatusFromString('accepted'), OrderStatus.accepted);
      expect(orderStatusFromString('completed'), OrderStatus.completed);
      expect(orderStatusFromString('cancelled'), OrderStatus.cancelled);
      expect(orderStatusFromString('rejected'), OrderStatus.rejected);
    });

    test('defaults to pending', () {
      expect(orderStatusFromString(null), OrderStatus.pending);
      expect(orderStatusFromString('nonsense'), OrderStatus.pending);
    });
  });

  test('ProductModel round-trips through Firestore maps', () {
    final DateTime createdAt = DateTime(2026, 3, 4, 5, 6);
    final ProductModel model = ProductModel(
      id: 'p1',
      farmerId: 'f1',
      farmerName: 'John',
      farmerPhone: '0700000000',
      farmerLocation: 'Arusha',
      name: 'Spinach',
      description: 'Fresh',
      price: 1500,
      quantity: 8,
      unit: 'kg',
      imageUrl: '',
      isAvailable: true,
      createdAt: createdAt,
      updatedAt: createdAt,
    );

    final ProductModel parsed = ProductModel.fromMap(
      model.toMap(),
      docId: model.id,
    );

    expect(parsed.id, 'p1');
    expect(parsed.name, 'Spinach');
    expect(parsed.price, 1500);
    expect(parsed.quantity, 8);
    expect(parsed.isAvailable, isTrue);
    expect(parsed.createdAt, createdAt);
  });

  test('OrderModel round-trips through Firestore maps', () {
    final DateTime createdAt = DateTime(2026, 4, 5, 6, 7);
    final OrderModel model = OrderModel(
      id: 'o1',
      productId: 'p1',
      productName: 'Spinach',
      productImageUrl: '',
      buyerId: 'b1',
      buyerName: 'Asha',
      buyerPhone: '0712345678',
      farmerId: 'f1',
      farmerName: 'John',
      farmerPhone: '0700000000',
      quantity: 2,
      unit: 'kg',
      unitPrice: 1500,
      totalPrice: 3000,
      deliveryLocation: 'Kariakoo',
      status: OrderStatus.accepted,
      createdAt: createdAt,
      updatedAt: createdAt,
    );

    final Map<String, dynamic> map = model.toMap();
    expect(map['status'], 'accepted');
    expect(map['createdAt'], isA<Timestamp>());

    final OrderModel parsed = OrderModel.fromMap(map, docId: model.id);
    expect(parsed.status, OrderStatus.accepted);
    expect(parsed.totalPrice, 3000);
    expect(parsed.deliveryLocation, 'Kariakoo');
    expect(parsed.createdAt, createdAt);
  });
}

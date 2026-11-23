import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/order_model.dart';
import '../models/user_model.dart';
import '../providers/cart_provider.dart';
import '../utils/constants.dart';

class OrderService {
  OrderService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection(AppConstants.ordersCollection);

  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection(AppConstants.productsCollection);

  Stream<List<OrderModel>> watchBuyerOrders(String buyerId) {
    return _orders
        .where('buyerId', isEqualTo: buyerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_mapDocuments);
  }

  Stream<List<OrderModel>> watchFarmerOrders(String farmerId) {
    return _orders
        .where('farmerId', isEqualTo: farmerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_mapDocuments);
  }

  Stream<OrderModel?> watchOrder(String orderId) {
    return _orders.doc(orderId).snapshots().map((
      DocumentSnapshot<Map<String, dynamic>> document,
    ) {
      final Map<String, dynamic>? data = document.data();
      if (!document.exists || data == null) {
        return null;
      }
      return OrderModel.fromMap(data, docId: document.id);
    });
  }

  Future<OrderModel?> getOrder(String orderId) async {
    final DocumentSnapshot<Map<String, dynamic>> document = await _orders
        .doc(orderId)
        .get();
    final Map<String, dynamic>? data = document.data();
    if (!document.exists || data == null) {
      return null;
    }
    return OrderModel.fromMap(data, docId: document.id);
  }

  Future<void> placeOrder({
    required List<CartItem> items,
    required UserModel buyer,
    required String buyerPhone,
    required String deliveryLocation,
  }) async {
    if (items.isEmpty) {
      throw Exception('Your cart is empty.');
    }

    await _firestore.runTransaction<void>((Transaction transaction) async {
      final Map<String, DocumentSnapshot<Map<String, dynamic>>> snapshots =
          <String, DocumentSnapshot<Map<String, dynamic>>>{};

      for (final CartItem item in items) {
        final DocumentReference<Map<String, dynamic>> productReference =
            _products.doc(item.product.id);
        final DocumentSnapshot<Map<String, dynamic>> snapshot =
            await transaction.get(productReference);

        if (!snapshot.exists) {
          throw Exception('${item.product.name} is no longer available.');
        }

        final double available = ((snapshot.data()?['quantity'] as num?) ?? 0)
            .toDouble();
        if (available < item.quantity) {
          throw Exception(
            'Only $available ${item.product.unit} of ${item.product.name} '
            'are available.',
          );
        }

        snapshots[item.product.id] = snapshot;
      }

      for (final CartItem item in items) {
        final DocumentSnapshot<Map<String, dynamic>> snapshot =
            snapshots[item.product.id]!;
        final double available = ((snapshot.data()?['quantity'] as num?) ?? 0)
            .toDouble();
        final double remaining = available - item.quantity;
        final DateTime now = DateTime.now();
        final DocumentReference<Map<String, dynamic>> orderReference = _orders
            .doc();

        final OrderModel order = OrderModel(
          id: orderReference.id,
          productId: item.product.id,
          productName: item.product.name,
          productImageUrl: item.product.imageUrl,
          buyerId: buyer.uid,
          buyerName: buyer.name,
          buyerPhone: buyerPhone.trim(),
          farmerId: item.product.farmerId,
          farmerName: item.product.farmerName,
          farmerPhone: item.product.farmerPhone,
          quantity: item.quantity,
          unit: item.product.unit,
          unitPrice: item.product.price,
          totalPrice: item.product.price * item.quantity,
          deliveryLocation: deliveryLocation.trim(),
          status: OrderStatus.pending,
          createdAt: now,
          updatedAt: now,
        );

        transaction.set(orderReference, order.toMap());
        transaction.update(snapshot.reference, {
          'quantity': remaining,
          'isAvailable': remaining > 0,
          'updatedAt': Timestamp.fromDate(now),
        });
      }
    });
  }

  Future<void> updateStatus(String orderId, OrderStatus status) async {
    await _firestore.runTransaction<void>((Transaction transaction) async {
      final DocumentReference<Map<String, dynamic>> orderReference = _orders
          .doc(orderId);
      final DocumentSnapshot<Map<String, dynamic>> orderSnapshot =
          await transaction.get(orderReference);

      if (!orderSnapshot.exists) {
        throw Exception('This order no longer exists.');
      }

      final Map<String, dynamic> data =
          orderSnapshot.data() ?? <String, dynamic>{};
      final OrderStatus currentStatus = orderStatusFromString(
        data['status'] as String?,
      );
      final bool shouldRestoreStock =
          (status == OrderStatus.cancelled || status == OrderStatus.rejected) &&
          (currentStatus == OrderStatus.pending ||
              currentStatus == OrderStatus.accepted);

      transaction.update(orderReference, <String, dynamic>{
        'status': status.value,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (shouldRestoreStock) {
        final String productId = data['productId'] as String? ?? '';
        if (productId.isEmpty) {
          return;
        }

        final DocumentReference<Map<String, dynamic>> productReference =
            _products.doc(productId);
        final DocumentSnapshot<Map<String, dynamic>> productSnapshot =
            await transaction.get(productReference);
        if (!productSnapshot.exists) {
          return;
        }

        final double currentQuantity =
            ((productSnapshot.data()?['quantity'] as num?) ?? 0).toDouble();
        final double orderQuantity = ((data['quantity'] as num?) ?? 0)
            .toDouble();

        transaction.update(productReference, <String, dynamic>{
          'quantity': currentQuantity + orderQuantity,
          'isAvailable': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> cancelOrder(String orderId) {
    return updateStatus(orderId, OrderStatus.cancelled);
  }

  List<OrderModel> _mapDocuments(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs
        .map(
          (QueryDocumentSnapshot<Map<String, dynamic>> document) =>
              OrderModel.fromMap(document.data(), docId: document.id),
        )
        .toList(growable: false);
  }
}

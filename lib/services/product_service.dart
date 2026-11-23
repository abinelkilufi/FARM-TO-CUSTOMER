import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product_model.dart';
import '../utils/constants.dart';

class ProductService {
  ProductService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection(AppConstants.productsCollection);

  Stream<List<ProductModel>> watchAvailableProducts() {
    return _products
        .where('isAvailable', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_mapDocuments);
  }

  Stream<List<ProductModel>> watchFarmerProducts(String farmerId) {
    return _products
        .where('farmerId', isEqualTo: farmerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_mapDocuments);
  }

  Stream<ProductModel?> watchProduct(String productId) {
    return _products.doc(productId).snapshots().map((
      DocumentSnapshot<Map<String, dynamic>> document,
    ) {
      final Map<String, dynamic>? data = document.data();
      if (!document.exists || data == null) {
        return null;
      }
      return ProductModel.fromMap(data, docId: document.id);
    });
  }

  Future<ProductModel?> getProduct(String productId) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _products.doc(productId).get();
    final Map<String, dynamic>? data = snapshot.data();
    if (!snapshot.exists || data == null) {
      return null;
    }
    return ProductModel.fromMap(data, docId: snapshot.id);
  }

  Future<String> createProduct(ProductModel product) async {
    final DocumentReference<Map<String, dynamic>> reference = _products.doc();
    await reference.set(product.toMap());
    return reference.id;
  }

  Future<void> updateProduct(String productId, Map<String, dynamic> data) async {
    final Map<String, dynamic> payload = Map<String, dynamic>.from(data);
    payload['updatedAt'] = FieldValue.serverTimestamp();
    await _products.doc(productId).update(payload);
  }

  Future<void> toggleAvailability(String productId, bool currentStatus) async {
    await setAvailability(productId, !currentStatus);
  }

  Future<void> setAvailability(String productId, bool isAvailable) async {
    await updateProduct(productId, <String, dynamic>{'isAvailable': isAvailable});
  }

  Future<void> deleteProduct(String productId) async {
    await _products.doc(productId).delete();
  }

  List<ProductModel> _mapDocuments(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs
        .map(
          (QueryDocumentSnapshot<Map<String, dynamic>> document) =>
              ProductModel.fromMap(document.data(), docId: document.id),
        )
        .toList(growable: false);
  }
}

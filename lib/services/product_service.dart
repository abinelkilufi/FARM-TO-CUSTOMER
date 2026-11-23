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
    final DocumentSnapshot<Map<String, dynamic>> document = await _products
        .doc(productId)
        .get();
    final Map<String, dynamic>? data = document.data();
    if (!document.exists || data == null) {
      return null;
    }
    return ProductModel.fromMap(data, docId: document.id);
  }

  Future<String> createProduct(ProductModel product) async {
    final DocumentReference<Map<String, dynamic>> reference = _products.doc();
    await reference.set(product.toMap());
    return reference.id;
  }

  Future<void> updateProduct(ProductModel product) async {
    final Map<String, dynamic> data = product.toMap();
    data['updatedAt'] = Timestamp.now();
    await _products.doc(product.id).update(data);
  }

  Future<void> deleteProduct(String productId) async {
    await _products.doc(productId).delete();
  }

  Future<void> setAvailability(String productId, bool isAvailable) async {
    await _products.doc(productId).update({
      'isAvailable': isAvailable,
      'updatedAt': FieldValue.serverTimestamp(),
    });
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

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';
import '../utils/constants.dart';

class UserService {
  UserService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(AppConstants.usersCollection);

  Stream<UserModel?> watchUser(String uid) {
    return _users.doc(uid).snapshots().map((
      DocumentSnapshot<Map<String, dynamic>> document,
    ) {
      final Map<String, dynamic>? data = document.data();
      if (!document.exists || data == null) {
        return null;
      }
      return UserModel.fromMap(data, docId: document.id);
    });
  }

  Future<UserModel?> getUser(String uid) async {
    final DocumentSnapshot<Map<String, dynamic>> document = await _users
        .doc(uid)
        .get();
    final Map<String, dynamic>? data = document.data();
    if (!document.exists || data == null) {
      return null;
    }
    return UserModel.fromMap(data, docId: document.id);
  }

  Future<void> updateProfile({
    required String uid,
    required String name,
    required String phone,
    required String location,
    String? profileImageUrl,
  }) async {
    final Map<String, dynamic> data = <String, dynamic>{
      'name': name.trim(),
      'phone': phone.trim(),
      'location': location.trim(),
    };
    if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
      data['profileImageUrl'] = profileImageUrl;
    }

    await _users.doc(uid).update(data);
  }
}

import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  StorageService({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Future<String> uploadProductImage(XFile file, String farmerId) {
    return _upload(file: file, folder: 'products/$farmerId');
  }

  Future<String> uploadProfileImage(XFile file, String uid) {
    return _upload(file: file, folder: 'profiles/$uid');
  }

  Future<String> _upload({required XFile file, required String folder}) async {
    final Uint8List bytes = await file.readAsBytes();
    final String extension = file.name.contains('.')
        ? file.name.split('.').last.toLowerCase()
        : 'jpg';
    final String path =
        '$folder/${DateTime.now().millisecondsSinceEpoch}.$extension';
    final Reference reference = _storage.ref().child(path);

    final SettableMetadata metadata = SettableMetadata(
      contentType: file.mimeType ?? _contentTypeFor(extension),
    );

    final TaskSnapshot snapshot = await reference.putData(bytes, metadata);
    return snapshot.ref.getDownloadURL();
  }

  String _contentTypeFor(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }
}

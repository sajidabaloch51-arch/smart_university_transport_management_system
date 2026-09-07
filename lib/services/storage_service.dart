import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  FirebaseStorage? get _storage {
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseStorage.instance;
    } catch (e) {}
    return null;
  }

  Future<String> uploadImage(String path, File file) async {
    final storage = _storage;
    if (storage == null) return '';
    
    try {
      Reference ref = storage.ref().child(path);
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print(e);
      return '';
    }
  }
}

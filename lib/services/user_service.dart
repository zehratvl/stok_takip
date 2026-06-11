import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Future<String?> kullaniciRoluGetir() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    return doc.data()?['rol'];
  }

  static Future<void> kullaniciKaydet({
    required String uid,
    required String email,
    required String rol,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'email': email,
      'rol': rol,
      'tarih': FieldValue.serverTimestamp(),
    });
  }
}
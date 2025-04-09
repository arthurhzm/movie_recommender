import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _db;
  UserService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  Future<Map<String, dynamic>> getUserPreferences() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    try {
      return await _db.collection('user_preferences').doc(userId).get().then((
        doc,
      ) {
        if (doc.exists) {
          return doc.data()!;
        } else {
          return {};
        }
      });
    } catch (e) {
      print('Error getting user preferences: $e');
      return {};
    }
  }
}

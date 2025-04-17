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

  Future<List<Map<String, dynamic>>> getUserSwipes() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    try {
      return await _db
          .collection('user_swipes')
          .where('userId', isEqualTo: userId)
          .get()
          .then((snapshot) {
            return snapshot.docs.map((doc) => doc.data()).toList();
          });
    } catch (e) {
      print('Error getting user swipes: $e');
      return [];
    }
  }

  Future<void> deleteSwipe(String movieTitle) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    try {
      final swipes =
          await _db
              .collection('user_swipes')
              .where('userId', isEqualTo: userId)
              .where('movieTitle', isEqualTo: movieTitle)
              .get();
      for (var doc in swipes.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error deleting swipe: $e');
    }
  }
}

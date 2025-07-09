import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:movie_recommender/models/user_model.dart';

class UserService {
  final FirebaseFirestore _db;
  UserService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  Future createUser(UserModel user) async {
    try {
      await _db.collection('users').doc(user.uid).set({
        'name': user.name,
        'followingCount': 0,
        'followersCount': 0,
      });
    } catch (e) {
      print('Error creating user: $e');
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      await _db.collection('users').doc(user.uid).update({
        'name': user.name,
        'photoUrl': user.photoUrl,
      });
    } catch (e) {
      print('Error updating user: $e');
    }
  }

  Future<List<UserModel>> getUsersByName(String name) async {
    try {
      final snapshot =
          await _db
              .collection('users')
              .where('name', isGreaterThanOrEqualTo: name.toLowerCase())
              .where('name', isLessThan: '${name.toLowerCase()}\uf8ff')
              // .where('uid', isNotEqualTo: userId)
              .get();
      if (snapshot.docs.isNotEmpty) {
        print('Found ${snapshot.docs.length} users matching "$name"');
        return snapshot.docs.map((doc) {
          final data = doc.data();
          return UserModel(
            uid: doc.id,
            name: data['name'] ?? '',
            photoUrl: data['photoUrl'],
            followingCount: data['followingCount'] ?? 0,
            followersCount: data['followersCount'] ?? 0,
          );
        }).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Error getting user by name: $e');
      return [];
    }
  }

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

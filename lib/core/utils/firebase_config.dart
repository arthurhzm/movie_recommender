import 'package:firebase_core/firebase_core.dart';
import 'package:movie_recommender/firebase_options.dart';
  

class FirebaseConfig {
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}
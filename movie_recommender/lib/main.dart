import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:movie_recommender/pages/add_preferences_page.dart';
import 'package:movie_recommender/pages/home_page.dart';
import 'package:movie_recommender/pages/login_page.dart';
import 'package:movie_recommender/pages/preferences_page.dart';
import 'package:movie_recommender/pages/recommendations_page.dart';
import 'package:movie_recommender/pages/register_page.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());  
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
        '/preferences': (context) => const PreferencesPage(),
        '/preferences/add': (context) => const AddPreferencesPage(),
        '/recommendations': (context) => const RecommendationsPage(),
      },
    );
  }
}

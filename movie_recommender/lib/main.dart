import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:movie_recommender/pages/add_preferences_page.dart';
import 'package:movie_recommender/pages/forgot_password_page.dart';
import 'package:movie_recommender/pages/home_page.dart';
import 'package:movie_recommender/pages/login_page.dart';
import 'package:movie_recommender/pages/preferences_page.dart';
import 'package:movie_recommender/pages/settings_page.dart';
import 'package:movie_recommender/pages/recommendations_page.dart';
import 'package:movie_recommender/pages/register_page.dart';
import 'package:movie_recommender/pages/search_page.dart';
import 'package:movie_recommender/pages/user_movies_page.dart';
import 'package:movie_recommender/pages/chat_page.dart';
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
      darkTheme: ThemeData(brightness: Brightness.dark),
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/home': (context) => const HomePage(),
        '/settings': (context) => const SettingsPage(),
        '/preferences': (context) => const PreferencesPage(),
        '/preferences/add': (context) => const AddPreferencesPage(),
        '/recommendations': (context) => const RecommendationsPage(),
        '/user_movies': (context) => const UserMoviesPage(),
        '/chat': (context) => const ChatPage(),
        '/search': (context) => const SearchMoviePage(),
      },
    );
  }
}

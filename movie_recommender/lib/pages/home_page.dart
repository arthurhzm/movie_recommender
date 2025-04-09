import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:movie_recommender/services/user_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final db = FirebaseFirestore.instance;
  final userId = FirebaseAuth.instance.currentUser?.uid;
  final UserService _userService = UserService();
  late Future<Map<String, dynamic>> userPreferences;

  @override
  void initState() {
    super.initState();
    userPreferences = _userService.getUserPreferences();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: userPreferences,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushNamed(context, '/preferences/add');
            });
            return const Center(child: Text('Redirecting...'));
          } else {
            return Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/recommendations');
                },
                child: const Text('Me recomende filmes'),
              ),
            );
          }
        },
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:movie_recommender/services/user_service.dart';

class PreferencesPage extends StatefulWidget {
  const PreferencesPage({super.key});

  @override
  State<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {
  final UserService _userService = UserService();
  late Future<Map<String, dynamic>> userPreferences;
  final db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    userPreferences = _userService.getUserPreferences();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preferências')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: userPreferences,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final preferences = snapshot.data!;
            return ListView.builder(
              itemCount: preferences.entries.length,
              itemBuilder: (context, index) {
                final entry = preferences.entries.elementAt(index);
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    leading: const Icon(Icons.star, color: Colors.amber),
                    title: Text(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(entry.value.toString()),
                  ),
                );
              },
            );
          } else {
            return const Center(
              child: Text(
                'Nenhuma preferência adicionada ainda',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/preferences/add');
        },
        child: const Icon(Icons.add),
        tooltip: 'Adicionar Preferências',
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:movie_recommender/components/drawer_component.dart';
import 'package:movie_recommender/services/user_service.dart';

final Map<String, String> preferenceTitles = {
  'maxDuration': 'Duração Máxima (em minutos)',
  'acceptAdultContent': 'Aceita Conteúdo Adulto?',
  'favoriteDirectors': 'Diretores Favoritos',
  'minReleaseYear': 'Ano de Lançamento Mínimo',
  'favoriteGenres': 'Gêneros Favoritos',
  'favoriteActors': 'Atores Favoritos',
};

final Map<String, String> preferenceEmoji = {
  'maxDuration': '🕒',
  'acceptAdultContent': '🔞',
  'favoriteDirectors': '🎬',
  'minReleaseYear': '📅',
  'favoriteGenres': '🎭',
  'favoriteActors': '🌟',
};

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
      drawer: DrawerComponent(),
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
                final title = preferenceTitles[entry.key] ?? entry.key;
                final emoji = preferenceEmoji[entry.key] ?? entry.key;

                String formatedText;
                final value = entry.value;

                if (value is List) {
                  formatedText = value.join(', ');
                } else if (value is bool) {
                  formatedText = value ? 'Sim' : 'Não';
                } else {
                  formatedText = value.toString();
                }

                return Card(
                  margin: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  child: ListTile(
                    leading: Text(emoji, style: TextStyle(fontSize: 20),),
                    title: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(formatedText),
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

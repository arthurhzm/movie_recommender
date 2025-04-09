import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddPreferencesPage extends StatefulWidget {
  const AddPreferencesPage({super.key});

  @override
  State<AddPreferencesPage> createState() => _AddPreferencesPageState();
}

class _AddPreferencesPageState extends State<AddPreferencesPage> {
  final db = FirebaseFirestore.instance;
  final userId = FirebaseAuth.instance.currentUser?.uid;
  final _formKey = GlobalKey<FormState>();
  final List<String> _selectedGenres = [];
  final List<String> _selectedDirectors = [];
  final List<String> _selectedActors = [];
  int _selectedYear = 2000;
  int _selectedDuration = 180;
  bool _adultContent = false;

  //FIXME - Trocar por API depois
  final List<String> _allGenres = [
    'Ação',
    'Comédia',
    'Drama',
    'Ficção Científica',
    'Terror',
    'Romance',
    'Animação',
    'Documentário',
  ];

  //FIXME - Trocar por API depois
  final List<String> _popularDirectors = [
    'Christopher Nolan',
    'Quentin Tarantino',
    'Steven Spielberg',
    'Martin Scorsese',
    'Greta Gerwig',
  ];

  Future<void> _savePreferences() async {
    if (_selectedGenres.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione pelo menos um gênero')),
      );
      return;
    }

    final preferences = {
      'favoriteGenres': _selectedGenres,
      'favoriteDirectors': _selectedDirectors,
      'favoriteActors': _selectedActors,
      'minReleaseYear': _selectedYear,
      'maxDuration': _selectedDuration,
      'acceptAdultContent': _adultContent,
    };

    try {
      await db.collection('user_preferences').doc(userId).set(preferences);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao salvar preferências')),
        );
      }
      debugPrint('Error saving preferences: $e');
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferências salvas com sucesso!')),
      );
      Navigator.pushNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Suas Preferências')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Seus gêneros favoritos:',
                style: TextStyle(fontSize: 16),
              ),
              Wrap(
                spacing: 8,
                children:
                    _allGenres.map((genre) {
                      return FilterChip(
                        label: Text(genre),
                        selected: _selectedGenres.contains(genre),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedGenres.add(genre);
                            } else {
                              _selectedGenres.remove(genre);
                            }
                          });
                        },
                      );
                    }).toList(),
              ),

              const SizedBox(height: 24),
              const Text(
                'Diretores favoritos:',
                style: TextStyle(fontSize: 16),
              ),
              Wrap(
                spacing: 8,
                children:
                    _popularDirectors.map((director) {
                      return FilterChip(
                        label: Text(director),
                        selected: _selectedDirectors.contains(director),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedDirectors.add(director);
                            } else {
                              _selectedDirectors.remove(director);
                            }
                          });
                        },
                      );
                    }).toList(),
              ),

              const SizedBox(height: 24),
              const Text('Ano mínimo de lançamento:'),
              Slider(
                value: _selectedYear.toDouble(),
                min: 1950,
                max: DateTime.now().year.toDouble(),
                divisions: (DateTime.now().year - 1950),
                label: _selectedYear.toString(),
                onChanged: (value) {
                  setState(() {
                    _selectedYear = value.toInt();
                  });
                },
              ),

              const SizedBox(height: 24),
              const Text('Duração máxima (minutos):'),
              Slider(
                value: _selectedDuration.toDouble(),
                min: 60,
                max: 240,
                divisions: 6,
                label: _selectedDuration.toString(),
                onChanged: (value) {
                  setState(() {
                    _selectedDuration = value.toInt();
                  });
                },
              ),

              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Aceitar conteúdo adulto'),
                value: _adultContent,
                onChanged: (value) {
                  setState(() {
                    _adultContent = value;
                  });
                },
              ),

              const SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  onPressed: _savePreferences,
                  child: const Text('Salvar Preferências'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

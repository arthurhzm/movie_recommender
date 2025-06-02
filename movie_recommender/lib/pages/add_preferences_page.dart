import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:movie_recommender/components/drawer_component.dart';
import 'package:movie_recommender/providers/movie_api_provider.dart';
import 'package:movie_recommender/providers/tmdb_provider.dart';
import 'package:movie_recommender/services/user_service.dart';

class AddPreferencesPage extends StatefulWidget {
  const AddPreferencesPage({super.key});

  @override
  State<AddPreferencesPage> createState() => _AddPreferencesPageState();
}

class _AddPreferencesPageState extends State<AddPreferencesPage> {
  final UserService _userService = UserService();
  final TmdbProvider _tmdbProvider = TmdbProvider();
  final MovieApiProvider _movieApiProvider = MovieApiProvider();
  late Future<Map<String, dynamic>> userPreferences;
  final _formKey = GlobalKey<FormState>();
  final List<String> _selectedGenres = [];
  final List<String> _selectedDirectors = [];
  final List<String> _selectedActors = [];
  int _selectedYear = 2000;
  int _selectedDuration = 180;
  bool _adultContent = false;
  late Future<List<Map<String, dynamic>>> _popularDirectors;
  late Future<List<Map<String, dynamic>>> _allGenres;

  final userId = FirebaseAuth.instance.currentUser?.uid;
  final db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    userPreferences = _userService.getUserPreferences();

    userPreferences
        .then((preferences) {
          if (preferences.isNotEmpty) {
            setState(() {
              _selectedGenres.addAll(
                List<String>.from(preferences['favoriteGenres'] ?? []),
              );
              _selectedDirectors.addAll(
                List<String>.from(preferences['favoriteDirectors'] ?? []),
              );
              _selectedActors.addAll(
                List<String>.from(preferences['favoriteActors'] ?? []),
              );
              _selectedYear = preferences['minReleaseYear'] ?? _selectedYear;
              _selectedDuration =
                  preferences['maxDuration'] ?? _selectedDuration;
              _adultContent =
                  preferences['acceptAdultContent'] ?? _adultContent;
            });
          }
        })
        .catchError((error) {
          debugPrint('Error loading user preferences: $error');
        });

    _popularDirectors = _movieApiProvider.getDirectors();

    _popularDirectors
        .then((directors) {
          // debugPrint('Directors: $directors');
        })
        .catchError((error) {
          // debugPrint('Error loading directors: $error');
        });

    _allGenres = _tmdbProvider.getMovieGenders();

    _allGenres
        .then((genres) {
          // debugPrint('Genres: $genres');
        })
        .catchError((error) {
          // debugPrint('Error loading genres: $error');
        });
  }

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
      drawer: DrawerComponent(),
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
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _allGenres,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Erro ao carregar gêneros: ${snapshot.error}');
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('Nenhum gênero encontrado.');
                  }

                  final genres = snapshot.data!;
                  return Wrap(
                    spacing: 8,
                    children:
                        genres.map((genre) {
                          final genreName = genre['name'] ?? 'Desconhecido';
                          return FilterChip(
                            label: Text(genreName),
                            selected: _selectedGenres.contains(genreName),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedGenres.add(genreName);
                                } else {
                                  _selectedGenres.remove(genreName);
                                }
                              });
                            },
                          );
                        }).toList(),
                  );
                },
              ),

              const SizedBox(height: 24),
              const Text(
                'Diretores favoritos:',
                style: TextStyle(fontSize: 16),
              ),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _popularDirectors,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text(
                      'Erro ao carregar diretores: ${snapshot.error}',
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('Nenhum diretor encontrado.');
                  }

                  final directors = snapshot.data!;
                  return Wrap(
                    spacing: 8,
                    children:
                        directors.map((director) {
                          final directorName =
                              director['name'] ?? 'Desconhecido';
                          return FilterChip(
                            label: Text(directorName),
                            selected: _selectedDirectors.contains(directorName),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedDirectors.add(directorName);
                                } else {
                                  _selectedDirectors.remove(directorName);
                                }
                              });
                            },
                          );
                        }).toList(),
                  );
                },
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

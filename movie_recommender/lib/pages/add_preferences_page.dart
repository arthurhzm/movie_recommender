import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:movie_recommender/components/drawer_component.dart';
import 'package:movie_recommender/components/standard_appbar.dart';
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
  late Future<List<Map<String, dynamic>>> _popularActors;
  late Future<List<Map<String, dynamic>>> _allGenres;
  
  // Search controllers and results
  final TextEditingController _directorSearchController = TextEditingController();
  final TextEditingController _actorSearchController = TextEditingController();
  List<Map<String, dynamic>> _directorSearchResults = [];
  List<Map<String, dynamic>> _actorSearchResults = [];
  bool _isSearchingDirectors = false;
  bool _isSearchingActors = false;

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
    _popularActors = _movieApiProvider.getActors();
    _allGenres = _tmdbProvider.getMovieGenders();
  }

  @override
  void dispose() {
    _directorSearchController.dispose();
    _actorSearchController.dispose();
    super.dispose();
  }

  Future<void> _searchDirectors(String query) async {
    if (query.isEmpty) {
      setState(() {
        _directorSearchResults = [];
        _isSearchingDirectors = false;
      });
      return;
    }

    setState(() {
      _isSearchingDirectors = true;
    });

    try {
      final directors = await _movieApiProvider.getDirectors();
      setState(() {
        _directorSearchResults = directors
            .where((director) => 
                director['name'].toString().toLowerCase().contains(query.toLowerCase()))
            .toList();
        _isSearchingDirectors = false;
      });
    } catch (e) {
      debugPrint('Error searching directors: $e');
      setState(() {
        _isSearchingDirectors = false;
        _directorSearchResults = [];
      });
    }
  }

  Future<void> _searchActors(String query) async {
    if (query.isEmpty) {
      setState(() {
        _actorSearchResults = [];
        _isSearchingActors = false;
      });
      return;
    }

    setState(() {
      _isSearchingActors = true;
    });

    try {
      final actors = await _movieApiProvider.getActors();
      setState(() {
        _actorSearchResults = actors
            .where((actor) => 
                actor['name'].toString().toLowerCase().contains(query.toLowerCase()))
            .toList();
        _isSearchingActors = false;
      });
    } catch (e) {
      debugPrint('Error searching actors: $e');
      setState(() {
        _isSearchingActors = false;
        _actorSearchResults = [];
      });
    }
  }

  Future<void> _savePreferences() async {
    if (_selectedGenres.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione pelo menos um gênero'),
          backgroundColor: Colors.redAccent,
        ),
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
          const SnackBar(
            content: Text('Erro ao salvar preferências'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      debugPrint('Error saving preferences: $e');
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preferências salvas com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushNamed(context, '/home');
    }
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667eea).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF764ba2)),
        ),
      ),
    );
  }

  Widget _buildChipList(List<Map<String, dynamic>> items, List<String> selectedItems, 
      Function(String, bool) onSelected, String nameKey) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade900),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items.map((item) {
          final name = item[nameKey] ?? 'Desconhecido';
          final isSelected = selectedItems.contains(name);
          
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: FilterChip(
              label: Text(name),
              selected: isSelected,
              showCheckmark: false,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[800],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              selectedColor: const Color(0xFF667eea),
              backgroundColor: isSelected ? const Color(0xFF667eea) : Colors.white,
              shape: StadiumBorder(
                side: BorderSide(
                  color: isSelected ? const Color(0xFF667eea) : Colors.grey.shade300,
                ),
              ),
              elevation: isSelected ? 4 : 1,
              shadowColor: isSelected ? const Color(0xFF667eea).withOpacity(0.4) : Colors.transparent,
              onSelected: (selected) => onSelected(name, selected),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchInput(
    String hintText,
    TextEditingController controller,
    Function(String) onSearch,
    bool isSearching,
    List<Map<String, dynamic>> searchResults,
    List<String> selectedItems,
    Function(String) onItemSelected
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade900),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: InputBorder.none,
              prefixIcon: const Icon(Icons.search, color: Color(0xFF667eea)),
              suffixIcon: isSearching
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF764ba2)),
                      ),
                    )
                  : null,
            ),
            onChanged: onSearch,
          ),
        ),
        if (searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(12),
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                final item = searchResults[index];
                final name = item['name'] ?? 'Desconhecido';
                return ListTile(
                  title: Text(
                    name,
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    onItemSelected(name);
                    controller.clear();
                  },
                );
              },
            ),
          ),
        if (selectedItems.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade700),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selecionados:',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: selectedItems.map((name) {
                    return Chip(
                      label: Text(name),
                      backgroundColor: const Color(0xFF667eea),
                      labelStyle: const TextStyle(color: Colors.white),
                      deleteIconColor: Colors.white,
                      onDeleted: () {
                        setState(() {
                          selectedItems.remove(name);
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: DrawerComponent(),
      appBar: StandardAppBar(
        title: const Text('Suas Preferências', 
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Colors.black12],
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF667eea).withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.movie_filter, color: Colors.white, size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        'Personalize suas experiências',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Escolha suas preferências para que possamos recomendar os melhores filmes para você!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),

                // Genres section
                _buildSectionTitle('Gêneros favoritos', Icons.category),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _allGenres,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoadingIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Erro ao carregar gêneros: ${snapshot.error}');
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Text('Nenhum gênero encontrado.');
                    }

                    return _buildChipList(
                      snapshot.data!,
                      _selectedGenres,
                      (name, selected) {
                        setState(() {
                          if (selected) {
                            _selectedGenres.add(name);
                          } else {
                            _selectedGenres.remove(name);
                          }
                        });
                      },
                      'name',
                    );
                  },
                ),

                // Directors section
                _buildSectionTitle('Diretores favoritos', Icons.camera_alt),
                _buildSearchInput(
                  'Buscar diretores...',
                  _directorSearchController,
                  _searchDirectors,
                  _isSearchingDirectors,
                  _directorSearchResults,
                  _selectedDirectors,
                  (name) {
                    setState(() {
                      if (!_selectedDirectors.contains(name)) {
                        _selectedDirectors.add(name);
                      }
                      _directorSearchResults = [];
                    });
                  }
                ),

                // Actors section
                _buildSectionTitle('Atores favoritos', Icons.person),
                _buildSearchInput(
                  'Buscar atores...',
                  _actorSearchController,
                  _searchActors,
                  _isSearchingActors,
                  _actorSearchResults,
                  _selectedActors,
                  (name) {
                    setState(() {
                      if (!_selectedActors.contains(name)) {
                        _selectedActors.add(name);
                      }
                      _actorSearchResults = [];
                    });
                  }
                ),

                // Year section
                _buildSectionTitle('Ano mínimo de lançamento', Icons.date_range),
                Card(
                  elevation: 4,
                  shadowColor: Colors.grey.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'A partir de $_selectedYear',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: const Color(0xFF667eea),
                            inactiveTrackColor: Colors.grey.shade300,
                            thumbColor: const Color(0xFF764ba2),
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                          ),
                          child: Slider(
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
                        ),
                      ],
                    ),
                  ),
                ),

                // Duration section
                _buildSectionTitle('Duração máxima', Icons.timer),
                Card(
                  elevation: 4,
                  shadowColor: Colors.grey.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_selectedDuration minutos',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: const Color(0xFF667eea),
                            inactiveTrackColor: Colors.grey.shade300,
                            thumbColor: const Color(0xFF764ba2),
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                          ),
                          child: Slider(
                            value: _selectedDuration.toDouble(),
                            min: 60,
                            max: 240,
                            divisions: 6,
                            label: '$_selectedDuration min',
                            onChanged: (value) {
                              setState(() {
                                _selectedDuration = value.toInt();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Adult content section
                _buildSectionTitle('Conteúdo adulto', Icons.warning_amber),
                Card(
                  elevation: 4,
                  shadowColor: Colors.grey.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SwitchListTile(
                      title: const Text(
                        'Incluir conteúdo adulto',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'Mostrar filmes com conteúdo classificado para maiores de 18 anos'
                      ),
                      value: _adultContent,
                      activeColor: const Color(0xFF764ba2),
                      onChanged: (value) {
                        setState(() {
                          _adultContent = value;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 40),
                
                // Save button
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF667eea).withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _savePreferences,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Salvar Preferências',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

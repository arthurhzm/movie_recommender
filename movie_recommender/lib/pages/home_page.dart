import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:movie_recommender/components/drawer_component.dart';
import 'package:movie_recommender/components/movie_card_component.dart';
import 'package:movie_recommender/providers/gemini_provider.dart';
import 'package:movie_recommender/services/user_service.dart';
import 'package:movie_recommender/components/standard_button.dart';
import 'package:movie_recommender/components/standard_appbar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final db = FirebaseFirestore.instance;
  final userId = FirebaseAuth.instance.currentUser?.uid;
  final user = FirebaseAuth.instance.currentUser;
  final UserService _userService = UserService();
  final GeminiProvider _geminiProvider = GeminiProvider();
  late Future<Map<String, dynamic>> userPreferences;
  late Future<List<Map<String, dynamic>>> movies;
  late Future<List<Map<String, dynamic>>> specialMovies;
  late Future<List<List<Map<String, dynamic>>>> allMovies;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    userPreferences = _userService.getUserPreferences();
    _loadMovies();
  }

  void _loadMovies({bool forceRefresh = false}) {
    if (forceRefresh) {
      setState(() {
        _isRefreshing = true;
      });
    }

    movies = _geminiProvider.getMoviesRecommendations(
      10,
      forceRefresh: forceRefresh,
    );
    specialMovies = _geminiProvider.getMoviesRecommendations(
      10,
      special: true,
      forceRefresh: forceRefresh,
    );
    allMovies = Future.wait([movies, specialMovies]);

    if (forceRefresh) {
      allMovies.then((_) {
        if (mounted) {
          setState(() {
            _isRefreshing = false;
          });
        }
      });
    }

    debugPrint(allMovies.toString());
  }

  // Helper method to sanitize movie data
  Map<String, dynamic> sanitizeMovieData(Map<String, dynamic> movie) {
    // Ensure all string fields have non-null values
    return {
      'title': movie['title'] ?? 'Título Desconhecido',
      'overview': movie['overview'] ?? 'Descrição não disponível',
      'poster_path': movie['poster_path'] ?? '',
      'backdrop_path': movie['backdrop_path'] ?? '',
      'release_date': movie['release_date']?.toString() ?? '',
      'vote_average': movie['vote_average'] ?? 0.0,
      'id': movie['id']?.toString() ?? '',
      'year': movie['year']?.toString() ?? '',
      'genres': movie['genres'] ?? [],
      'why_recommend': movie['why_recommend'] ?? '',
      'streaming_services': movie['streaming_services'] ?? [],
      'poster_url': movie['poster_url'] ?? '',
      'backdrop_url': movie['backdrop_url'] ?? '',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/chat');
        },
        backgroundColor: Colors.green,
        child: Icon(Icons.chat),
      ),
      drawer: DrawerComponent(),
      appBar: StandardAppBar(
        actions: [
          IconButton(
            icon: Icon(_isRefreshing ? Icons.hourglass_empty : Icons.refresh),
            onPressed:
                _isRefreshing
                    ? null
                    : () {
                      _loadMovies(forceRefresh: true);
                    },
            tooltip: 'Atualizar recomendações',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
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
            // Main content loads immediately
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      "${horarioAtual()} ${user?.displayName ?? ""}, vamos escolher um filme para assistir?",
                    ),
                    const SizedBox(height: 15),
                    Text("Filmes recomendados com base em seus gostos"),
                    SizedBox(height: 8),
                    // First movie section with spinner while loading
                    SizedBox(
                      height: 180,
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: movies,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.movie_creation,
                                    size: 40,
                                    color: Colors.blue,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "Procurando os melhores filmes...",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  SizedBox(
                                    width: 120,
                                    child: LinearProgressIndicator(
                                      backgroundColor: Colors.grey[300],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.blue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else if (snapshot.hasError) {
                            return Center(
                              child: Text('Error: ${snapshot.error}'),
                            );
                          } else if (!snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return const Center(
                              child: Text('Nenhum filme encontrado'),
                            );
                          } else {
                            final moviesList = snapshot.data!;
                            return ScrollConfiguration(
                              behavior: ScrollConfiguration.of(
                                context,
                              ).copyWith(
                                scrollbars: true,
                                dragDevices: {
                                  PointerDeviceKind.touch,
                                  PointerDeviceKind.mouse,
                                  PointerDeviceKind.trackpad,
                                },
                              ),
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: moviesList.length,
                                physics: const BouncingScrollPhysics(),
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                itemBuilder: (context, index) {
                                  final movie = sanitizeMovieData(
                                    moviesList[index],
                                  );
                                  return MovieCardComponent(movie: movie);
                                },
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text("Filmes especiais recomendados para você"),
                    SizedBox(height: 8),
                    // Second movie section with spinner while loading
                    SizedBox(
                      height: 180,
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: specialMovies,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.movie_filter,
                                    size: 40,
                                    color: Colors.orange,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "Preparando filmes especiais...",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  SizedBox(
                                    width: 120,
                                    child: LinearProgressIndicator(
                                      backgroundColor: Colors.grey[300],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.orange,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else if (snapshot.hasError) {
                            return Center(
                              child: Text('Error: ${snapshot.error}'),
                            );
                          } else if (!snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return const Center(
                              child: Text('Nenhum filme encontrado'),
                            );
                          } else {
                            final specialMoviesList = snapshot.data!;
                            return ScrollConfiguration(
                              behavior: ScrollConfiguration.of(
                                context,
                              ).copyWith(
                                scrollbars: true,
                                dragDevices: {
                                  PointerDeviceKind.touch,
                                  PointerDeviceKind.mouse,
                                  PointerDeviceKind.trackpad,
                                },
                              ),
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: specialMoviesList.length,
                                physics: const BouncingScrollPhysics(),
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                itemBuilder: (context, index) {
                                  final movie = sanitizeMovieData(
                                    specialMoviesList[index],
                                  );
                                  return MovieCardComponent(movie: movie);
                                },
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    // Premium styled button
                    const SizedBox(height: 15),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF9900), Color(0xFFCF8700)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromARGB(
                              204,
                              255,
                              191,
                              0,
                            ).withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(25),
                          onTap:
                              () => Navigator.pushNamed(
                                context,
                                '/recommendations',
                              ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.movie,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Me recomende filmes',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}

String horarioAtual() {
  String mensagem = "";
  DateTime now = DateTime.now();

  if (now.hour >= 5) mensagem = "Bom dia";
  if (now.hour >= 12) mensagem = "Boa tarde";
  if (now.hour >= 19) mensagem = "Boa noite";

  return mensagem;
}

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

  @override
  void initState() {
    super.initState();
    userPreferences = _userService.getUserPreferences();
    movies = _geminiProvider.getMoviesRecommendations(10);
    specialMovies = _geminiProvider.getMoviesRecommendations(10, special: true);
    allMovies = Future.wait([movies, specialMovies]);
  }

  // Helper method to sanitize movie data
  Map<String, dynamic> sanitizeMovieData(Map<String, dynamic> movie) {
    // Ensure all string fields have non-null values
    return {
      'title': movie['title'] ?? 'Título Desconhecido',
      'overview': movie['overview'] ?? 'Descrição não disponível',
      'poster_path': movie['poster_path'] ?? '',
      'backdrop_path': movie['backdrop_path'] ?? '',
      'release_date': movie['release_date'] ?? '',
      'vote_average': movie['vote_average'] ?? 0.0,
      'id': movie['id']?.toString() ?? '',
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
            return Expanded(
              child: Center(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      "${horarioAtual()} ${user?.displayName ?? ""}, vamos escolher um filme para assistir?",
                    ),
                    const SizedBox(height: 15),
                    Text("Filmes recomendados com base em seus gostos"),
                    // First movie section with spinner while loading
                    SizedBox(
                      height: 180,
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: movies,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
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
                                  final movie = sanitizeMovieData(moviesList[index]);
                                  return MovieCardComponent(movie: movie);
                                },
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text("Filmes festivos recomendados para você"),
                    // Second movie section with spinner while loading
                    SizedBox(
                      height: 180,
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: specialMovies,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
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
                                  final movie = sanitizeMovieData(specialMoviesList[index]);
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
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.4),
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

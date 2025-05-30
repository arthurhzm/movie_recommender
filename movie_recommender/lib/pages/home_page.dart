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
            return Center(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Text(
                    "${horarioAtual()} ${user?.displayName ?? ""}, vamos escolher um filme para assistir?",
                  ),
                  const SizedBox(height: 15),
                  Text("Filmes com base em seus gostos"),
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
                            behavior: ScrollConfiguration.of(context).copyWith(
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
                                final movie = moviesList[index];
                                return MovieCardComponent(movie: movie);
                              },
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text("Filmes festivos para você"),
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
                            behavior: ScrollConfiguration.of(context).copyWith(
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
                                final movie = specialMoviesList[index];
                                return MovieCardComponent(movie: movie);
                              },
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  // Button is always visible immediately
                  const SizedBox(height: 15),
                  StandardButton(
                    onPressed:
                        () => Navigator.pushNamed(context, '/recommendations'),
                    child: const Text('Me recomende filmes'),
                  ),
                ],
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

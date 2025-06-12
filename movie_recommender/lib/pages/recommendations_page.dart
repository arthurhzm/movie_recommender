import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:movie_recommender/components/drawer_component.dart';
import 'package:movie_recommender/providers/gemini_provider.dart';
import 'package:movie_recommender/providers/tmdb_provider.dart';
import 'package:movie_recommender/services/api_limit_service.dart';
import 'package:movie_recommender/services/user_service.dart';

class RecommendationsPage extends StatefulWidget {
  const RecommendationsPage({super.key});

  @override
  State<RecommendationsPage> createState() => _RecommendationsPageState();
}

class _RecommendationsPageState extends State<RecommendationsPage> {
  final List<Map<String, dynamic>> _movies = [];
  final TmdbProvider _tmdbProvider = TmdbProvider();
  final GeminiProvider _geminiProvider = GeminiProvider();
  final userId = FirebaseAuth.instance.currentUser?.uid;
  int _currentIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;
  late final GenerativeModel _model;
  final UserService _userService = UserService();
  late Future<Map<String, dynamic>> userPreferences;
  late Future<List<Map<String, dynamic>>> userSwipes;
  final db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    userPreferences = _userService.getUserPreferences();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    if (userId == null) return;
    final canRequest = await ApiUsageService().canMakeRequest(userId!);

    if (canRequest['success'] == false) {
      String message = 'Não foi possível fazer a requisição.';

      if (canRequest['reason'] == 'DAILY_COUNT') {
        message =
            'Você atingiu o limite de recomendações para hoje. Volte amanhã para descobrir mais filmes!';
      } else if (canRequest['reason'] == 'MINUTE_COUNT') {
        message =
            'Você atingiu o limite de solicitações por minuto. Aguarde um momento e tente novamente.';
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              title: Text(
                canRequest['reason'] == 'DAILY_COUNT'
                    ? 'Limite diário atingido'
                    : 'Muitas solicitações',
              ),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Entendi'),
                ),
              ],
            ),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final movies = await _geminiProvider.getMoviesRecommendations(3);
      setState(() {
        _movies.clear();
        _movies.addAll(movies);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _handleSwipe(String action) async {
    final currentMovie = _movies[_currentIndex];

    // Feedback
    await FirebaseFirestore.instance.collection('user_swipes').add({
      'userId': FirebaseAuth.instance.currentUser?.uid,
      'movieTitle': currentMovie['title'],
      'action': action,
      'genres': currentMovie['genres'],
      'detailedFeedback': "",
      'timestamp': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Avaliação recebida! Caso queira fornecer mais detalhes e melhorar as recomendações, acesse "Meus filmes" e clique no filme desejado',
        ),
      ),
    );

    setState(() {
      userSwipes = _userService.getUserSwipes();
    });

    if (_currentIndex < _movies.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      setState(() {
        _isLoading = true;
        _loadRecommendations();
      });
    }
  }

  Widget _buildMovieCard(Map<String, dynamic> movie) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: Text(movie['title']),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${movie['year']} • ${movie['genres'].join(', ')}'),
                    const SizedBox(height: 16),
                    const Text(
                      'Sinopse',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(movie['overview'] ?? 'Sinopse não disponível.'),
                    const SizedBox(height: 16),
                    const Text(
                      'Por que recomendamos:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(movie['why_recommend'] ?? ''),
                    const SizedBox(height: 8),
                    Text(
                      'Disponível em: ${movie['streaming_services']?.join(', ') ?? 'Nenhum serviço de streaming encontrado'}',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Fechar'),
                  ),
                ],
              ),
        );
      },
      onPanUpdate: (details) {
        if (details.delta.dx > 0) {
          _handleSwipe('like');
        } else if (details.delta.dx < 0) {
          _handleSwipe('dislike');
        }
      },
      child: Card(
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            fit: StackFit.expand,
            children: [
              movie['poster_url'] != null
                  ? Image.network(movie['poster_url'], fit: BoxFit.cover)
                  : const Center(child: Icon(Icons.movie, size: 50)),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie['title'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${movie['year']} • ${movie['genres'].join(', ')}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _sanitizeJson(String rawJson) {
    // Remove caracteres não-ASCII e linhas problemáticas
    return rawJson
        .replaceAll(RegExp(r'[^\x00-\x7F]'), '') // Remove caracteres não-ASCII
        .replaceAll(RegExp(r',\s*\}'), '}') // Remove vírgulas finais
        .replaceAll(RegExp(r',\s*\]'), ']'); // Remove vírgulas finais
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }

    if (_movies.isEmpty) {
      return const Center(child: Text('Nenhum filme disponível'));
    }

    return Scaffold(
      drawer: const DrawerComponent(),
      appBar: AppBar(
        title: const Text('Descubra Filmes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRecommendations,
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
            return const Center(child: Text('Redirecionando...'));
          } else {
            return Center(child: _buildMovieCard(_movies[_currentIndex]));
          }
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            FloatingActionButton(
              heroTag: 'dislike',
              onPressed: () => _handleSwipe('dislike'),
              backgroundColor: Colors.red,
              child: const Icon(Icons.thumb_down, size: 30),
            ),
            FloatingActionButton(
              heroTag: 'super-like',
              onPressed: () => _handleSwipe('super_like'),
              backgroundColor: Colors.blue,
              child: const Icon(Icons.star, size: 30),
            ),
            FloatingActionButton(
              heroTag: 'like',
              onPressed: () => _handleSwipe('like'),
              backgroundColor: Colors.green,
              child: const Icon(Icons.thumb_up, size: 30),
            ),
          ],
        ),
      ),
    );
  }
}

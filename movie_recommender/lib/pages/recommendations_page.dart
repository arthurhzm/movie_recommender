import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:movie_recommender/components/drawer_component.dart';
import 'package:movie_recommender/services/user_service.dart';

class RecommendationsPage extends StatefulWidget {
  const RecommendationsPage({super.key});

  @override
  State<RecommendationsPage> createState() => _RecommendationsPageState();
}

class _RecommendationsPageState extends State<RecommendationsPage> {
  final List<Map<String, dynamic>> _movies = [];
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
    if (dotenv.env['GEMINI_API_KEY'] == null) {
      throw Exception('GEMINI_API_KEY not found in .env file');
    }
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: dotenv.env['GEMINI_API_KEY']!,
    );
    userPreferences = _userService.getUserPreferences();
    userSwipes = _userService.getUserSwipes();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    try {
      final preferences = await userPreferences;
      await getMovieRecommendation(preferences);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<String> getMovieRecommendation(preferences) async {
    try {
      final prompt = await _buildPrompt(preferences);
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? 'Não foi possível gerar as recomendações';
      final jsonStartIndex = text.indexOf('[');
      final jsonEndIndex = text.lastIndexOf(']');
      if (jsonStartIndex != -1 && jsonEndIndex != -1) {
        setState(() {
          _movies.clear();
          _movies.addAll(
            List<Map<String, dynamic>>.from(
              json.decode(text.substring(jsonStartIndex, jsonEndIndex + 1)),
            ),
          );
          _isLoading = false;
        });
      }
      return 'Não foi possível extrair o JSON das recomendações';
    } catch (e) {
      throw Exception('Erro na geração: ${e.toString()}');
    }
  }

  Future<String> _buildPrompt(Map<String, dynamic> preferences) async {
    final swipes = await userSwipes;

    final favoriteGenres =
        preferences['favoriteGenres']?.join(', ') ?? 'Nenhum';
    final favoriteDirectors =
        preferences['favoriteDirectors']?.join(', ') ?? 'Nenhum';
    final favoriteActors =
        preferences['favoriteActors']?.join(', ') ?? 'Nenhum';
    final minReleaseYear = preferences['minReleaseYear'] ?? 'Não especificado';
    final maxDuration = preferences['maxDuration'] ?? 'Não especificado';
    final acceptAdultContent =
        preferences['acceptAdultContent'] == true ? 'Sim' : 'Não';

    return '''
      Você é um cinéfilo especialista em recomendar filmes personalizados. 
      
      Contexto do usuário:
      - Gêneros preferidos: $favoriteGenres 
      - Diretores favoritos: $favoriteDirectors
      - Atores preferidos: $favoriteActors
      - Período preferido: Filmes após $minReleaseYear
      - Duração máxima: $maxDuration minutos
      - Aceita conteúdo adulto: $acceptAdultContent

      Sua tarefa:
      1. Sugira 3 filmes que combinem com o perfil
      2. Para cada filme, explique por que foi escolhido
      3. Inclua 1 sugestão fora da zona de conforto
      5. Priorize filmes com boa avaliação (>70% no Rotten Tomatoes)

      Exemplo de estrutura:
      Recomende filmes no formato JSON com:
      - title
      - year
      - genres
      - overview
      - why_recommend

      Limite a 200 caracteres por "why_recommend"

      Baseado no histórico:
      - Filmes curtidos: ${swipes.where((swipe) => swipe['action'] == 'like').map((swipe) => swipe['movieTitle']).join(', ')}
      - Filmes rejeitados: ${swipes.where((swipe) => swipe['action'] == 'dislike').map((swipe) => swipe['movieTitle']).join(', ')}
      - Filmes super curtidos: ${swipes.where((swipe) => swipe['action'] == 'super_like').map((swipe) => swipe['movieTitle']).join(', ')}

      Feedback detalhado:
      - Curtidas: ${swipes.where((swipe) => swipe['action'] == 'like').map((swipe) => swipe['detailedFeedback']).join(', ')}
      - Rejeitadas: ${swipes.where((swipe) => swipe['action'] == 'dislike').map((swipe) => swipe['detailedFeedback']).join(', ')}
      - Super curtidas: ${swipes.where((swipe) => swipe['action'] == 'super_like').map((swipe) => swipe['detailedFeedback']).join(', ')}

      Regras:
      1. Priorize gêneros curtidos
      2. Evite gêneros rejeitados
      3. Inclua 1 filme surpresa baseado em padrões similares
      4. Limite a 200 caracteres por "why_recommend"

      [Repita para os 3 filmes]
      (Retorne apenas o JSON)
      ''';
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
        child: Stack(
          children: [
            // Imagem do filme (substitua pelo seu widget de imagem)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                image:
                    movie['poster_url'] != null
                        ? DecorationImage(
                          image: NetworkImage(movie['poster_url']),
                          fit: BoxFit.cover,
                        )
                        : null,
                color: Colors.grey.shade200,
              ),
              child:
                  movie['poster_url'] == null
                      ? const Center(child: Icon(Icons.movie, size: 50))
                      : null,
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withAlpha(179)],
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
    );
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
      body: Center(child: _buildMovieCard(_movies[_currentIndex])),
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

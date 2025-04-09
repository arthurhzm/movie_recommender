import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:movie_recommender/services/user_service.dart';

class RecommendationsPage extends StatefulWidget {
  const RecommendationsPage({super.key});

  @override
  State<RecommendationsPage> createState() => _RecommendationsPageState();
}

class _RecommendationsPageState extends State<RecommendationsPage> {
  late final GenerativeModel _model;
  final UserService _userService = UserService();
  late Future<Map<String, dynamic>> userPreferences;
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
  }

  Future<String> getMovieRecommendation(preferences) async {
    try {
      final prompt = _buildPrompt(preferences);
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'Não foi possível gerar as recomendações';
    } catch (e) {
      throw Exception('Erro na geração: ${e.toString()}');
    }
  }

  String _buildPrompt(Map<String, dynamic> preferences) {
    final favoriteGenres = preferences['favoriteGenres']?.join(', ') ?? 'Nenhum';
    final favoriteDirectors = preferences['favoriteDirectors']?.join(', ') ?? 'Nenhum';
    final favoriteActors = preferences['favoriteActors']?.join(', ') ?? 'Nenhum';
    final minReleaseYear = preferences['minReleaseYear'] ?? 'Não especificado';
    final maxDuration = preferences['maxDuration'] ?? 'Não especificado';
    final acceptAdultContent = preferences['acceptAdultContent'] == true ? 'Sim' : 'Não';

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
      4. Formate como Markdown
      5. Priorize filmes com boa avaliação (>70% no Rotten Tomatoes)

      Exemplo de estrutura:
      ### 1. Nome do Filme (Ano)
      **Gênero**: Ação, Ficção Científica  
      **Por que recomendamos**: Explicação detalhada...
      **Fora da zona de conforto**: Sim/Não

      [Repita para os 3 filmes]
      ''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommendations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: Scaffold(
        body: FutureBuilder<Map<String, dynamic>>(
          future: userPreferences,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Erro: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text('Nenhuma preferência encontrada.'),
              );
            } else {
              return FutureBuilder<String>(
                future: getMovieRecommendation(snapshot.data!),
                builder: (context, recommendationSnapshot) {
                  if (recommendationSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (recommendationSnapshot.hasError) {
                    return Center(
                      child: Text('Erro: ${recommendationSnapshot.error}'),
                    );
                  } else if (!recommendationSnapshot.hasData ||
                      recommendationSnapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('Nenhuma recomendação disponível.'),
                    );
                  } else {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Recomendações de Filmes',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              recommendationSnapshot.data!,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                },
              );
            }
          },
        ),
      ),
    );
  }
}

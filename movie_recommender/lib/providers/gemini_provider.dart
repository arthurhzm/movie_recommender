import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:movie_recommender/providers/tmdb_provider.dart';
import 'package:movie_recommender/services/user_service.dart';
import 'dart:convert';

class GeminiProvider {
  final _model = GenerativeModel(
    model: 'gemini-2.5-flash-preview-04-17',
    apiKey: dotenv.env['GEMINI_API_KEY']!,
  );
  final _userService = UserService();
  final _tmdbProvider = TmdbProvider();

  Future<String> _buildPrompt(
    Map<String, dynamic> preferences,
    List<Map<String, dynamic>> swipes,
    int length, {
    bool special = false,
  }) async {
    final DateTime now = DateTime.now();
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
    final specialMovies =
        special
            ? '6. Recomende APENAS filmes FESTIVOS relacionados a próxima data comemorativa ou feriado no Brasil após hoje ($now), (EX: Caso estejamos em dezembro, filmes de natal)'
            : '';

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
      1. Sugira $length filmes que combinem com o perfil
      2. Para cada filme, explique por que foi escolhido
      3. Inclua 1 sugestão fora da zona de conforto
      5. Priorize filmes com boa avaliação (>70% no Rotten Tomatoes)
      $specialMovies

      Exemplo de estrutura:
      Recomende filmes no formato JSON com:
      - title
      - year
      - genres
      - overview
      - why_recommend
      - streaming_services (lista de serviços de streaming onde está disponível no Brasil. Ex: ["Netflix", "Prime Video", "Star+"])

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
      5. Para "streaming_services":
       - Liste apenas serviços válidos e verificáveis
       - Use nomes oficiais (ex: "GloboPlay", não "Globo Play")
       - Se não houver informação, retorne array vazio
      6. Use apenas caracteres ASCII simples
      7. Não inclua comentários ou texto adicional
      8. Verifique cuidadosamente a formatação JSON, os valores do JSON devem ser em português do Brasil
      9. Nunca use caracteres especiais ou Unicode

      Exemplo de JSON válido:
      [
        {
          "title": "Interestelar",
          "year": 2014,
          "genres": ["Ficção Científica", "Aventura"],
          "overview": "Um grupo de exploradores...",
          "why_recommend": "Excelente representação...",
          "streaming_services": ["Netflix"]
        }
      ]
      
      (Retorne apenas o JSON válido, sem markdown ou formatação adicional)
      ''';
  }

  String _sanitizeJson(String rawJson) {
    // Remove caracteres não-ASCII e linhas problemáticas
    return rawJson
        .replaceAll(RegExp(r'[^\x00-\x7F]'), '') // Remove caracteres não-ASCII
        .replaceAll(RegExp(r',\s*\}'), '}') // Remove vírgulas finais
        .replaceAll(RegExp(r',\s*\]'), ']'); // Remove vírgulas finais
  }

  Future<List<Map<String, dynamic>>> getMoviesRecommendations(
    int length, {
    bool special = false,
  }) async {
    final Map<String, dynamic> preferences =
        await _userService.getUserPreferences();
    final List<Map<String, dynamic>> swipes =
        await _userService.getUserSwipes();

    final prompt = await _buildPrompt(
      preferences,
      swipes,
      length,
      special: special,
    );
    try {
      final response = await _model.generateContent([Content.text(prompt)]);

      final text = response.text;
      if (text == null || text.isEmpty) {
        debugPrint('Resposta do Gemini está vazia ou null');
        return [];
      }

      final sanitizedText = _sanitizeJson(text);
      final jsonStartIndex = sanitizedText.indexOf('[');
      final jsonEndIndex = sanitizedText.lastIndexOf(']');
      debugPrint(
        'JSON: ${sanitizedText.substring(jsonStartIndex, jsonEndIndex + 1)}',
      );
      if (jsonStartIndex != -1 && jsonEndIndex != -1) {
        final movies =
            List<Map<String, dynamic>>.from(
              json.decode(
                sanitizedText.substring(jsonStartIndex, jsonEndIndex + 1),
              ),
            ).map((movie) {
              return {
                'title': movie['title'] ?? 'Título desconhecido',
                'year': movie['year']?.toString() ?? 'Ano desconhecido',
                'genres': List<String>.from(movie['genres'] ?? []),
                'overview': movie['overview'] ?? 'Sinopse não disponível',
                'why_recommend':
                    movie['why_recommend'] ?? 'Recomendação não disponível',
                'streaming_services': List<String>.from(
                  movie['streaming_services'] ?? [],
                ),
              };
            }).toList();

        for (var movie in movies) {
          try {
            final details = await _tmdbProvider.searchMoviesByTitle(
              movie['title'],
            );

            if (details.isNotEmpty) {
              movie.addAll(details[0]);
            }
          } catch (e) {
            debugPrint('Erro ao buscar dados do TMDB: $e');
            movie['poster_url'] = null;
          }
        }

        return movies;
      }
      return [];
    } catch (e) {
      throw Exception('Erro na geração: ${e.toString()}');
    }
  }

  Future<String> sendIndividualMessage(
    List<Map<String, String>> messages,
  ) async {
    debugPrint(messages.toString());
    final user = FirebaseAuth.instance.currentUser;
    final userName = user!.displayName;
    final Map<String, dynamic> preferences =
        await _userService.getUserPreferences();
    final List<Map<String, dynamic>> swipes =
        await _userService.getUserSwipes();

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

    final prompt = '''
        [SISTEMA] - Estamos em um sistema de recomendação de filmes com base em gostos do usuário e avaliações de filmes já assistidos.
        Você está em um chat com o usuário $userName.

        Neste contexto, você é um cinéfilo especialista em recomendar filmes personalizados. Evite responder qualquer pergunta que não seja sobre filmes.
        Use um vocabulário natural.
      
        Contexto do usuário:
        - Gêneros preferidos: $favoriteGenres 
        - Diretores favoritos: $favoriteDirectors
        - Atores preferidos: $favoriteActors
        - Período preferido: Filmes após $minReleaseYear
        - Duração máxima: $maxDuration minutos
        - Aceita conteúdo adulto: $acceptAdultContent

         Baseado no histórico:
        - Filmes curtidos: ${swipes.where((swipe) => swipe['action'] == 'like').map((swipe) => swipe['movieTitle']).join(', ')}
        - Filmes rejeitados: ${swipes.where((swipe) => swipe['action'] == 'dislike').map((swipe) => swipe['movieTitle']).join(', ')}
        - Filmes super curtidos: ${swipes.where((swipe) => swipe['action'] == 'super_like').map((swipe) => swipe['movieTitle']).join(', ')}

        Feedback detalhado:
        - Curtidas: ${swipes.where((swipe) => swipe['action'] == 'like').map((swipe) => swipe['detailedFeedback']).join(', ')}
        - Rejeitadas: ${swipes.where((swipe) => swipe['action'] == 'dislike').map((swipe) => swipe['detailedFeedback']).join(', ')}
        - Super curtidas: ${swipes.where((swipe) => swipe['action'] == 'super_like').map((swipe) => swipe['detailedFeedback']).join(', ')}

        As mensagens trocadas até agora foram: $messages
        Se adapte ao vocabulário do usuário 
        Caso o usuário peça por filmes que estão fora de seus gostos, se ajuste para fazer as recomendações com base nisso e, se possível, correlacionar os gostos do usuário com a requisição
        [/SISTEMA]
    ''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text =
          response.text ??
          'Não foi possível responder a esta solicitação no momento...';
      return text;
    } catch (e) {
      throw Exception('Erro na geração: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> searchMovies(String query) async {
    final prompt = ''' 
        [SISTEMA] - 
        Estamos em um sistema de recomendação de filmes e, neste contexto, o usuário está fazendo uma pesquisa e você é um cinéfilo especialista em recomendar filmes.
        A pesquisa do usuário para encontrar filmes foi: $query
        Pesquise por filmes com o nome passado pelo usuário ou, caso tenha passado o contexto do filme, pesquise pelo contexto.

        Retorno esperado:
        Recomende até 10 filmes filmes no formato JSON com:
        - title
        - year
        - genres
        - overview
        - why_recommend
        - streaming_services (lista de serviços de streaming onde está disponível no Brasil. Ex: ["Netflix", "Prime Video", "Star+"])
        Fora as chaves JSON, que devem seguir estritamente o padrão imposto, o resto deve ser em português do Brasil
        Limite a 200 caracteres por "why_recommend"

        Fora as chaves JSON, que devem seguir estritamente o padrão imposto, o resto deve ser em português do Brasil
      
       [/SISTEMA]
    ''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);

      final text = response.text ?? 'Não foi possível gerar as recomendações';
      final sanitizedText = _sanitizeJson(text);
      final jsonStartIndex = sanitizedText.indexOf('[');
      final jsonEndIndex = sanitizedText.lastIndexOf(']');
      debugPrint(
        'JSON: ${sanitizedText.substring(jsonStartIndex, jsonEndIndex + 1)}',
      );
      if (jsonStartIndex != -1 && jsonEndIndex != -1) {
        final movies =
            List<Map<String, dynamic>>.from(
              json.decode(
                sanitizedText.substring(jsonStartIndex, jsonEndIndex + 1),
              ),
            ).map((movie) {
              return {
                'title': movie['title'] ?? 'Título desconhecido',
                'year': movie['year']?.toString() ?? 'Ano desconhecido',
                'genres': List<String>.from(movie['genres'] ?? []),
                'overview': movie['overview'] ?? 'Sinopse não disponível',
                'why_recommend':
                    movie['why_recommend'] ?? 'Recomendação não disponível',
                'streaming_services': List<String>.from(
                  movie['streaming_services'] ?? [],
                ),
              };
            }).toList();

        for (var movie in movies) {
          try {
            final details = await _tmdbProvider.searchMoviesByTitle(
              movie['title'],
            );

            if (details.isNotEmpty) {
              movie.addAll(details[0]);
            }
          } catch (e) {
            debugPrint('Erro ao buscar dados do TMDB: $e');
            movie['poster_url'] = null;
          }
        }

        debugPrint(movies.toString());

        return movies;
      }
      return [];
    } catch (e) {
      throw Exception('Erro na geração: ${e.toString()}');
    }
  }
}

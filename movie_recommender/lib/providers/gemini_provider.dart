import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:movie_recommender/providers/tmdb_provider.dart';
import 'package:movie_recommender/services/user_service.dart';
import 'dart:convert';

class GeminiProvider {
  final _model = GenerativeModel(
    model: 'gemini-1.5-flash',
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
    final specialMovies = special ? _getSpecialMoviesPrompt(now, length) : '';

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
    // Remove apenas caracteres problemáticos, mas preserva acentos portugueses
    return rawJson
        .replaceAll(
          RegExp(r'[\u0000-\u001F\u007F-\u009F]'),
          '',
        ) // Remove caracteres de controle
        .replaceAll(RegExp(r',\s*\}'), '}') // Remove vírgulas finais
        .replaceAll(RegExp(r',\s*\]'), ']') // Remove vírgulas finais
        .replaceAll(
          RegExp(r'[\u201C\u201D]'),
          '"',
        ) // Substitui aspas curvas por normais
        .replaceAll(
          RegExp(r'[\u2018\u2019]'),
          "'",
        ) // Substitui apostrofes curvos
        .replaceAll('…', '...'); // Substitui reticências Unicode
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

      if (jsonStartIndex != -1 && jsonEndIndex != -1) {
        print(sanitizedText.substring(jsonStartIndex, jsonEndIndex + 1));
        final movies =
            List<Map<String, dynamic>>.from(
              json.decode(
                sanitizedText.substring(jsonStartIndex, jsonEndIndex + 1),
              ),
            ).map((movie) {
              return {
                'title': movie['title']?.toString() ?? 'Título desconhecido',
                'year': movie['year']?.toString() ?? 'Ano desconhecido',
                'genres': List<String>.from(movie['genres'] ?? []),
                'overview':
                    movie['overview']?.toString() ?? 'Sinopse não disponível',
                'why_recommend':
                    movie['why_recommend']?.toString() ??
                    'Recomendação não disponível',
                'streaming_services': List<String>.from(
                  movie['streaming_services'] ?? [],
                ),
              };
            }).toList();

        for (var movie in movies) {
          try {
            final details = await _tmdbProvider.searchMoviesByTitle(
              movie['title']?.toString() ?? '',
            );

            if (details.isNotEmpty) {
              movie.addAll(details[0].cast<String, Object>());
            }
          } catch (e) {
            debugPrint('Erro ao buscar dados do TMDB: $e');
            movie['poster_url'] = '';
          }
        }

        return movies;
      }
      return [];
    } on GenerativeAIException catch (e) {
      if (e.message.contains('overloaded') || e.message.contains('503')) {
        debugPrint('Serviço temporariamente indisponível: ${e.message}');
        throw Exception(
          'O serviço está temporariamente sobrecarregado. Tente novamente em alguns instantes.',
        );
      }
      debugPrint('Erro da IA: ${e.message}');
      throw Exception('Erro no serviço de recomendações. Tente novamente.');
    } catch (e) {
      debugPrint('Erro geral na geração: ${e.toString()}');
      throw Exception(
        'Não foi possível gerar recomendações no momento. Tente novamente.',
      );
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
      // debugPrint(
      //   'JSON: ${sanitizedText.substring(jsonStartIndex, jsonEndIndex + 1)}',
      // );
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

String _getSpecialMoviesPrompt(DateTime now, int length) {
  final month = now.month;
  final day = now.day;

  // Define as datas comemorativas do Brasil
  String occasionContext = '';

  if (month >= 11 && day >= 1) {
    occasionContext = '''
    CONTEXTO ESPECIAL - DEZEMBRO/NATAL:
    Recomende APENAS filmes natalinos, de fim de ano ou familiares apropriados para a época.
    Exemplos: filmes de Natal, comédia familiar, romance natalino, aventuras familiares.
    ''';
  } else if (month == 10) {
    occasionContext = '''
    CONTEXTO ESPECIAL - HALLOWEEN:
    Recomende APENAS filmes de terror, suspense, thriller ou sobrenaturais apropriados para Halloween.
    Considere o nível de terror baseado nas preferências do usuário.
    ''';
  } else if ((month == 2 || month == 6) && day >= 1 && day <= 28) {
    occasionContext = '''
    CONTEXTO ESPECIAL - DIA DOS NAMORADOS:
    Para início de fevereiro: filmes festivos, musicais ou comédias brasileiras.
    Para meio de fevereiro: filmes românticos, dramas românticos ou comédias românticas.
    ''';
  } else if (month == 4 && day >= 15 && day <= 25) {
    occasionContext = '''
    CONTEXTO ESPECIAL - PÁSCOA:
    Recomende filmes familiares, aventuras para toda família, 
    animações ou filmes com temas de renovação e esperança.
    ''';
  } else if (month == 5 && day >= 1 && day <= 15) {
    occasionContext = '''
    CONTEXTO ESPECIAL - DIA DAS MÃES:
    Recomende filmes sobre maternidade, relações familiares,
    dramas emocionantes sobre mães ou comédias familiares.
    ''';
  } else if (month == 8 && day >= 1 && day <= 15) {
    occasionContext = '''
    CONTEXTO ESPECIAL - DIA DOS PAIS:
    Recomende filmes sobre paternidade, relações pai-filho,
    aventuras familiares ou dramas sobre figura paterna.
    ''';
  } else {
    occasionContext = '''
    CONTEXTO ESPECIAL - GERAL:
    Identifique a próxima data comemorativa importante no Brasil e recomende 
    filmes apropriados para essa ocasião. Considere feriados nacionais, 
    datas culturais ou sazonais relevantes.
    ''';
  }

  return '''
  $occasionContext
  
  IMPORTANTE: 
  - Todos os $length filmes devem ser relacionados à ocasião especial identificada
  - Mantenha as preferências do usuário quando possível, mas priorize a temática especial
  - Explique no "why_recommend" a conexão com a data comemorativa
  ''';
}

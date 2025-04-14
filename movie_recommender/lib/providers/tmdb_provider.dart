import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tmdb_api/tmdb_api.dart';

class TmdbProvider {
  final TMDB _tmdb = TMDB(
    ApiKeys(dotenv.env['TMDB_API_KEY']!, dotenv.env['TMDB_READ_ACCESS_TOKEN']!),
    defaultLanguage: 'pt-BR',
    logConfig: const ConfigLogger(showLogs: true, showErrorLogs: true),
  );

  Future<List<Map<String, dynamic>>> getDirectors() async {
    final popularMovies = await _tmdb.v3.movies.getPopular();
    final List<dynamic> movies = popularMovies['results'];
    final List<int> directorIds = [];
    for (var movie in movies) {
      final Map<String, dynamic> creditsMap =
          (await _tmdb.v3.movies.getCredits(
            movie['id'],
          )).cast<String, dynamic>();
      final List<dynamic> credits = creditsMap['crew'] ?? [];
      for (var credit in credits) {
        if (credit['job'] == 'Director') {
          directorIds.add(credit['id']);
        }
      }
    }

    // Remove duplicates
    final uniqueDirectorIds = directorIds.toSet().toList();
    final List<Map<String, dynamic>> directors = [];
    for (var id in uniqueDirectorIds) {
      final person = await _tmdb.v3.people.getDetails(id);
      directors.add({
        'id': person['id'],
        'name': person['name'],
        'profile_path': person['profile_path'],
      });
    }

    return directors;
  }

  Future<List<Map<String, dynamic>>> getMovieGenders() async {
    final Map<dynamic, dynamic> result = await _tmdb.v3.genres.getMovieList();
    final List<dynamic> genres = result['genres'] ?? [];
    return genres.map((genre) {
      return {'id': genre['id'], 'name': genre['name']};
    }).toList();
  }
}

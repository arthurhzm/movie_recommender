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

  Future<List<String>> _getGenreNames(List<dynamic> genreIds) async {
    final List<Map<String, dynamic>> genres = await getMovieGenders();
    final List<String> genreNames = [];
    for (var genreId in genreIds) {
      final genre = genres.firstWhere(
        (genre) => genre['id'] == genreId,
        orElse: () => {'name': 'Unknown'},
      );
      genreNames.add(genre['name']);
    }
    return genreNames;
  }

  Future<List<Map<String, dynamic>>> searchMoviesByTitle(
    String title, {
    int page = 1,
  }) async {
    final Map<dynamic, dynamic> result = await _tmdb.v3.search.queryMovies(
      title,
      page: page,
    );
    final List<dynamic> movies = result['results'] ?? [];

    List<Map<String, dynamic>> moviesList = [];
    for (var movie in movies) {
      final genreNames = await _getGenreNames(movie['genre_ids'] ?? []);
      moviesList.add({
        'id': movie['id'],
        'title': movie['title'],
        'year': movie['release_date']?.split('-')[0] ?? 'N/A',
        'overview': movie['overview'],
        'genres': genreNames,
        'poster_path': movie['poster_path'],
        'poster_url': 'https://image.tmdb.org/t/p/w500${movie['poster_path']}',
        'backdrop_url':
            'https://image.tmdb.org/t/p/w500${movie['backdrop_path']}',
        'backdrop_path': movie['backdrop_path'],
      });
    }
    return moviesList;
  }
}

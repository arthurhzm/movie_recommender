import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tmdb_api/tmdb_api.dart';

class TmdbProvider {
  final TMDB _tmdb = TMDB(
    ApiKeys(dotenv.env['TMDB_API_KEY']!, dotenv.env['TMDB_READ_ACCESS_TOKEN']!),
    defaultLanguage: 'pt-BR',
    logConfig: const ConfigLogger(showLogs: true, showErrorLogs: true),
  );

  
}

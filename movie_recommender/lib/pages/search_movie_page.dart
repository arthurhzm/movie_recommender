import 'package:flutter/material.dart';
import 'package:movie_recommender/components/drawer_component.dart';
import 'package:movie_recommender/components/standard_appbar.dart';
import 'package:movie_recommender/components/standard_button.dart';
import 'package:movie_recommender/providers/gemini_provider.dart';

class SearchMoviePage extends StatefulWidget {
  const SearchMoviePage({super.key});

  @override
  State<SearchMoviePage> createState() => _SearchMoviePageState();
}

class _SearchMoviePageState extends State<SearchMoviePage> {
  final GeminiProvider _geminiProvider = GeminiProvider();
  late Future<List<Map<String, dynamic>>> searchResults;
  final _searchMovieController = TextEditingController();
  bool _hasSearched = false;
  String _searchQuery = '';

  void searchMoveis(String arguments) {
    if (arguments.isNotEmpty) {
      setState(() {
        _searchQuery = arguments;
        searchResults = _geminiProvider.searchMovies(arguments);
        _hasSearched = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: DrawerComponent(),
      appBar: StandardAppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed:
                () => Navigator.of(context).pushReplacementNamed('/home'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchMovieController,
                    decoration: const InputDecoration(
                      labelText: 'Pesquisar filme',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                StandardButton(
                  onPressed: () {
                    final query = _searchMovieController.text.trim();
                    searchMoveis(query);
                  },
                  child: const Text('Buscar'),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                _hasSearched
                    ? FutureBuilder<List<Map<String, dynamic>>>(
                      future: searchResults,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.red,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  '🍿 Procurando filmes incríveis...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TweenAnimationBuilder<double>(
                                  duration: const Duration(seconds: 2),
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  builder: (context, value, child) {
                                    return Opacity(
                                      opacity: (value * 2) % 1,
                                      child: const Text(
                                        '🎬 Analisando catálogos...',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        } else if (snapshot.hasError) {
                          return Center(child: Text('Erro: ${snapshot.error}'));
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Nenhum filme encontrado para esta busca.',
                                  style: TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Voltar'),
                                ),
                              ],
                            ),
                          );
                        } else {
                          final movies = snapshot.data!;
                          return Column(
                            children: [
                              Text("Resultados para $_searchQuery"),
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: movies.length,
                                  itemBuilder: (context, index) {
                                    final movie = movies[index];
                                    return GestureDetector(
                                      onTap: () {
                                        // Chama o dialog do MovieCardComponent
                                        showDialog(
                                          context: context,
                                          builder:
                                              (ctx) => AlertDialog(
                                                title: Text(
                                                  movie['title'] ?? '',
                                                ),
                                                content: SingleChildScrollView(
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      if (movie['poster_url'] !=
                                                          null)
                                                        Center(
                                                          child: Image.network(
                                                            movie['poster_url'],
                                                            height: 200,
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                      const SizedBox(
                                                        height: 12,
                                                      ),
                                                      Text(
                                                        "${movie['year']} • ${movie['genres']?.join(', ') ?? ''}",
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 12,
                                                      ),
                                                      const Text(
                                                        'Sinopse',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        movie['overview'] ??
                                                            'Sinopse não disponível.',
                                                      ),
                                                      const SizedBox(
                                                        height: 12,
                                                      ),
                                                      const Text(
                                                        'Por que recomendamos:',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        movie['why_recommend'] ??
                                                            '',
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        'Disponível em: ${movie['streaming_services']?.join(', ') ?? 'Nenhum serviço de streaming encontrado'}',
                                                        style: TextStyle(
                                                          color: Colors.blue,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed:
                                                        () =>
                                                            Navigator.of(
                                                              ctx,
                                                            ).pop(),
                                                    child: const Text('Fechar'),
                                                  ),
                                                ],
                                              ),
                                        );
                                      },
                                      child: Card(
                                        margin: const EdgeInsets.only(
                                          bottom: 16,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            children: [
                                              // Imagem
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child:
                                                    movie['poster_url'] != null
                                                        ? Image.network(
                                                          movie['poster_url'],
                                                          width: 60,
                                                          height: 90,
                                                          fit: BoxFit.cover,
                                                          errorBuilder:
                                                              (
                                                                _,
                                                                __,
                                                                ___,
                                                              ) => Container(
                                                                width: 60,
                                                                height: 90,
                                                                color:
                                                                    Colors
                                                                        .grey[300],
                                                                child:
                                                                    const Icon(
                                                                      Icons
                                                                          .movie,
                                                                    ),
                                                              ),
                                                        )
                                                        : Container(
                                                          width: 60,
                                                          height: 90,
                                                          color:
                                                              Colors.grey[300],
                                                          child: const Icon(
                                                            Icons.movie,
                                                          ),
                                                        ),
                                              ),
                                              const SizedBox(width: 16),
                                              // Informações básicas
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      movie['title'] ??
                                                          'Título indisponível',
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      '${movie['year'] ?? ''} • ${movie['genres']?.join(', ') ?? ''}',
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      'Toque para ver detalhes',
                                                      style: TextStyle(
                                                        color: Colors.blue,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    )
                    : const Center(
                      child: Text(
                        'Nenhuma busca realizada',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}

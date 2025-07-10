import 'package:flutter/material.dart';
import 'package:movie_recommender/components/drawer_component.dart';
import 'package:movie_recommender/components/standard_appbar.dart';
import 'package:movie_recommender/components/standard_button.dart';
import 'package:movie_recommender/providers/gemini_provider.dart';
import 'package:movie_recommender/services/user_service.dart';
import 'package:movie_recommender/utils/routes.dart';
import 'package:movie_recommender/utils/search_filters.dart';

class SearchMoviePage extends StatefulWidget {
  const SearchMoviePage({super.key});

  @override
  State<SearchMoviePage> createState() => _SearchMoviePageState();
}

class _SearchMoviePageState extends State<SearchMoviePage> {
  final GeminiProvider _geminiProvider = GeminiProvider();
  final UserService _userService = UserService();
  late Future<List<Map<String, dynamic>>> searchResults;
  final _searchMovieController = TextEditingController();
  bool _hasSearched = false;
  String _searchQuery = '';
  String selectedFilter = SearchFilters.filmes;

  void _search(String arguments) {
    if (arguments.isNotEmpty) {
      setState(() {
        _searchQuery = arguments;
        searchResults =
            selectedFilter == SearchFilters.filmes
                ? _geminiProvider.searchMovies(arguments)
                : _userService
                    .getUsersByName(arguments)
                    .then(
                      (userModels) =>
                          userModels
                              .map(
                                (user) => {
                                  'uid': user.uid,
                                  'name': user.name,
                                  'photoUrl': user.photoUrl,
                                  'followingCount': user.followingCount,
                                  'followersCount': user.followersCount,
                                },
                              )
                              .toList(),
                    );
        _hasSearched = true;
      });

      print(searchResults);
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
            child: Column(
              children: [
                SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchMovieController,
                        decoration: const InputDecoration(
                          labelText: 'Pesquisar',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    StandardButton(
                      onPressed: () {
                        final query = _searchMovieController.text.trim();
                        _search(query);
                      },
                      child: const Text('Buscar'),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilterChip(
                      avatar: const Icon(Icons.movie, size: 18),
                      label: const Text('Filmes'),
                      selected: selectedFilter == SearchFilters.filmes,
                      onSelected: (bool selected) {
                        setState(() {
                          selectedFilter =
                              selected
                                  ? SearchFilters.filmes
                                  : SearchFilters.people;
                          searchResults = _geminiProvider.searchMovies(
                            _searchQuery,
                          );
                        });
                      },
                    ),
                    const SizedBox(width: 10),
                    FilterChip(
                      avatar: const Icon(Icons.people, size: 18),
                      label: const Text('Pessoas'),
                      selected: selectedFilter == SearchFilters.people,
                      onSelected: (bool selected) {
                        setState(() {
                          selectedFilter =
                              selected
                                  ? SearchFilters.people
                                  : SearchFilters.filmes;
                          searchResults = _userService
                              .getUsersByName(_searchQuery)
                              .then(
                                (userModels) =>
                                    userModels
                                        .map(
                                          (user) => {
                                            'uid': user.uid,
                                            'name': user.name,
                                            'photoUrl': user.photoUrl,
                                            'followingCount':
                                                user.followingCount,
                                            'followersCount':
                                                user.followersCount,
                                          },
                                        )
                                        .toList(),
                              );
                        });
                      },
                    ),
                  ],
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
                                Text(
                                  selectedFilter == SearchFilters.filmes
                                      ? '🍿 Procurando filmes incríveis...'
                                      : '👥 Procurando pessoas...',
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
                                      child: Text(
                                        selectedFilter == SearchFilters.filmes
                                            ? '🎬 Analisando catálogos...'
                                            : '🔍 Buscando usuários...',
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
                                Text(
                                  selectedFilter == SearchFilters.filmes
                                      ? 'Nenhum filme encontrado para esta busca.'
                                      : 'Nenhuma pessoa encontrada para esta busca.',
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
                          final results = snapshot.data!;
                          return Column(
                            children: [
                              Text("Resultados para $_searchQuery"),
                              Expanded(
                                child:
                                    selectedFilter == SearchFilters.filmes
                                        ? _buildMoviesList(results)
                                        : _buildUsersList(results),
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

  Widget _buildMoviesList(List<Map<String, dynamic>> movies) {
    return ListView.builder(
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
                    title: Text(movie['title'] ?? ''),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (movie['poster_url'] != null)
                            Center(
                              child: Image.network(
                                movie['poster_url'],
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            ),
                          const SizedBox(height: 12),
                          Text(
                            "${movie['year']} • ${movie['genres']?.join(', ') ?? ''}",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Sinopse',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(movie['overview'] ?? 'Sinopse não disponível.'),
                          const SizedBox(height: 12),
                          const Text(
                            'Por que recomendamos:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
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
          child: Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Imagem
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child:
                        movie['poster_url'] != null
                            ? Image.network(
                              movie['poster_url'],
                              width: 60,
                              height: 90,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) => Container(
                                    width: 60,
                                    height: 90,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.movie),
                                  ),
                            )
                            : Container(
                              width: 60,
                              height: 90,
                              color: Colors.grey[300],
                              child: const Icon(Icons.movie),
                            ),
                  ),
                  const SizedBox(width: 16),
                  // Informações básicas
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          movie['title'] ?? 'Título indisponível',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
                          style: TextStyle(color: Colors.blue, fontSize: 12),
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
    );
  }

  Widget _buildUsersList(List<Map<String, dynamic>> users) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.red[400],
              child:
                  user['photoUrl'] != null && user['photoUrl'].isNotEmpty
                      ? ClipOval(
                        child: Image.network(
                          user['photoUrl'],
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) =>
                                  Icon(Icons.person, color: Colors.white),
                        ),
                      )
                      : Icon(Icons.person, color: Colors.white),
            ),
            title: Text(
              user['name'] ?? 'Nome não disponível',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (user['email'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    user['email'],
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
                if (user['bio'] != null && user['bio'].isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    user['bio'],
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.person_add, color: Colors.blue),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Seguindo ${user['name']}'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
            onTap: () {
              // Navegar para a página de perfil do usuário
              Navigator.pushNamed(
                context,
                Routes.settings,
                arguments: user['uid'],
              );
            },
          ),
        );
      },
    );
  }
}

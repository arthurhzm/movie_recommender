import 'package:flutter/material.dart';
import 'package:movie_recommender/components/drawer_component.dart';
import 'package:movie_recommender/services/user_service.dart';

class UserMoviesPage extends StatefulWidget {
  const UserMoviesPage({super.key});

  @override
  State<UserMoviesPage> createState() => _UserMoviesPageState();
}

class _UserMoviesPageState extends State<UserMoviesPage> {
  List<Map<String, dynamic>>? userSwipes;
  final _userService = UserService();

  @override
  void initState() {
    super.initState();
    _userService
        .getUserSwipes()
        .then((swipes) {
          setState(() {
            userSwipes = swipes;
            print(userSwipes);
          });
        })
        .catchError((error) {
          // Handle error here, e.g., show a snackbar or dialog
          print('Error fetching user swipes: $error');
        });
  }

  @override
  Widget build(BuildContext context) {
    if (userSwipes == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (userSwipes!.isEmpty) {
      return Scaffold(
        drawer: const DrawerComponent(),
        appBar: AppBar(title: const Text('Meus filmes'), elevation: 0),
        body: const Center(
          child: Text(
            'Você ainda não avaliou nenhum filme',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    // Process swipes to eliminate duplicates and organize by movie title
    final Map<String, Map<String, dynamic>> uniqueMovies = {};
    for (var swipe in userSwipes!) {
      final movieTitle = swipe['movieTitle'] as String;
      // Keep only the latest rating for each movie
      if (!uniqueMovies.containsKey(movieTitle) ||
          (swipe['timestamp'].seconds >
              uniqueMovies[movieTitle]!['timestamp'].seconds)) {
        uniqueMovies[movieTitle] = swipe;
      }
    }

    final List<Map<String, dynamic>> processedSwipes =
        uniqueMovies.values.toList();
    // Sort by timestamp (most recent first)
    processedSwipes.sort(
      (a, b) => b['timestamp'].seconds.compareTo(a['timestamp'].seconds),
    );

    return Scaffold(
      drawer: const DrawerComponent(),
      appBar: AppBar(title: const Text('Meus filmes'), elevation: 0),
      body: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: processedSwipes.length,
        itemBuilder: (context, index) {
          final movie = processedSwipes[index];
          final String action = movie['action'] as String;
          final bool liked = action == 'like';
          final bool superLiked = action == 'super_like';

          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              leading: CircleAvatar(
                backgroundColor:
                    superLiked
                        ? Colors.blue.shade100
                        : liked
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                child: Icon(
                  superLiked
                      ? Icons.star
                      : liked
                      ? Icons.thumb_up
                      : Icons.thumb_down,
                  color:
                      superLiked
                          ? Colors.blue
                          : liked
                          ? Colors.green
                          : Colors.red,
                ),
              ),
              title: Text(
                movie['movieTitle'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6.0,
                    runSpacing: 6.0,
                    children:
                        (movie['genres'] as List<dynamic>)
                            .map(
                              (genre) => Chip(
                                label: Text(
                                  genre,
                                  style: const TextStyle(fontSize: 10.0),
                                ),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                padding: EdgeInsets.zero,
                                labelPadding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                  vertical: 0,
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ],
              ),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  _userService
                      .deleteSwipe(movie['movieTitle'])
                      .then((_) {
                        setState(() {
                          processedSwipes.removeAt(index);

                          userSwipes!.removeWhere(
                            (swipe) =>
                                swipe['movieTitle'] == movie['movieTitle'],
                          );
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Filme "${movie['movieTitle']}" removido',
                            ),
                          ),
                        );
                      })
                      .catchError((error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erro ao remover filme: $error'),
                          ),
                        );
                      });
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

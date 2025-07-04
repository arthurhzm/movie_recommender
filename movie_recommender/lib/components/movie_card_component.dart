import 'package:flutter/material.dart';

class MovieCardComponent extends StatefulWidget {
  final Map<String, dynamic> movie;
  const MovieCardComponent({super.key, required this.movie});

  @override
  State<MovieCardComponent> createState() => _MovieCardComponentState();
}

class _MovieCardComponentState extends State<MovieCardComponent> {
  Map<String, dynamic> get movie => widget.movie;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
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
                      if (movie['poster_url'] != null &&
                          movie['poster_url'].isNotEmpty)
                        Center(
                          child: Image.network(
                            movie['poster_url'],
                            height: 200,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 200,
                                width: double.infinity,
                                color: Colors.grey[300],
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.local_movies,
                                      size: 40,
                                      color: Colors.grey[600],
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Preparando o show...',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    SizedBox(
                                      width: 100,
                                      child: LinearProgressIndicator(
                                        value:
                                            loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                                : null,
                                        backgroundColor: Colors.grey[400],
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.orange,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                width: double.infinity,
                                color: Colors.grey[300],
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.movie,
                                      size: 50,
                                      color: Colors.grey[600],
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Poster não\ndisponível',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        )
                      else
                        Container(
                          height: 200,
                          width: double.infinity,
                          color: Colors.grey[300],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.movie,
                                size: 50,
                                color: Colors.grey[600],
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Poster não\ndisponível',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
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
      child: Container(
        width: 120,
        margin: EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(5)),
              child:
                  movie['poster_url'] != null && movie['poster_url'].isNotEmpty
                      ? Image.network(
                        movie['poster_url'],
                        height: 180,
                        width: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 180,
                            width: 120,
                            color: Colors.grey[300],
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.movie,
                                  size: 30,
                                  color: Colors.grey[600],
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Sem\nPoster',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                      : Container(
                        height: 180,
                        width: 120,
                        color: Colors.grey[300],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.movie,
                              size: 30,
                              color: Colors.grey[600],
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Sem\nPoster',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 10,
                              ),
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
}

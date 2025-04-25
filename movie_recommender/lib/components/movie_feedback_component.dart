import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:movie_recommender/providers/tmdb_provider.dart';
import 'package:movie_recommender/services/user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MovieFeedbackComponent extends StatefulWidget {
  final String movieTitle;

  const MovieFeedbackComponent({super.key, required this.movieTitle});

  @override
  State<MovieFeedbackComponent> createState() => _MovieFeedbackComponentState();
}

class _MovieFeedbackComponentState extends State<MovieFeedbackComponent> {
  final _userService = UserService();
  late List<Map<String, dynamic>> userSwipes;
  final _feedbackController = TextEditingController();
  bool _isLoading = false;

  void _saveFeedback() async {
    if (_feedbackController.text.isNotEmpty) {
      try {
        setState(() {
          _isLoading = true;
        });

        final userId = FirebaseAuth.instance.currentUser?.uid;

        final querySnapshot =
            await FirebaseFirestore.instance
                .collection('user_swipes')
                .where('userId', isEqualTo: userId)
                .where('movieTitle', isEqualTo: widget.movieTitle)
                .get();

        if (querySnapshot.docs.isNotEmpty) {
          await querySnapshot.docs.first.reference.update({
            'detailedFeedback': _feedbackController.text,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Feedback enviado com sucesso!')),
          );

          Navigator.of(context).pop();
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving feedback: $e')));
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'O feedback do filme não pode ser vazio, caso não queria avaliar o filme, apenas feche esta tela.',
          ),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _isLoading = true;
    _userService
        .getUserSwipes()
        .then((swipes) {
          setState(() {
            userSwipes = swipes;
            _isLoading = false;

            final movieSwipe = swipes.firstWhere(
              (swipe) => swipe['movieTitle'] == widget.movieTitle,
              orElse: () => <String, dynamic>{},
            );
            if (movieSwipe.containsKey('detailedFeedback')) {
              _feedbackController.text = movieSwipe['detailedFeedback'] ?? '';
            }
          });
        })
        .catchError((error) {
          // Handle error here, e.g., show a snackbar or dialog
          print('Error fetching user swipes: $error');
          setState(() {
            _isLoading = false;
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.movieTitle),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : FutureBuilder<List<Map<String, dynamic>>>(
                future: TmdbProvider().searchMoviesByTitle(widget.movieTitle),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildFeedbackForm(null);
                  }

                  final movieData = snapshot.data!.first;
                  return _buildFeedbackForm(movieData);
                },
              ),
    );
  }

  Widget _buildFeedbackForm(Map<String, dynamic>? movieData) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (movieData != null && movieData['poster_path'] != null)
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  movieData['poster_url'],
                  height: 300,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      height: 300,
                      child: Center(
                        child: CircularProgressIndicator(
                          value:
                              loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox(
                      height: 300,
                      child: Center(child: Icon(Icons.error)),
                    );
                  },
                ),
              ),
            ),
          const SizedBox(height: 20),
          if (movieData != null &&
              movieData['overview'] != null &&
              movieData['overview'].toString().isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sinopse', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  movieData['overview'],
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
              ],
            ),
          Text(
            'Avalie o filme:',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _feedbackController,
            decoration: InputDecoration(
              labelText: 'Dê o seu melhor feedback',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
            maxLines: 5,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saveFeedback,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child:
                  _isLoading
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                      : const Text('Enviar Avaliação'),
            ),
          ),
        ],
      ),
    );
  }
}

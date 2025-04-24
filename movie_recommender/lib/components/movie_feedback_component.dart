import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
      appBar: AppBar(title: Text(widget.movieTitle)),
      body: Center(
        child: Column(
          children: [
            TextField(
              controller: _feedbackController,
              decoration: const InputDecoration(
                labelText: 'Dê o seu melhor feedback',
              ),
            ),
            ElevatedButton(onPressed: _saveFeedback, child: Text('Avaliar')),
          ],
        ),
      ),
    );
  }
}

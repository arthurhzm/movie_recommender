import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:movie_recommender/components/drawer_component.dart';
import 'package:movie_recommender/providers/gemini_provider.dart';
import 'package:movie_recommender/services/api_limit_service.dart';
import 'package:movie_recommender/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:another_flushbar/flushbar.dart';

class RecommendationsPage extends StatefulWidget {
  const RecommendationsPage({super.key});

  @override
  State<RecommendationsPage> createState() => _RecommendationsPageState();
}

class _RecommendationsPageState extends State<RecommendationsPage> {
  final List<Map<String, dynamic>> _movies = [];
  final GeminiProvider _geminiProvider = GeminiProvider();
  final userId = FirebaseAuth.instance.currentUser?.uid;
  int _currentIndex = 0;
  String? _errorMessage;
  final UserService _userService = UserService();
  late Future<List<Map<String, dynamic>>> userSwipes;
  final db = FirebaseFirestore.instance;
  bool _isSwipeInProgress = false;
  final double _swipeThreshold = 100.0;
  late Future<List<Map<String, dynamic>>> _recommendationsFuture;
  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();
    _recommendationsFuture = _loadRecommendations();
    _checkFirstTime();
  }

  Future<List<Map<String, dynamic>>> _loadRecommendations() async {
    if (userId == null) return [];

    // Check user preferences first
    final userPreferences = await _userService.getUserPreferences();
    if (userPreferences.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamed(context, '/preferences/add');
      });
      return [];
    }

    final canRequest = await ApiUsageService().canMakeRequest(userId!);

    if (canRequest['success'] == false) {
      String message = 'Não foi possível fazer a requisição.';

      if (canRequest['reason'] == 'DAILY_COUNT') {
        message =
            'Você atingiu o limite de recomendações para hoje. Volte amanhã para descobrir mais filmes!';
      } else if (canRequest['reason'] == 'MINUTE_COUNT') {
        message =
            'Você atingiu o limite de solicitações por minuto. Aguarde um momento e tente novamente.';
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => AlertDialog(
                title: Text(
                  canRequest['reason'] == 'DAILY_COUNT'
                      ? 'Limite diário atingido'
                      : 'Muitas solicitações',
                ),
                content: Text(message),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Entendi'),
                  ),
                ],
              ),
        );
      });
      return [];
    }

    try {
      final movies = await _geminiProvider.getMoviesRecommendations(5);
      _movies.clear();
      _movies.addAll(movies);
      return movies;
    } catch (e) {
      _errorMessage = e.toString();
      throw Exception(e.toString());
    }
  }

  void _refreshRecommendations() {
    setState(() {
      _recommendationsFuture = _loadRecommendations();
      _currentIndex = 0;
      _errorMessage = null;
    });
  }

  void _handleSwipe(String action) async {
    if (_isSwipeInProgress) return;

    setState(() {
      _isSwipeInProgress = true;
    });

    final currentMovie = _movies[_currentIndex];

    // Feedback
    await FirebaseFirestore.instance.collection('user_swipes').add({
      'userId': FirebaseAuth.instance.currentUser?.uid,
      'movieTitle': currentMovie['title'],
      'action': action,
      'genres': currentMovie['genres'],
      'detailedFeedback': "",
      'timestamp': FieldValue.serverTimestamp(),
    });

    Flushbar(
      message:
          'Avaliação recebida! Caso queira fornecer mais detalhes e melhorar as recomendações, acesse "Meus filmes" e clique no filme desejado',
      duration: const Duration(seconds: 4),
      flushbarPosition: FlushbarPosition.TOP, // <- no topo!
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
      backgroundColor: Colors.black87,
      icon: const Icon(Icons.info_outline, color: Colors.white),
    ).show(context);

    setState(() {
      userSwipes = _userService.getUserSwipes();
    });

    if (_currentIndex < _movies.length - 1) {
      setState(() {
        _currentIndex++;
        _isSwipeInProgress = false;
      });
    } else {
      _refreshRecommendations();
      setState(() {
        _isSwipeInProgress = false;
      });
    }
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenTutorial =
        prefs.getBool('has_seen_recommendations_tutorial') ?? false;

    if (!hasSeenTutorial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _showTutorial = true;
        });
      });
    }
  }

  Future<void> _markTutorialSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_recommendations_tutorial', true);
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder:
          (ctx) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 16,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    child: const Row(
                      children: [
                        Icon(Icons.help_outline, color: Colors.white, size: 28),
                        SizedBox(width: 12),
                        Text(
                          'Como usar',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildHelpItem(
                          Icons.swipe_left,
                          Colors.red,
                          'Arrastar para esquerda',
                          'Não gostei',
                        ),
                        const SizedBox(height: 16),
                        _buildHelpItem(
                          Icons.swipe_right,
                          Colors.green,
                          'Arrastar para direita',
                          'Gostei',
                        ),
                        const SizedBox(height: 16),
                        _buildHelpItem(
                          Icons.swipe_up,
                          Colors.blue,
                          'Arrastar para cima',
                          'Super gostei!',
                        ),
                        const SizedBox(height: 16),
                        _buildHelpItem(
                          Icons.touch_app,
                          Colors.orange,
                          'Tocar no cartaz',
                          'Ver detalhes',
                        ),
                      ],
                    ),
                  ),
                  // Button
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF667eea),
                          elevation: 8,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Entendi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildHelpItem(
    IconData icon,
    Color color,
    String title,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialOverlay() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Stack(
        children: [
          // Animated background blur
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.black],
              ),
            ),
            child: const SizedBox.expand(),
          ),
          // Tutorial content with animation
          Center(
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.7 + (0.3 * value),
                  child: Opacity(
                    opacity: value,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFFFFFF), Color(0xFFF8F9FA)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                            spreadRadius: 0,
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(0.8),
                            blurRadius: 0,
                            offset: const Offset(0, 1),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Header with gradient text
                              Container(
                                padding: const EdgeInsets.only(bottom: 24),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF667eea),
                                            Color(0xFF764ba2),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF667eea,
                                            ).withOpacity(0.3),
                                            blurRadius: 12,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.movie_filter,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ShaderMask(
                                      shaderCallback:
                                          (bounds) => const LinearGradient(
                                            colors: [
                                              Color(0xFF667eea),
                                              Color(0xFF764ba2),
                                            ],
                                          ).createShader(bounds),
                                      child: const Text(
                                        'Como avaliar filmes',
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Instruction items
                              _buildPremiumHelpItem(
                                Icons.swipe_left_outlined,
                                const Color(0xFFFF6B6B),
                                'Arrastar para esquerda',
                                'Não gostei',
                                0,
                              ),
                              const SizedBox(height: 16),
                              _buildPremiumHelpItem(
                                Icons.swipe_right_outlined,
                                const Color(0xFF4ECDC4),
                                'Arrastar para direita',
                                'Gostei',
                                1,
                              ),
                              const SizedBox(height: 16),
                              _buildPremiumHelpItem(
                                Icons.swipe_up_outlined,
                                const Color(0xFF45B7D1),
                                'Arrastar para cima',
                                'Super gostei!',
                                2,
                              ),
                              const SizedBox(height: 16),
                              _buildPremiumHelpItem(
                                Icons.touch_app_outlined,
                                const Color(0xFFFFA726),
                                'Tocar no cartaz',
                                'Ver mais detalhes',
                                3,
                              ),
                              const SizedBox(height: 32),
                              // Action buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 56,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: TextButton(
                                        onPressed: () {
                                          setState(() {
                                            _showTutorial = false;
                                          });
                                        },
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.grey.shade600,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          'Pular',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      height: 56,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF667eea),
                                            Color(0xFF764ba2),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF667eea,
                                            ).withOpacity(0.4),
                                            blurRadius: 12,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          await _markTutorialSeen();
                                          setState(() {
                                            _showTutorial = false;
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          foregroundColor: Colors.white,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          'Entendi',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumHelpItem(
    IconData icon,
    Color color,
    String title,
    String subtitle,
    int index,
  ) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.2), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildMovieCard(Map<String, dynamic> movie) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxCardHeight = screenHeight * 0.8; // Limita a altura do card

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: Text(movie['title']),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${movie['year']} • ${movie['genres'].join(', ')}'),
                      const SizedBox(height: 16),
                      const Text(
                        'Sinopse',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(movie['overview'] ?? 'Sinopse não disponível.'),
                      const SizedBox(height: 16),
                      const Text(
                        'Por que recomendamos:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(movie['why_recommend'] ?? ''),
                      const SizedBox(height: 8),
                      Text(
                        'Disponível em: ${movie['streaming_services']?.join(', ') ?? 'Nenhum serviço de streaming encontrado'}',
                        style: const TextStyle(
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
      onPanEnd: (details) {
        if (_isSwipeInProgress) return;

        final velocity = details.velocity.pixelsPerSecond;
        if (velocity.dy < -_swipeThreshold &&
            velocity.dy.abs() > velocity.dx.abs()) {
          _handleSwipe('super_like');
        } else if (velocity.dx.abs() > _swipeThreshold) {
          if (velocity.dx > 0) {
            _handleSwipe('like');
          } else {
            _handleSwipe('dislike');
          }
        }
      },
      child: Card(
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: maxCardHeight,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  image:
                      movie['poster_url'] != null
                          ? DecorationImage(
                            image: NetworkImage(movie['poster_url']),
                            fit: BoxFit.cover,
                          )
                          : null,
                ),
                child:
                    movie['poster_url'] == null
                        ? const Center(child: Icon(Icons.movie, size: 50))
                        : null,
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withAlpha(179)],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        movie['title'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${movie['year']} • ${movie['genres'].join(', ')}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _sanitizeJson(String rawJson) {
    // Remove caracteres não-ASCII e linhas problemáticas
    return rawJson
        .replaceAll(RegExp(r'[^\x00-\x7F]'), '') // Remove caracteres não-ASCII
        .replaceAll(RegExp(r',\s*\}'), '}') // Remove vírgulas finais
        .replaceAll(RegExp(r',\s*\]'), ']'); // Remove vírgulas finais
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const DrawerComponent(),
      appBar: AppBar(
        title: const Text('Descubra Filmes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshRecommendations,
          ),
        ],
      ),
      body: Stack(
        children: [
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _recommendationsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Buscando filmes perfeitos para você...'),
                    ],
                  ),
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text('Erro: ${snapshot.error}'),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _refreshRecommendations,
                        child: Text('Tentar novamente'),
                      ),
                    ],
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.movie_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Nenhum filme disponível'),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _refreshRecommendations,
                        child: Text('Buscar filmes'),
                      ),
                    ],
                  ),
                );
              } else {
                return Center(child: _buildMovieCard(_movies[_currentIndex]));
              }
            },
          ),
          if (_showTutorial) _buildTutorialOverlay(),
        ],
      ),
      bottomNavigationBar: FutureBuilder<List<Map<String, dynamic>>>(
        future: _recommendationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return const SizedBox.shrink();
          }

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(
                  heroTag: 'dislike',
                  onPressed: () => _handleSwipe('dislike'),
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.thumb_down, size: 30),
                ),
                FloatingActionButton(
                  heroTag: 'super-like',
                  onPressed: () => _handleSwipe('super_like'),
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.star, size: 30),
                ),
                FloatingActionButton(
                  heroTag: 'like',
                  onPressed: () => _handleSwipe('like'),
                  backgroundColor: Colors.green,
                  child: const Icon(Icons.thumb_up, size: 30),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

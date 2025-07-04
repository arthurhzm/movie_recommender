import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:movie_recommender/components/drawer_component.dart';
import 'package:movie_recommender/components/standard_appbar.dart';
import 'package:movie_recommender/providers/gemini_provider.dart';
import 'package:movie_recommender/services/user_service.dart';
import 'package:movie_recommender/utils/gemini_models.dart';
import 'package:speech_to_text/speech_to_text.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final db = FirebaseAuth.instance;
  final userId = FirebaseAuth.instance.currentUser?.uid;
  final user = FirebaseAuth.instance.currentUser;
  final UserService _userService = UserService();
  late Future<Map<String, dynamic>> userPreferences;
  final List<Map<String, String>> messages = [];
  final _geminiProvider = GeminiProvider(model: GeminiModels.gemini_2_5_flash);
  final SpeechToText _speechToText = SpeechToText();
  bool _isLoading = false;
  bool _isListening = false;
  bool _speechEnabled = false;
  @override
  void initState() {
    super.initState();
    userPreferences = _userService.getUserPreferences();
    _initSpeech();

    _messageController.addListener(() {
      setState(() {});
    });
  }

  void _initSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (val) {
          debugPrint('Erro no speech-to-text: $val');
          setState(() {
            _isListening = false;
          });
        },
        onStatus: (val) {
          debugPrint('Status do speech-to-text: $val');
          if (val == 'done' || val == 'notListening') {
            setState(() {
              _isListening = false;
            });
          }
        },
      );
      setState(() {});
    } catch (e) {
      debugPrint('Erro ao inicializar speech-to-text: $e');
      _speechEnabled = false;
    }
  }

  void _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    setState(() {
      messages.add({'text': messageText, 'sender': 'user'});
      _isLoading = true;
      _messageController.clear();
    });

    try {
      final answer = await _geminiProvider.sendIndividualMessage(messages);

      setState(() {
        messages.add({'text': answer, 'sender': 'gemini'});
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        messages.add({
          'text': 'Ocorreu um erro ao processar sua mensagem.',
          'sender': 'gemini',
        });
        _isLoading = false;
      });
      debugPrint('Error sending message: $e');
    }
  }

  void _toggleListening() async {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  void _startListening() async {
    if (!_speechEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Speech recognition não está disponível')),
      );
      return;
    }

    setState(() {
      _isListening = true;
    });

    await _speechToText.listen(
      onResult: (result) {
        setState(() {
          _messageController.text = result.recognizedWords;
        });
      },
      listenFor: Duration(seconds: 30),
      pauseFor: Duration(seconds: 3),
      localeId: 'pt_BR',
    );
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: DrawerComponent(),
      appBar: StandardAppBar(),
      body: Column(
        children: [
          Expanded(
            child:
                messages.isEmpty
                    ? Center(
                      child: Text(
                        'Envie uma mensagem para começar a conversa!',
                      ),
                    )
                    : ListView.builder(
                      padding: EdgeInsets.all(10),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isUser = message['sender'] == 'user';

                        return Align(
                          alignment:
                              isUser
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                          child: Container(
                            margin: EdgeInsets.symmetric(vertical: 5),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  isUser
                                      ? const Color.fromARGB(255, 131, 78, 255)
                                      : Colors.grey[200],
                              borderRadius:
                                  isUser
                                      ? BorderRadius.only(
                                        topLeft: Radius.circular(15),
                                        bottomLeft: Radius.circular(15),
                                        topRight: Radius.circular(15),
                                      )
                                      : BorderRadius.only(
                                        topLeft: Radius.circular(15),
                                        topRight: Radius.circular(15),
                                        bottomRight: Radius.circular(15),
                                      ),
                            ),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.7,
                            ),
                            child: MarkdownBody(
                              data: message['text'] ?? '',
                              styleSheet: MarkdownStyleSheet(
                                p: TextStyle(
                                  color: isUser ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
          if (_isLoading)
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Gerando resposta...'),
                ],
              ),
            ),
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 20, 18, 14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5,
                  offset: Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText:
                          _isListening
                              ? 'Ouvindo...'
                              : 'Digite sua mensagem...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor:
                          _isListening
                              ? const Color.fromARGB(255, 50, 30, 30)
                              : const Color.fromARGB(255, 32, 32, 32),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      prefixIcon:
                          _isListening
                              ? Icon(Icons.mic, color: Colors.red)
                              : null,
                    ),
                    enabled: !_isListening,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  onPressed:
                      _isLoading
                          ? null
                          : _messageController.text.isEmpty
                          ? _toggleListening
                          : _sendMessage,
                  icon: AnimatedSwitcher(
                    duration: Duration(milliseconds: 200),
                    transitionBuilder:
                        (child, animation) =>
                            ScaleTransition(scale: animation, child: child),
                    child:
                        _isListening
                            ? Icon(
                              Icons.stop,
                              key: ValueKey<String>('stop'),
                              color: Colors.red,
                            )
                            : Icon(
                              _messageController.text.isEmpty
                                  ? Icons.mic
                                  : Icons.send,
                              key: ValueKey<String>(
                                _messageController.text.isEmpty
                                    ? 'mic'
                                    : 'send',
                              ),
                            ),
                  ),
                  color:
                      _isListening
                          ? Colors.red
                          : const Color.fromARGB(255, 183, 166, 224),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

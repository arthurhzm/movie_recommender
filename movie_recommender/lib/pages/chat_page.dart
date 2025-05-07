import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:movie_recommender/services/user_service.dart';
import 'package:movie_recommender/components/drawer_component.dart';
import 'package:movie_recommender/components/standard_appbar.dart';

import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final db = FirebaseAuth.instance;
  final userId = FirebaseAuth.instance.currentUser?.uid;
  final user = FirebaseAuth.instance.currentUser;
  final UserService _userService = UserService();
  late Future<Map<String, dynamic>> userPreferences;

  @override
  void initState() {
    super.initState();
    userPreferences = _userService.getUserPreferences();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: DrawerComponent(),
      appBar: StandardAppBar(),
      body: Column(
        children: [
          Flexible(
            child: ListView(
              children: [
                ListTile(
                  leading: CircleAvatar(),
                  title: Text(user?.displayName ?? ""),
                  subtitle: Text("Mensagem..."),
                  trailing: Text(DateFormat('H:mm - dd/MM/yyyy').format(DateTime.now())),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(10),
            height: 80,
            child: Row(
              spacing: 10,
              children: [
                Expanded(child: TextField()),
                IconButton(onPressed: () => {}, icon: Icon(Icons.send))
              ],
            ),
          )
        ],
      ),
    );
  }
}

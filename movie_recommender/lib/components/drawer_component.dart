import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:movie_recommender/pages/login_page.dart';

class DrawerComponent extends StatefulWidget {
  const DrawerComponent({super.key});

  @override
  State<DrawerComponent> createState() => _DrawerComponentState();
}

class _DrawerComponentState extends State<DrawerComponent> {
  final _auth = FirebaseAuth.instance;
  final _user = FirebaseAuth.instance.currentUser;

  void _signOut() async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.grey[900]),
            child: Row(
              children: [
                Icon(Icons.account_circle, size: 60),
                Padding(padding: EdgeInsets.only(right: 5)),
                Text(_user?.displayName ?? ""),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Início'),
            onTap: () {
              Navigator.pushNamed(context, '/home');
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Perfil'),
            onTap: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.recommend),
            title: const Text('Recomendações'),
            onTap: () {
              Navigator.pushNamed(context, '/recommendations');
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_reaction_outlined),
            title: const Text('Preferências'),
            onTap: () {
              Navigator.pushNamed(context, '/preferences');
            },
          ),
          ListTile(
            leading: const Icon(Icons.movie),
            title: const Text('Meus Filmes'),
            onTap: () {
              Navigator.pushNamed(context, '/user_movies');
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sair'),
            onTap: _signOut,
          ),
        ],
      ),
    );
  }
}

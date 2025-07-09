import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:movie_recommender/components/standard_button.dart';
import 'package:movie_recommender/models/api_limit_model.dart';
import 'package:movie_recommender/models/user_model.dart';
import 'package:movie_recommender/providers/movie_api_provider.dart';
import 'package:movie_recommender/services/api_limit_service.dart';
import 'package:movie_recommender/services/user_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _moviesApiProvider = MovieApiProvider();
  final _apiUsageService = ApiUsageService();
  final _userService = UserService();

  void _createUser() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Criando o usuário no Firebase Auth
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            );
        // Atualizando o nome do usuário no Firebase Auth
        await credential.user?.updateDisplayName(_nameController.text);
        // Criando o limite de uso da API do gemini para o usuário
        await _apiUsageService.createUserApiUsage(credential.user?.uid);

        // Criando o usuário no Firestore
        UserModel user = UserModel(
          uid: credential.user!.uid,
          name: _nameController.text.trim(),
        );
        await _userService.createUser(user);

        Navigator.pushReplacementNamed(context, '/');

        // Criando o usuário na API do MoviesAPI
        await _moviesApiProvider.createUser(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'weak-password') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('A senha informada é muito fraca!')),
          );
        } else if (e.code == 'email-already-in-use') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'O e-mail informado já está em uso. Faça login ou recupere a senha!',
              ),
            ),
          );
        }
      } catch (e) {
        print(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: StandardAppBar(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person, color: Colors.blue, size: 40),
                      Icon(Icons.add_rounded, size: 40),
                      Icon(Icons.movie_filter, color: Colors.green, size: 40),
                      Icon(Icons.drag_handle_rounded, size: 40),
                      Icon(Icons.favorite, color: Colors.orange, size: 40),
                    ],
                  ),
                ),
                Text(
                  "Insira as credenciais abaixo para realizarmos seu registro na aplicação",
                  style: TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira seu nome';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira seu email';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Por favor, insira um email válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira sua senha';
                    }
                    if (value.length < 6) {
                      return 'A senha deve ter ao menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                StandardButton(
                  onPressed: _createUser,
                  child: Text('Registrar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

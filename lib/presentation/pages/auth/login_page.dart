import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('nome do projeto')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const TextField(
              decoration: InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 16),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(labelText: 'Senha'),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Implementar lógica de login
              },
              child: const Text('Login'),
            ),
            TextButton(
              onPressed: () {
                // Navegar para tela de cadastro
              },
              child: const Text('Criar conta'),
            ),
          ],
        ),
      ),
    );
  }
}
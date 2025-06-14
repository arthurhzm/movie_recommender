import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:movie_recommender/components/drawer_component.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _auth = FirebaseAuth.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    if (_currentUser != null) {
      _nameController.text = _currentUser!.displayName ?? '';
      _emailController.text = _currentUser!.email ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (_currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Update display name
      if (_nameController.text.isNotEmpty &&
          _nameController.text != _currentUser!.displayName) {
        await _currentUser!.updateDisplayName(_nameController.text);
      }

      // Update email
      if (_emailController.text.isNotEmpty &&
          _emailController.text != _currentUser!.email) {
        try {
          await _currentUser!.verifyBeforeUpdateEmail(_emailController.text);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Um link de verificação foi enviado para o novo email. '
                'Por favor, verifique sua caixa de entrada e siga as instruções.',
              ),
              duration: Duration(seconds: 8),
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Não foi possível atualizar o email: ${e.toString()}',
              ),
            ),
          );
          rethrow;
        }
      }

      // Update password
      if (_passwordController.text.isNotEmpty) {
        await _currentUser!.updatePassword(_passwordController.text);
        _passwordController.clear();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil atualizado com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar perfil: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const DrawerComponent(),
      appBar: AppBar(title: const Text('Perfil')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 65,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: _currentUser?.photoURL != null
                              ? NetworkImage(_currentUser!.photoURL!)
                              : null,
                          child: _currentUser?.photoURL == null
                              ? const Icon(
                                  Icons.person,
                                  size: 65,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                //TODO - FUNÇÃO PRA TROCAR A FOTO DO FODIDO
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Função para alterar foto não implementada',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Nova Senha',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                      helperText: 'Deixe em branco para manter a senha atual',
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _updateProfile,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text('Atualizar Perfil'),
                  ),
                ],
              ),
            ),
    );
  }
}

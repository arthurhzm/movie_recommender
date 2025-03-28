import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  // Função para autenticar um usuário com email e senha no firebase
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  );

  // Função para criar um novo usuário com email e senha no firebase
  // Retorna um UserCredential que contém informações sobre o usuário autenticado
  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  );

  Future<void> signOut(); // Função para desconectar o usuário atual
  User? getCurrentUser(); // Função para obter o usuário atual
  Stream<User?> get authStateChanges; // Fluxo de mudanças de autenticação
}

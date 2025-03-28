import 'package:movie_recommender/domain/repositories/auth_repository.dart';

class SignUpWithEmailAndPassword {
  final AuthRepository repository;

  SignUpWithEmailAndPassword(this.repository);

  Future<void> call(String email, String password) async {
    await repository.signInWithEmailAndPassword(email, password);
  }
}
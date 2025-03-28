import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movie_recommender/data/repositories/auth_repository_impl.dart';
import 'package:movie_recommender/domain/repositories/auth_repository.dart';
import 'package:movie_recommender/domain/usecases/sign_up_with_email_and_password.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

// Provider para o use case (se criou o use case)
final signUpWithEmailAndPasswordProvider = Provider((ref) {
  return SignUpWithEmailAndPassword(ref.read(authRepositoryProvider));
});

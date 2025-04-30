import 'package:best/domain/entities/user_entity.dart';
import 'package:best/domain/repositories/auth_repository.dart';

class GoogleSignInUseCase {
  final AuthRepository repository;

  GoogleSignInUseCase(this.repository);

  Future<UserEntity> execute() async {
    return await repository.signInWithGoogle();
  }
}

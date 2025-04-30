import 'package:best/domain/entities/user_entity.dart';
import 'package:best/domain/repositories/auth_repository.dart';

class SignUpUseCase {
  final AuthRepository repository;

  SignUpUseCase(this.repository);

  Future<UserEntity> execute({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    return await repository.signUp(
      email: email,
      password: password,
      fullName: fullName,
      phoneNumber: phoneNumber,
    );
  }
}

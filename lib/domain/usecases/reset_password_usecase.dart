import 'package:best/domain/repositories/auth_repository.dart';

class ResetPasswordUseCase {
  final AuthRepository repository;

  ResetPasswordUseCase(this.repository);

  Future<void> execute({required String email}) async {
    return await repository.resetPassword(email: email);
  }
}

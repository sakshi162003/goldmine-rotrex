import 'package:best/data/repositories/auth_repository_impl.dart';
import 'package:best/data/services/supabase_config_service.dart';
import 'package:best/domain/repositories/auth_repository.dart';
import 'package:best/domain/usecases/google_sign_in_usecase.dart';
import 'package:best/domain/usecases/reset_password_usecase.dart';
import 'package:best/domain/usecases/sign_in_usecase.dart';
import 'package:best/domain/usecases/sign_up_usecase.dart';
import 'package:best/presentation/controllers/auth_controller.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Initialize all dependencies for the application
Future<void> initDependencies() async {
  // External
  final supabaseClient = Supabase.instance.client;
  final googleSignIn = GoogleSignIn();

  // Services
  Get.lazyPut(
    () => SupabaseConfigService(supabaseClient: supabaseClient),
    fenix: true,
  );

  // Repositories
  Get.lazyPut<AuthRepository>(
    () => AuthRepositoryImpl(
      supabaseClient: supabaseClient,
      googleSignIn: googleSignIn,
    ),
    fenix: true,
  );

  // Use cases
  Get.lazyPut(() => SignUpUseCase(Get.find<AuthRepository>()), fenix: true);
  Get.lazyPut(() => SignInUseCase(Get.find<AuthRepository>()), fenix: true);
  Get.lazyPut(() => GoogleSignInUseCase(Get.find<AuthRepository>()),
      fenix: true);
  Get.lazyPut(() => ResetPasswordUseCase(Get.find<AuthRepository>()),
      fenix: true);

  // Controllers
  Get.lazyPut(
    () => AuthController(
      signUpUseCase: Get.find(),
      signInUseCase: Get.find(),
      googleSignInUseCase: Get.find(),
      resetPasswordUseCase: Get.find(),
    ),
    fenix: true,
  );
}

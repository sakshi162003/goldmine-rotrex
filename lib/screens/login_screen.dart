import 'package:flutter/material.dart';
import 'package:best/widgets/or_separator.dart';
import 'package:best/presentation/controllers/auth_controller.dart';
import 'package:get/get.dart';
import 'package:best/domain/entities/user_role.dart';
import 'package:best/data/services/user_role_service.dart';
import 'package:best/utils/admin_checker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authController = Get.find<AuthController>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    final result = await _authController.signInWithGoogle();

    if (result == "Success") {
      // Set as regular user for Google sign-in
      await UserRoleService.saveUserRole(UserRole.user);
      Get.offAllNamed('/home');
    } else {
      _authController.showError(result);
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    
    print("Login attempt: $email");
    
    // Check if admin login
    bool isAdminLogin = false;
    if (email == 'sahilbagal877@gmail.com' && password == 'Sahil@123') {
      print("Admin credentials detected");
      isAdminLogin = true;
    }

    // Use the enhanced auth controller for login
    final result = await _authController.signIn(
      email: email,
      password: password,
    );
    
    print("Login result: $result");

    if (result == "Success") {
      print("Login successful, checking if admin...");
      
      // For admin login, use our special utility to ensure admin role is set
      if (isAdminLogin) {
        print("Running admin checker...");
        final adminSetupResult = await AdminChecker.checkAndCreateAdminUser();
        print("Admin setup result: $adminSetupResult");
        
        if (adminSetupResult) {
          // Force refresh admin status in auth controller
          await _authController.verifyAdminStatus();
          
          // Check if we are still logged in (sometimes auth state can be lost)
          final currentUser = Supabase.instance.client.auth.currentUser;
          if (currentUser == null) {
            print("Auth state lost after admin setup, redirecting to login");
            _showLoginErrorDialog("Invalid Credentials");
            return;
          }
          
          print("Admin setup completed successfully, navigating to home page");
          Get.offAllNamed('/home');
          return;
        }
      }
      
      // For regular user login or if admin setup failed
      final isAdmin = await _authController.verifyAdminStatus();
      print("Is admin: $isAdmin");
      
      // Always navigate to home for both admin and regular users
      print("Navigating to home");
      Get.offAllNamed('/home');
    } else {
      print("Login failed: $result");
      
      // Show simple error message
      _showLoginErrorDialog("Invalid Credentials");
    }
  }
  
  void _showLoginErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                spreadRadius: 5,
          ),
        ],
      ),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFB8C100).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Color(0xFFB8C100),
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  foreground: Paint()
                    ..shader = const LinearGradient(
                      colors: [
                        Color(0xFFF3F717),
                        Color(0xFF898B10),
                        Color(0xFF52530D),
                      ],
                    ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
                ),
        ),
              const SizedBox(height: 20),
              ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB8C100),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  elevation: 0,
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
          ),
        ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Responsive Image Banner
              Container(
                width: double.infinity,
                height: screenHeight * 0.3,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/sakshi.jpeg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.07),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: screenHeight * 0.05),

                    // ✅ Gradient Heading
                    ShaderMask(
                      shaderCallback: (bounds) {
                        return const LinearGradient(
                          colors: [
                            Color.fromARGB(255, 187, 190, 39),
                            Color(0xFF898B10),
                            Color(0xFF52530D),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds);
                      },
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "Let's ",
                              style: TextStyle(
                                fontSize: screenWidth * 0.07,
                                fontFamily: "Lato",
                                fontWeight: FontWeight.normal,
                                color: Colors.white,
                              ),
                            ),
                            TextSpan(
                              text: "Sign In",
                              style: TextStyle(
                                fontSize: screenWidth * 0.07,
                                fontFamily: "Lato",
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F4C6B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.02),

                    Text(
                      "Enter your credentials to continue",
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        color: Colors.grey,
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.03),

                    // ✅ Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.email_outlined,
                            color: Color(0xFF988A44)),
                        labelText: "Email",
                        filled: true,
                        fillColor: const Color(0xFFF5F4F8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(7),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.02,
                          horizontal: screenWidth * 0.04,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: screenHeight * 0.02),

                    // ✅ Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline,
                            color: Color(0xFF988A44)),
                        labelText: "Password",
                        filled: true,
                        fillColor: const Color(0xFFF5F4F8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(7),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.02,
                          horizontal: screenWidth * 0.04,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: const Color(0xFF988A44),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: screenHeight * 0.015),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Get.toNamed('/forgot-password'),
                        child: Text(
                          "Forgot Password?",
                          style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.03),

                    // ✅ Login Button
                    Center(
                      child: Obx(() => Container(
                            width: screenWidth * 0.7,
                            height: screenHeight * 0.07,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFF3F717),
                                  Color(0xFF898B10),
                                  Color(0xFF52530D),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: TextButton(
                              onPressed: _authController.isLoading.value
                                  ? null
                                  : _handleLogin,
                              child: _authController.isLoading.value
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : Text(
                                      "Login",
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.05,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          )),
                    ),

                    SizedBox(height: screenHeight * 0.025),

                    // ✅ OR Separator
                    const ORSeparator(),

                    SizedBox(height: screenHeight * 0.02),

                    // ✅ Google Sign-In Button
                    Center(
                      child: Container(
                        width: screenWidth * 0.7,
                        height: screenHeight * 0.07,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              spreadRadius: 2,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextButton(
                          onPressed: _handleGoogleSignIn,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/google_icon.png',
                                width: 24,
                                height: 24,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "Sign In with Google",
                                style: TextStyle(
                                  fontSize: screenWidth * 0.045,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1F4C6B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.025),

                    // ✅ Register Option
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: TextStyle(fontSize: screenWidth * 0.04),
                          ),
                          TextButton(
                            onPressed: () => Get.toNamed('/signup'),
                            child: const Text(
                              "Register",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

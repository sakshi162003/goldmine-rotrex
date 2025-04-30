import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  _EmailVerificationScreenState createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  List<TextEditingController> otpControllers =
      List.generate(4, (index) => TextEditingController());
  int countdown = 30;
  late Timer timer;
  String correctOTP = "1234"; // Mock OTP
  late String userEmail;
  bool isLoading = false;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    final Map<String, dynamic>? args = Get.arguments;
    userEmail = args?['email'] ?? "your email";
    startTimer();
    sendOTP(); // Send OTP initially
  }

  void startTimer() {
    countdown = 30;
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (countdown > 0) {
        setState(() {
          countdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void sendOTP() {
    correctOTP = generateOTP(); // Generate new OTP
    print("New OTP: $correctOTP"); // Simulating OTP sent via backend
    // TODO: Integrate with backend API to send OTP to the user's email
  }

  String generateOTP() {
    Random random = Random();
    return (1000 + random.nextInt(9000)).toString(); // Generates a 4-digit OTP
  }

  void resendOTP() {
    setState(() {
      startTimer(); // Restart timer
      sendOTP(); // Send new OTP
    });
  }

  void verifyOTP() {
    String enteredOTP = otpControllers.map((e) => e.text).join();
    if (enteredOTP == correctOTP) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("OTP Verified Successfully!")),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Invalid OTP"),
          content: Text("The entered OTP is incorrect. Please try again."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  void checkVerification() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Try to sign in to check if email is verified
      await supabase.auth.signInWithPassword(
        email: userEmail,
        password: Get.arguments?['password'] ?? '',
      );

      // If we get here without error, user is verified
      Get.snackbar(
        'Verified',
        'Your email has been verified!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );

      // Redirect to home
      Future.delayed(Duration(seconds: 2), () {
        Get.offAllNamed('/home');
      });
    } catch (e) {
      // Show error message if verification failed
      if (e.toString().contains('Email not confirmed')) {
        Get.snackbar(
          'Not Verified',
          'Please check your email and click the verification link',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to check verification: ${e.toString()}',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void resendVerification() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Try to resend verification email
      await supabase.auth.resend(
        type: OtpType.signup,
        email: userEmail,
      );

      Get.snackbar(
        'Email Sent',
        'Verification email has been resent',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to resend verification email: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    timer.cancel();
    for (var controller in otpControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.offAllNamed('/login'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.mail_outline, size: 80, color: const Color(0xFF988A44)),
            SizedBox(height: 20),
            Text(
              "Verify Your Email",
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            SizedBox(height: 20),
            Text("We've sent a verification link to:",
                style: TextStyle(color: Colors.black54, fontSize: 16)),
            SizedBox(height: 10),
            Text(userEmail,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.black, fontSize: 18)),
            SizedBox(height: 30),
            Text(
              "Please check your email inbox and click the verification link to confirm your account.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 16),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: isLoading ? null : checkVerification,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF988A44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                minimumSize: Size(double.infinity, 50),
              ),
              child: isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text("I've Verified My Email",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
            ),
            SizedBox(height: 20),
            TextButton(
              onPressed: isLoading ? null : resendVerification,
              child: Text(
                "Resend Verification Email",
                style: TextStyle(
                  color: const Color(0xFF988A44),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 20),
            TextButton(
              onPressed: () => Get.offAllNamed('/login'),
              child: Text(
                "Back to Login",
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

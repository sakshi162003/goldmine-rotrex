import 'package:flutter/material.dart';

class RegisterLink extends StatelessWidget {
  const RegisterLink({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: GestureDetector(
        onTap: () {},
        child: const Text(
          "Don't have an account? Register",
          style: TextStyle(color: Colors.blue, fontSize: 14),
        ),
      ),
    );
  }
}

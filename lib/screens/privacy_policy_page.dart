import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Privacy Policy",
          style: TextStyle(color: Color(0xFF7C8500), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF7C8500)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF7C8500)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Privacy Policy",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF7C8500)),
              ),
              const SizedBox(height: 10),
              _policySection("Data Collection",
                  "We collect user information like name, email, and profile details to improve the app experience."),
              _policySection("Usage of Information",
                  "Your personal data is used for authentication, personalization, and communication."),
              _policySection("Security Measures",
                  "User data is encrypted and securely stored with access restricted to authorized personnel."),
              _policySection("User Rights",
                  "Users can update or delete their personal information and request data removal."),
              _policySection("Third-Party Services",
                  "The app may use third-party APIs for services like payments or analytics."),
              _policySection("Policy Updates",
                  "Any changes to the privacy policy will be communicated through the app."),
            ],
          ),
        ),
      ),
    );
  }

  Widget _policySection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 5),
          Text(content, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }
}


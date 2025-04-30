import 'package:flutter/material.dart';

class FAQSupportPage extends StatefulWidget {
  const FAQSupportPage({super.key});

  @override
  _FAQSupportPageState createState() => _FAQSupportPageState();
}

class _FAQSupportPageState extends State<FAQSupportPage> {
  final List<Map<String, dynamic>> _faqList = [
    {
      "question": "What is Rise Real Estate?",
      "answer": "Rise Real Estate is a platform that helps you find the best properties for rent and sale.",
      "isExpanded": false,
    },
    {
      "question": "Why choose to buy in Rise?",
      "answer": "We provide verified listings, easy transactions, and top-notch customer service.",
      "isExpanded": false,
    },
    {
      "question": "How do I list my property?",
      "answer": "You can list your property through our app by navigating to the 'Post Property' section.",
      "isExpanded": false,
    },
    {
      "question": "How do I contact customer support?",
      "answer": "You can contact us via phone, email, or live chat support available in the app.",
      "isExpanded": false,
    },
  ];

  void _toggleFAQ(int index) {
    setState(() {
      _faqList[index]["isExpanded"] = !_faqList[index]["isExpanded"];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "FAQ & Support",
          style: TextStyle(color: Color(0xFF7C8500), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Find answers to your problems quickly.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 20),

              // Contact Options
              _buildHelpOption(Icons.phone, "Contact Us", Colors.green, () {}),
              _buildHelpOption(Icons.email, "Email Support", Colors.blue, () {}),
              _buildHelpOption(Icons.article, "Terms of Service", Colors.orange, () {}),
              _buildHelpOption(Icons.language, "Visit Our Website", Colors.purple, () {}),
              
              const SizedBox(height: 20),

              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: "Try searching 'how to'",
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(15),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // FAQ Section
              const Text(
                "Frequently Asked Questions",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF7C8500)),
              ),
              const SizedBox(height: 10),

              ..._faqList.asMap().entries.map((entry) {
                int index = entry.key;
                Map<String, dynamic> faqItem = entry.value;
                return _buildExpandableFAQ(index, faqItem["question"], faqItem["answer"], faqItem["isExpanded"]);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpOption(IconData icon, String text, Color iconColor, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onPressed,
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: iconColor.withOpacity(0.1),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 10),
            Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableFAQ(int index, String title, String content, bool isExpanded) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _toggleFAQ(index),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.black),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(content, style: const TextStyle(color: Colors.grey)),
          ),
      ],
    );
  }
}

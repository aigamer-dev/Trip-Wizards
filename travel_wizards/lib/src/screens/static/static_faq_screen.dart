import 'package:flutter/material.dart';

class StaticFaqScreen extends StatelessWidget {
  const StaticFaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FAQ')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Frequently Asked Questions\n\nQ: How do I plan a trip?\nA: Use the Add Trip button and follow the steps.',
        ),
      ),
    );
  }
}

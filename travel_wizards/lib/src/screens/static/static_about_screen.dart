import 'package:flutter/material.dart';

class StaticAboutScreen extends StatelessWidget {
  const StaticAboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Text(
        'Travel Wizards\n\nVersion 1.0.0\n\nA cross-platform travel planning app built with Flutter.',
      ),
    );
  }
}

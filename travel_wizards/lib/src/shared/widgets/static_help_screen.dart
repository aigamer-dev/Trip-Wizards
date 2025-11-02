import 'package:flutter/material.dart';

class StaticHelpScreen extends StatelessWidget {
  const StaticHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Help & Support\n\nCommon troubleshooting steps and contact information.',
        ),
      ),
    );
  }
}

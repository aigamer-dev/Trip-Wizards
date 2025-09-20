import 'package:flutter/material.dart';

class StaticTutorialsScreen extends StatelessWidget {
  const StaticTutorialsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tutorials')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Tutorials\n\nShort guides on using Explore, Plan Trip, and Brainstorm.',
        ),
      ),
    );
  }
}

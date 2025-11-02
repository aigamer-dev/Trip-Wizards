import 'package:flutter/material.dart';

class StaticFeedbackScreen extends StatelessWidget {
  const StaticFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feedback')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We\'d love your feedback',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text('Email: travel.wizards.feedback@gmail.com'),
            const SizedBox(height: 8),
            const Text('GitHub Issues: open an issue in the repository'),
            const SizedBox(height: 16),
            const Text(
              'Please avoid sharing sensitive personal data. For bug reports, include steps to reproduce, expected behavior, and screenshots if possible.',
            ),
          ],
        ),
      ),
    );
  }
}

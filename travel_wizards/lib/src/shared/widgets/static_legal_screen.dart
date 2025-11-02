import 'package:flutter/material.dart';

class StaticLegalScreen extends StatelessWidget {
  const StaticLegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Legal')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Legal', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'Terms of Service and Privacy Policy are required for distribution on the Play Store and public web hosting.',
            ),
            const SizedBox(height: 12),
            const Text('Host your documents and update the links below:'),
            const SizedBox(height: 8),
            const SelectableText(
              '• Terms of Service: https://your-domain.example/terms',
            ),
            const SelectableText(
              '• Privacy Policy: https://your-domain.example/privacy',
            ),
            const SizedBox(height: 16),
            const Text(
              'Until hosted, keep this page accessible for internal testing only.',
            ),
          ],
        ),
      ),
    );
  }
}

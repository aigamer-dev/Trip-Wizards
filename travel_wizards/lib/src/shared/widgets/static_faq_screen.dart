import 'package:flutter/material.dart';

class StaticFaqScreen extends StatelessWidget {
  const StaticFaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('FAQ')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Frequently Asked Questions',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Q: How do I plan a trip?\nA: Use the Add Trip button and follow the guided steps to build your itinerary.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          Text(
            'Need to change the name, date of birth, gender, email, or home location on your account? Those details are managed by your sign-in provider. Send a request to support@travelwizards.com and our concierge team will help you update them safely.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 64),
            const SizedBox(height: 16),
            const Text('We couldn\'t find that page.'),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.goNamed('home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}

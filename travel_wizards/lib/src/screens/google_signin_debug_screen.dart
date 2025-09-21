import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

/// Debug screen to test and diagnose Google Sign-In issues
class GoogleSignInDebugScreen extends StatefulWidget {
  const GoogleSignInDebugScreen({super.key});

  @override
  State<GoogleSignInDebugScreen> createState() =>
      _GoogleSignInDebugScreenState();
}

class _GoogleSignInDebugScreenState extends State<GoogleSignInDebugScreen> {
  bool _isLoading = false;
  String? _lastError;
  String? _lastResult;
  Map<String, dynamic>? _diagnosis;

  @override
  void initState() {
    super.initState();
    _runDiagnosis();
  }

  Future<void> _runDiagnosis() async {
    try {
      final diagnosis = await AuthService.instance.diagnoseGoogleSignInConfig();
      setState(() {
        _diagnosis = diagnosis;
      });
    } catch (e) {
      setState(() {
        _lastError = 'Diagnosis failed: $e';
      });
    }
  }

  Future<void> _testGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _lastError = null;
      _lastResult = null;
    });

    try {
      final result = await AuthService.instance.signInWithGoogle();
      setState(() {
        _lastResult = result != null
            ? 'Success: ${result.user.email}'
            : 'Sign-in cancelled';
      });
    } catch (e) {
      setState(() {
        _lastError = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Google Sign-In Debug')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current user status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current User Status',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<User?>(
                      stream: FirebaseAuth.instance.authStateChanges(),
                      builder: (context, snapshot) {
                        final user = snapshot.data;
                        return Text(
                          user != null
                              ? 'Signed in: ${user.email} (${user.uid})'
                              : 'Not signed in',
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Diagnosis information
            if (_diagnosis != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Configuration Diagnosis',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      ..._diagnosis!.entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text('${entry.key}: ${entry.value}'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Test button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _testGoogleSignIn,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Test Google Sign-In'),
              ),
            ),

            const SizedBox(height: 16),

            // Results
            if (_lastResult != null) ...[
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Success',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(color: Colors.green),
                      ),
                      const SizedBox(height: 8),
                      Text(_lastResult!),
                    ],
                  ),
                ),
              ),
            ],

            if (_lastError != null) ...[
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Error',
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(color: Colors.red),
                      ),
                      const SizedBox(height: 8),
                      Text(_lastError!),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Common solutions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Common Solutions',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Add localhost to Firebase Auth → Settings → Authorized domains\n'
                      '2. Check Google OAuth client configuration\n'
                      '3. Verify Firebase project settings\n'
                      '4. Check browser console for detailed errors\n'
                      '5. Ensure Google Sign-In is enabled in Firebase Console',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_wizards/src/shared/widgets/spacing.dart';
import 'package:travel_wizards/src/shared/services/auth_service.dart';

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isSignIn = true;
  bool _isPasswordVisible = false;
  bool _isBusy = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_isSignIn ? 'Sign In' : 'Sign Up')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isDesktop = Breakpoints.isDesktop(width);
          final isTablet = Breakpoints.isTablet(width);
          final maxWidth = isDesktop
              ? 560.0
              : (isTablet ? 480.0 : double.infinity);
          final padding = isDesktop
              ? Insets.allXl
              : (isTablet ? Insets.allLg : Insets.allMd);
          final buttonHeight = isDesktop ? 56.0 : (isTablet ? 52.0 : 48.0);

          return Center(
            child: Padding(
              padding: padding,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!_isSignIn)
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            border: OutlineInputBorder(),
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => (v != null && v.trim().isNotEmpty)
                              ? null
                              : 'Please enter your name',
                        ),
                      if (!_isSignIn) const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => v != null && v.contains('@')
                            ? null
                            : 'Enter a valid email',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                              () => _isPasswordVisible = !_isPasswordVisible,
                            ),
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                        ),
                        obscureText: !_isPasswordVisible,
                        validator: (v) => v != null && v.length >= 6
                            ? null
                            : 'Password too short',
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: buttonHeight,
                        child: FilledButton(
                          onPressed: _isBusy
                              ? null
                              : () async {
                                  if (_formKey.currentState?.validate() !=
                                      true) {
                                    return;
                                  }
                                  setState(() => _isBusy = true);
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  final router = GoRouter.of(context);
                                  final theme = Theme.of(context);
                                  try {
                                    if (_isSignIn) {
                                      await AuthService.instance
                                          .signInWithEmail(
                                            email: _emailController.text.trim(),
                                            password: _passwordController.text,
                                          );
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text('Signed in'),
                                        ),
                                      );
                                    } else {
                                      await AuthService.instance
                                          .signUpWithEmail(
                                            email: _emailController.text.trim(),
                                            password: _passwordController.text,
                                            name: _nameController.text.trim(),
                                          );
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text('Account created'),
                                        ),
                                      );
                                    }
                                    if (!mounted) return;
                                    router.go('/');
                                  } on Exception {
                                    if (!mounted) return;
                                    // Show error using captured messenger instead of ErrorHandlingService
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Authentication failed. Please check your email and password.',
                                        ),
                                        backgroundColor:
                                            theme.colorScheme.error,
                                      ),
                                    );
                                  } finally {
                                    if (mounted) {
                                      setState(() => _isBusy = false);
                                    }
                                  }
                                },
                          child: _isBusy
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(_isSignIn ? 'Sign In' : 'Sign Up'),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _isSignIn = !_isSignIn),
                        child: Text(
                          _isSignIn
                              ? "Don't have an account? Sign Up"
                              : 'Already have an account? Sign In',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This is a UI-only demo. No account will be created.',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

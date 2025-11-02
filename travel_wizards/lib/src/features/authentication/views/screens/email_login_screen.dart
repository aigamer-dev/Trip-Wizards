import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:travel_wizards/src/shared/services/auth_service.dart';
import 'package:travel_wizards/src/shared/widgets/travel_components/travel_components.dart';

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isSignIn = true;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isBusy = false;
  String? _passwordStrength;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String _checkPasswordStrength(String password) {
    if (password.isEmpty) return '';
    if (password.length < 6) return 'Too short';
    if (password.length < 8) return 'Weak';

    bool hasUpper = password.contains(RegExp(r'[A-Z]'));
    bool hasLower = password.contains(RegExp(r'[a-z]'));
    bool hasDigit = password.contains(RegExp(r'[0-9]'));
    bool hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    int strength = [
      hasUpper,
      hasLower,
      hasDigit,
      hasSpecial,
    ].where((e) => e).length;

    if (strength < 2) return 'Weak';
    if (strength < 3) return 'Medium';
    return 'Strong';
  }

  String _getErrorMessage(dynamic e) {
    if (e is FirebaseAuthException) {
      // Provide specific error messages based on Firebase error codes
      switch (e.code) {
        case 'user-not-found':
          return 'No account found with this email.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'email-already-in-use':
          return 'An account with this email already exists.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'weak-password':
          return 'Password is too weak. Use a stronger password.';
        case 'network-request-failed':
          return 'Network error. Please check your connection.';
        default:
          return 'Authentication failed: ${e.message}';
      }
    }
    return 'An unexpected error occurred: $e';
  }

  Color _getPasswordStrengthColor(String strength, ColorScheme colorScheme) {
    switch (strength) {
      case 'Strong':
        return Colors.green;
      case 'Medium':
        return Colors.orange;
      case 'Weak':
      case 'Too short':
        return colorScheme.error;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                          decoration: const InputDecoration(labelText: 'Name'),
                          textCapitalization: TextCapitalization.words,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Name is required';
                            }
                            return null;
                          },
                        ),
                      if (!_isSignIn) const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email is required';
                          }
                          // Basic email validation
                          final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                          if (!emailRegex.hasMatch(value.trim())) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          suffixIcon: Semantics(
                            label: _isPasswordVisible
                                ? 'Hide password'
                                : 'Show password',
                            button: true,
                            child: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                          ),
                        ),
                        obscureText: !_isPasswordVisible,
                        onChanged: !_isSignIn
                            ? (value) {
                                setState(() {
                                  _passwordStrength = _checkPasswordStrength(
                                    value,
                                  );
                                });
                              }
                            : null,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Password is required';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      if (!_isSignIn && _passwordStrength != null) ...[
                        const SizedBox(height: 8),
                        Semantics(
                          label: 'Password strength: $_passwordStrength',
                          liveRegion: true,
                          child: Text(
                            'Strength: $_passwordStrength',
                            style: TextStyle(
                              color: _getPasswordStrengthColor(
                                _passwordStrength!,
                                Theme.of(context).colorScheme,
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (!_isSignIn) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmPasswordController,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            suffixIcon: Semantics(
                              label: _isConfirmPasswordVisible
                                  ? 'Hide confirm password'
                                  : 'Show confirm password',
                              button: true,
                              child: IconButton(
                                icon: Icon(
                                  _isConfirmPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isConfirmPasswordVisible =
                                        !_isConfirmPasswordVisible;
                                  });
                                },
                              ),
                            ),
                          ),
                          obscureText: !_isConfirmPasswordVisible,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Confirm password is required';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 24),
                      Semantics(
                        button: true,
                        label: _isSignIn
                            ? 'Sign in with email and password'
                            : 'Create new account with email and password',
                        child: PrimaryButton(
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
                                      router.go('/');
                                    } else {
                                      await AuthService.instance
                                          .signUpWithEmail(
                                            email: _emailController.text.trim(),
                                            password: _passwordController.text,
                                            name: _nameController.text.trim(),
                                          );

                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Account created successfully!',
                                          ),
                                        ),
                                      );

                                      router.go('/');
                                    }
                                  } catch (e) {
                                    final errorMessage = _getErrorMessage(e);

                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(errorMessage),
                                        backgroundColor:
                                            theme.colorScheme.error,
                                        duration: const Duration(seconds: 4),
                                        action: SnackBarAction(
                                          label: 'Dismiss',
                                          textColor: theme.colorScheme.onError,
                                          onPressed: () {},
                                        ),
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
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => setState(() {
                          _isSignIn = !_isSignIn;
                          _passwordStrength = null;
                          _formKey.currentState?.reset();
                        }),
                        child: Text(
                          _isSignIn
                              ? "Don't have an account? Sign Up"
                              : 'Already have an account? Sign In',
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

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_wizards/src/shared/services/auth_service.dart';
import 'package:travel_wizards/src/features/authentication/views/controllers/auth_controller.dart';
import 'package:travel_wizards/src/shared/widgets/travel_components/travel_components.dart';

class _EmailPasswordCredentials {
  final String email;
  final String password;

  const _EmailPasswordCredentials({
    required this.email,
    required this.password,
  });
}

class LoginLandingScreen extends StatefulWidget {
  const LoginLandingScreen({super.key});

  @override
  State<LoginLandingScreen> createState() => _LoginLandingScreenState();
}

class _LoginLandingScreenState extends State<LoginLandingScreen> {
  bool _isSigningIn = false;
  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    _completePendingRedirect();
    // If user is already signed in, navigate away immediately
    final current = FirebaseAuth.instance.currentUser;
    if (current != null) {
      debugPrint(
        '🚪 Login screen opened but already signed in as ${current.uid}, navigating to /',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/');
      });
    }

    // If auth state changes (e.g., after redirect), navigate away from login
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      debugPrint(
        '🔔 authStateChanges in LoginLandingScreen: user=${user?.uid ?? 'null'}',
      );
      if (!mounted) return;
      if (user != null) {
        // Let GoRouter's redirect logic choose target (home/onboarding)
        GoRouter.of(context).go('/');
      }
    });
  }

  Future<void> _completePendingRedirect() async {
    // After signInWithRedirect on web, this will resolve with a user.
    try {
      setState(() => _isSigningIn = true);
      // Prefer using authStateChanges to redirect; we just keep UI busy briefly.
      await Future.delayed(const Duration(milliseconds: 150));
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _showProviderMigrationDialog(
    BuildContext context, {
    required String email,
    required String existingProvider,
    required String newProvider,
    required VoidCallback onLinkAccounts,
    required VoidCallback onUseExisting,
    required VoidCallback onUseNew,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MigrationDialog(
        existingProvider: existingProvider,
        newProvider: newProvider,
        email: email,
        onLinkAccounts: onLinkAccounts,
        onUseExisting: onUseExisting,
        onUseNew: onUseNew,
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  Future<_EmailPasswordCredentials?> _showEmailPasswordDialog(
    BuildContext context,
  ) async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<_EmailPasswordCredentials>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Link Accounts'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter your existing email and password to link your Google account.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email address',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email is required';
                  }
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value)) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(context).pop(
                  _EmailPasswordCredentials(
                    email: emailController.text.trim(),
                    password: passwordController.text,
                  ),
                );
              }
            },
            child: const Text('Link Accounts'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLinkGoogleToExisting(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    // Show email/password dialog to get credentials for linking
    final credentials = await _showEmailPasswordDialog(context);
    if (credentials == null) return; // User cancelled

    try {
      setState(() => _isSigningIn = true);
      final success = await AuthController.instance.completeProviderMigration(
        credentials.email,
        credentials.password,
      );

      if (success) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Accounts linked successfully!')),
        );

        // Show undo option
        await _showUndoDialog(
          context,
          'linked',
          AuthController.instance.userId!,
        );

        if (!mounted) return;
        router.go('/');
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Failed to link accounts. Please check your credentials.',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to link accounts: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSigningIn = false);
      }
    }
  }

  Future<void> _handleMigrateEmailToGoogle(
    BuildContext context, {
    required String existingEmail,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    try {
      setState(() => _isSigningIn = true);
      final currentUser = await AuthService.instance
          .migrateEmailAccountToGoogle(existingEmail: existingEmail);

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Account migrated to Google successfully!'),
        ),
      );

      // Show undo option
      await _showUndoDialog(context, 'google', currentUser.user.uid);

      if (!mounted) return;
      router.go('/');
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to migrate account: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSigningIn = false);
      }
    }
  }

  Future<void> _showUndoDialog(
    BuildContext context,
    String previousProvider,
    String userId,
  ) async {
    const undoWindow = Duration(seconds: 30);
    final startTime = DateTime.now();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return UndoMigrationDialog(
          previousProvider: previousProvider,
          userId: userId,
          undoWindow: undoWindow,
          startTime: startTime,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = Breakpoints.isMobile(width);
        final isTablet = Breakpoints.isTablet(width);
        final isDesktop = Breakpoints.isDesktop(width);

        // Responsive configurations
        final maxWidth = isDesktop
            ? 560.0
            : (isTablet ? 480.0 : double.infinity);
        final viewportFraction = isMobile ? 0.82 : (isTablet ? 0.7 : 0.6);
        final heightFactor = isMobile ? 0.28 : (isTablet ? 0.32 : 0.35);
        final padding = isDesktop
            ? Insets.allXl
            : (isTablet ? Insets.allLg : Insets.allMd);

        final images = [
          Icons.flight_takeoff_rounded,
          Icons.terrain_rounded,
          Icons.beach_access_rounded,
          Icons.landscape_rounded,
        ];

        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: padding,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height:
                              MediaQuery.of(context).size.height * heightFactor,
                          child: PageView.builder(
                            controller: PageController(
                              viewportFraction: viewportFraction,
                            ),
                            itemBuilder: (context, index) {
                              final icon = images[index % images.length];
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    colors: [
                                      theme.colorScheme.primaryContainer,
                                      theme.colorScheme.tertiaryContainer,
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    icon,
                                    size: 96,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              'Welcome to Travel Wizards',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Gaps.h16,
                            Text(
                              'Plan your trips effortlessly with AI-powered suggestions!',
                              style: theme.textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            Gaps.h24,
                            if (_isSigningIn)
                              const CircularProgressIndicator()
                            else
                              Column(
                                children: [
                                  PrimaryButton(
                                    onPressed: () async {
                                      if (_isSigningIn) return;
                                      setState(() => _isSigningIn = true);
                                      final messenger = ScaffoldMessenger.of(
                                        context,
                                      );
                                      final router = GoRouter.of(context);
                                      try {
                                        if (kIsWeb) {
                                          // Use redirect-only on web to avoid popup blockers/cookie issues
                                          await AuthService.instance
                                              .signInWithGoogleRedirect();
                                          messenger.showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Redirecting to Google for sign-in...',
                                              ),
                                            ),
                                          );
                                          return; // auth listener will navigate after redirect completes
                                        }

                                        final outcome = await AuthController
                                            .instance
                                            .signInWithGoogle();

                                        switch (outcome) {
                                          case AuthOutcome.success:
                                            final user = AuthController
                                                .instance
                                                .currentUser;
                                            if (user != null) {
                                              final String name =
                                                  user.displayName ?? 'User';
                                              final String email =
                                                  user.email ?? '';
                                              messenger.showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Welcome $name${email.isNotEmpty ? ' <$email>' : ''}',
                                                  ),
                                                ),
                                              );
                                              router.goNamed('home');
                                            }
                                            break;
                                          case AuthOutcome.needsMigration:
                                            // Handle provider conflict - show migration dialog
                                            final pendingEmail = AuthController
                                                .instance
                                                .pendingMigrationEmail;
                                            await _showProviderMigrationDialog(
                                              context,
                                              email:
                                                  pendingEmail ?? 'your email',
                                              existingProvider: 'Email',
                                              newProvider: 'Google',
                                              onLinkAccounts: () async {
                                                Navigator.of(context).pop();
                                                await _handleLinkGoogleToExisting(
                                                  context,
                                                );
                                              },
                                              onUseExisting: () {
                                                Navigator.of(context).pop();
                                                messenger.showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Please sign in with email instead.',
                                                    ),
                                                  ),
                                                );
                                              },
                                              onUseNew: () async {
                                                Navigator.of(context).pop();
                                                await _handleMigrateEmailToGoogle(
                                                  context,
                                                  existingEmail:
                                                      pendingEmail ?? '',
                                                );
                                              },
                                            );
                                            break;
                                          case AuthOutcome.failed:
                                            messenger.showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Google Sign-In failed',
                                                ),
                                              ),
                                            );
                                            break;
                                        }
                                      } catch (e) {
                                        if (e is FirebaseAuthException &&
                                            e.code ==
                                                'account-exists-with-different-credential') {
                                          // Handle provider conflict - show migration dialog
                                          await _showProviderMigrationDialog(
                                            context,
                                            email: e.email ?? 'your email',
                                            existingProvider: 'Email',
                                            newProvider: 'Google',
                                            onLinkAccounts: () async {
                                              Navigator.of(context).pop();
                                              await _handleLinkGoogleToExisting(
                                                context,
                                              );
                                            },
                                            onUseExisting: () {
                                              Navigator.of(context).pop();
                                              messenger.showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Please sign in with email instead.',
                                                  ),
                                                ),
                                              );
                                            },
                                            onUseNew: () async {
                                              Navigator.of(context).pop();
                                              await _handleMigrateEmailToGoogle(
                                                context,
                                                existingEmail: e.email ?? '',
                                              );
                                            },
                                          );
                                        } else {
                                          messenger.showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Google Sign-In failed: $e',
                                              ),
                                            ),
                                          );
                                        }
                                      } finally {
                                        if (mounted) {
                                          setState(() => _isSigningIn = false);
                                        }
                                      }
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.login_rounded),
                                        SizedBox(width: 8),
                                        Text('Continue with Google'),
                                      ],
                                    ),
                                  ),
                                  Gaps.h16,
                                  SecondaryButton(
                                    onPressed: () {
                                      context.pushNamed('email_login');
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.email_rounded),
                                        SizedBox(width: 8),
                                        Text('Continue with Email'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        Text(
                          'By signing in, you agree to our Terms of Service and Privacy Policy.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

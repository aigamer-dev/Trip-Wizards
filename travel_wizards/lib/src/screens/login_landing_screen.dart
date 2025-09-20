import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_wizards/src/common/ui/spacing.dart';
import 'package:travel_wizards/src/services/auth_service.dart';

class LoginLandingScreen extends StatefulWidget {
  const LoginLandingScreen({super.key});

  @override
  State<LoginLandingScreen> createState() => _LoginLandingScreenState();
}

class _LoginLandingScreenState extends State<LoginLandingScreen> {
  bool _isSigningIn = false;

  @override
  void initState() {
    super.initState();
    _completePendingRedirect();
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
        final buttonHeight = isDesktop ? 56.0 : (isTablet ? 52.0 : 48.0);

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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    mainAxisSize: MainAxisSize.max,
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
                              margin: const EdgeInsets.symmetric(horizontal: 8),
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
                                SizedBox(
                                  width: double.infinity,
                                  height: buttonHeight,
                                  child: FilledButton.icon(
                                    icon: const Icon(Icons.login_rounded),
                                    onPressed: () async {
                                      if (_isSigningIn) return;
                                      setState(() => _isSigningIn = true);
                                      final messenger = ScaffoldMessenger.of(
                                        context,
                                      );
                                      final router = GoRouter.of(context);
                                      try {
                                        final result = await AuthService
                                            .instance
                                            .signInWithGoogle();
                                        if (result == null) {
                                          messenger.showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Sign-in cancelled',
                                              ),
                                            ),
                                          );
                                        } else {
                                          final name =
                                              result.profile?['name'] ??
                                              result.user.displayName ??
                                              'User';
                                          final email =
                                              result.profile?['email'] ??
                                              result.user.email ??
                                              '';
                                          messenger.showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Welcome $name${email.isNotEmpty ? ' <$email>' : ''}',
                                              ),
                                            ),
                                          );
                                          router.go('/');
                                        }
                                      } catch (e) {
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Google Sign-In failed: $e',
                                            ),
                                          ),
                                        );
                                      } finally {
                                        if (mounted) {
                                          setState(() => _isSigningIn = false);
                                        }
                                      }
                                    },
                                    label: const Text('Continue with Google'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor:
                                          theme.colorScheme.surface,
                                      foregroundColor:
                                          theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                Gaps.h16,
                                SizedBox(
                                  width: double.infinity,
                                  height: buttonHeight,
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.email_rounded),
                                    onPressed: () {
                                      context.pushNamed('email_login');
                                    },
                                    label: const Text('Continue with Email'),
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
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../app/theme.dart';

/// Get the appropriate transition duration based on reduced motion setting
Duration _getTransitionDuration(BuildContext context, int defaultDuration) {
  final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
  return themeProvider.reducedMotion
      ? const Duration(milliseconds: 0)
      : Duration(milliseconds: defaultDuration);
}

Page<void> fadePage(Widget child, [int duration = 200]) =>
    CustomTransitionPage<void>(
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final effectiveDuration = _getTransitionDuration(context, duration);
        if (effectiveDuration.inMilliseconds == 0) {
          return child; // No animation
        }
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: child,
        );
      },
      transitionDuration: Duration(milliseconds: duration),
    );

Page<void> slidePage(Widget child, String direction, [int duration = 200]) =>
    CustomTransitionPage<void>(
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final effectiveDuration = _getTransitionDuration(context, duration);
        if (effectiveDuration.inMilliseconds == 0) {
          return child; // No animation
        }
        final offsetAnimation = Tween<Offset>(
          begin: direction == 'left'
              ? const Offset(-1.0, 0.0)
              : direction == 'right'
              ? const Offset(1.0, 0.0)
              : direction == 'up'
              ? const Offset(0.0, -1.0)
              : const Offset(0.0, 1.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut));
        return SlideTransition(position: offsetAnimation, child: child);
      },
      transitionDuration: Duration(milliseconds: duration),
    );

Page<void> expandPage(Widget child, [int duration = 200]) =>
    CustomTransitionPage<void>(
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final effectiveDuration = _getTransitionDuration(context, duration);
        if (effectiveDuration.inMilliseconds == 0) {
          return child; // No animation
        }
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: child,
        );
      },
      transitionDuration: Duration(milliseconds: duration),
    );

Page<void> collapsePage(Widget child, [int duration = 200]) =>
    CustomTransitionPage<void>(
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final effectiveDuration = _getTransitionDuration(context, duration);
        if (effectiveDuration.inMilliseconds == 0) {
          return child; // No animation
        }
        return SizeTransition(
          sizeFactor: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ),
          axisAlignment: 0.0,
          child: child,
        );
      },
      transitionDuration: Duration(milliseconds: duration),
    );

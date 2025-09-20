import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

Page<void> fadePage(Widget child, [int duration = 200]) =>
    CustomTransitionPage<void>(
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
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

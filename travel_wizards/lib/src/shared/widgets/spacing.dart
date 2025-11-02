import 'package:flutter/widgets.dart';

/// Design system spacing and responsive breakpoints.
class Insets {
  // Base grid: 8dp multiples
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  // Common EdgeInsets presets
  static const EdgeInsets allSm = EdgeInsets.all(sm);
  static const EdgeInsets allMd = EdgeInsets.all(md);
  static const EdgeInsets allLg = EdgeInsets.all(lg);
  static const EdgeInsets allXl = EdgeInsets.all(xl);

  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: lg);

  static EdgeInsets h(double value) => EdgeInsets.symmetric(horizontal: value);
  static EdgeInsets v(double value) => EdgeInsets.symmetric(vertical: value);
}

/// Common gaps for padding between widgets.
class VGap extends StatelessWidget {
  final double size;
  const VGap(this.size, {super.key});
  @override
  Widget build(BuildContext context) => SizedBox(height: size);
}

class HGap extends StatelessWidget {
  final double size;
  const HGap(this.size, {super.key});
  @override
  Widget build(BuildContext context) => SizedBox(width: size);
}

class Gaps {
  // Square gaps (both width & height)
  static const SizedBox gap4 = SizedBox(width: 4, height: 4);
  static const SizedBox gap8 = SizedBox(width: 8, height: 8);
  static const SizedBox gap16 = SizedBox(width: 16, height: 16);
  static const SizedBox gap24 = SizedBox(width: 24, height: 24);
  static const SizedBox gap32 = SizedBox(width: 32, height: 32);
  static const SizedBox gap48 = SizedBox(width: 48, height: 48);
  static const SizedBox gap64 = SizedBox(width: 64, height: 64);

  // Horizontal-only gaps
  static const SizedBox w4 = SizedBox(width: 4);
  static const SizedBox w8 = SizedBox(width: 8);
  static const SizedBox w16 = SizedBox(width: 16);
  static const SizedBox w24 = SizedBox(width: 24);
  static const SizedBox w32 = SizedBox(width: 32);
  static const SizedBox w48 = SizedBox(width: 48);
  static const SizedBox w64 = SizedBox(width: 64);

  // Vertical-only gaps
  static const SizedBox h4 = SizedBox(height: 4);
  static const SizedBox h8 = SizedBox(height: 8);
  static const SizedBox h16 = SizedBox(height: 16);
  static const SizedBox h24 = SizedBox(height: 24);
  static const SizedBox h32 = SizedBox(height: 32);
  static const SizedBox h48 = SizedBox(height: 48);
  static const SizedBox h64 = SizedBox(height: 64);
}

/// Design system border radiuses
class Corners {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;

  static const BorderRadius smBorder = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdBorder = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgBorder = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlBorder = BorderRadius.all(Radius.circular(xl));
}

/// Responsive breakpoints (logical pixels).
class Breakpoints {
  static const double mobile = 600; // < 600 => mobile
  static const double tablet = 1024; // 600–1024 => tablet, >1024 => web/desktop

  static bool isMobile(double width) => width < mobile;
  static bool isTablet(double width) => width >= mobile && width <= tablet;
  static bool isDesktop(double width) => width > tablet;
}

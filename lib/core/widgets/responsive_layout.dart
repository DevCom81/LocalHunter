import 'package:flutter/material.dart';
import '../constants/app_spacing.dart';

class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    required this.desktop,
  });

  final Widget mobile;
  final Widget desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppSpacing.mobileBreakpoint) {
          return desktop;
        }
        return mobile;
      },
    );
  }
}

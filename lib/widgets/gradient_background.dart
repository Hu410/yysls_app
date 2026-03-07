import 'package:flutter/material.dart';

/// Legacy GradientBackground replaced by plain surface color.
/// Kept as a transparent wrapper during migration.
class GradientBackground extends StatelessWidget {
  final Widget child;
  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

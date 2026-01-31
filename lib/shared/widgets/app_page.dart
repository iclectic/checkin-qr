import 'package:flutter/material.dart';

import '../app_spacing.dart';

class AppPage extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const AppPage({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

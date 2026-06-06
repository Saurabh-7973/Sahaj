import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// Standard screen shell — SafeArea + consistent horizontal padding.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.leading,
    this.bottom,
    this.scrollable = false,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
  });

  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget? bottom;
  final bool scrollable;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: body);

    return Scaffold(
      appBar: title == null && leading == null && actions == null
          ? null
          : AppBar(
              title: title == null ? null : Text(title!),
              actions: actions,
              leading: leading,
            ),
      body: SafeArea(
        child: scrollable
            ? SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: content,
              )
            : content,
      ),
      bottomNavigationBar: bottom == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.sm,
                  AppSpacing.xl,
                  AppSpacing.lg,
                ),
                child: bottom,
              ),
            ),
    );
  }
}

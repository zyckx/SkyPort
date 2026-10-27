import 'package:flutter/material.dart' show CircularProgressIndicator;
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Small indeterminate progress indicator in the theme's muted colour.
class AppSpinner extends StatelessWidget {
  const AppSpinner({super.key, this.size = 16, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: color ?? ShadTheme.of(context).colorScheme.mutedForeground,
      ),
    );
  }
}

import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// A bordered card surface used for the main workspace regions.
class AppPanel extends StatelessWidget {
  const AppPanel({
    super.key,
    required this.child,
    this.muted = false,
    this.clip = false,
  });

  final Widget child;

  /// Uses the muted background, e.g. for side drawers.
  final bool muted;

  /// Clips [child] to the rounded corners.
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final colors = theme.colorScheme;
    return Container(
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: muted ? colors.muted.withValues(alpha: 0.5) : colors.card,
        borderRadius: theme.radius,
        border: Border.all(color: colors.border),
      ),
      child: child,
    );
  }
}

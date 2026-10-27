import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'app_tooltip.dart';

/// Compact ghost icon button with a required tooltip for discoverability.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 28,
    this.iconSize = 16,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = ShadTheme.of(context).colorScheme;
    return AppTooltip(
      message: tooltip,
      child: ShadIconButton.ghost(
        icon: Icon(icon, size: iconSize),
        foregroundColor: color ?? colors.mutedForeground,
        hoverForegroundColor: color ?? colors.foreground,
        width: size,
        height: size,
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        enabled: onPressed != null,
      ),
    );
  }
}

import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// A titled group of controls separated by hairlines.
class AppSection extends StatelessWidget {
  const AppSection({
    super.key,
    required this.title,
    required this.children,
    this.icon,
    this.trailing,
  });

  final String title;
  final List<Widget> children;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(
              left: 12,
              right: trailing == null ? 0 : 12,
              bottom: 8,
            ),
            child: Semantics(
              header: true,
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: colors.mutedForeground),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.small.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.foreground,
                      ),
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: trailing!,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              ShadSeparator.horizontal(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: colors.border,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// A tappable row with leading icon, title, optional subtitle and trailing.
class AppListTile extends StatefulWidget {
  const AppListTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  State<AppListTile> createState() => _AppListTileState();
}

class _AppListTileState extends State<AppListTile> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final colors = theme.colorScheme;
    final interactive = widget.onTap != null;
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(widget.icon, size: 16, color: colors.mutedForeground),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.title, style: theme.textTheme.small),
                if (widget.subtitle != null)
                  Text(
                    widget.subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.muted.copyWith(fontSize: 12),
                  ),
              ],
            ),
          ),
          if (widget.trailing != null) ...[
            const SizedBox(width: 8),
            widget.trailing!,
          ],
        ],
      ),
    );
    if (!interactive) return content;
    return Semantics(
      button: true,
      child: FocusableActionDetector(
        onShowHoverHighlight: (value) => setState(() => _hovered = value),
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        mouseCursor: SystemMouseCursors.click,
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap!();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _hovered || _focused
                  ? colors.accent
                  : const Color(0x00000000),
              borderRadius: theme.radius,
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

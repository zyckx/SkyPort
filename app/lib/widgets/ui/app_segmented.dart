import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Compact segmented control used as a tab switcher.
class AppSegmented<T> extends StatelessWidget {
  const AppSegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  final List<(T value, IconData icon, String label)> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.muted,
        borderRadius: theme.radius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (value, icon, label) in segments)
            Flexible(
              child: Semantics(
                button: true,
                selected: value == selected,
                child: GestureDetector(
                  key: ValueKey('segment-$value'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(value),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: value == selected
                            ? colors.background
                            : const Color(0x00000000),
                        borderRadius: theme.radius,
                        boxShadow: value == selected
                            ? const [
                                BoxShadow(
                                  color: Color(0x14000000),
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            size: 14,
                            color: value == selected
                                ? colors.foreground
                                : colors.mutedForeground,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.small.copyWith(
                                fontSize: 12,
                                color: value == selected
                                    ? colors.foreground
                                    : colors.mutedForeground,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

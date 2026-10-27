import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Labelled single-choice select. `options` pairs each value with its label.
///
/// A null [onChanged] disables the control. [selectKey] forces a fresh
/// selection state when the option set changes underneath the current value.
class AppSelect<T> extends StatelessWidget {
  const AppSelect({
    super.key,
    required this.initialValue,
    required this.options,
    required this.label,
    required this.onChanged,
    this.selectKey,
    this.enabled = true,
    this.showLabel = true,
    this.placeholder,
    this.errorText,
  });

  final T? initialValue;
  final List<(T, String)> options;
  final String label;
  final ValueChanged<T>? onChanged;
  final Key? selectKey;
  final bool enabled;
  final bool showLabel;
  final String? placeholder;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final colors = theme.colorScheme;
    final labels = {for (final (value, text) in options) value: text};
    final error = errorText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.small.copyWith(
              color: colors.mutedForeground,
            ),
          ),
          const SizedBox(height: 6),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 125;
            final textStyle = compact ? const TextStyle(fontSize: 12) : null;
            return Semantics(
              label: label,
              child: ShadSelect<T>(
                key: selectKey,
                initialValue: initialValue,
                enabled: enabled && onChanged != null,
                minWidth: constraints.maxWidth,
                maxWidth: constraints.maxWidth,
                maxHeight: 280,
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 8 : 12,
                  vertical: 8,
                ),
                decoration: error == null
                    ? null
                    : ShadDecoration(
                        border: ShadBorder.all(color: colors.destructive),
                      ),
                // ShadSelect asserts a placeholder whenever nothing is selected.
                placeholder: Text(
                  placeholder ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle,
                ),
                trailing: Icon(
                  LucideIcons.chevronDown,
                  size: compact ? 14 : 16,
                  color: colors.popoverForeground.withValues(alpha: .5),
                ),
                options: [
                  for (final (value, text) in options)
                    ShadOption<T>(value: value, child: Text(text)),
                ],
                selectedOptionBuilder: (context, value) => Text(
                  labels[value] ?? value.toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle,
                ),
                onChanged: (value) {
                  if (value != null) onChanged?.call(value);
                },
              ),
            );
          },
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(
            error,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.small.copyWith(
              color: colors.destructive,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Switch exposing [label] to assistive technologies.
class AppSwitch extends StatelessWidget {
  const AppSwitch({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: ShadSwitch(
        value: value,
        enabled: onChanged != null,
        onChanged: onChanged,
      ),
    );
  }
}

/// A labelled settings row: icon, title and a trailing switch.
class AppSwitchRow extends StatelessWidget {
  const AppSwitchRow({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
    this.padding,
  });

  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.mutedForeground),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: theme.textTheme.small)),
          AppSwitch(label: label, value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

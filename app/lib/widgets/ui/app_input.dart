import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Text input with optional label, suffix, helper and error text.
class AppInput extends StatelessWidget {
  const AppInput({
    super.key,
    this.controller,
    this.initialValue,
    this.label,
    this.placeholder,
    this.helperText,
    this.errorText,
    this.suffixText,
    this.keyboardType,
    this.inputFormatters,
    this.textAlign = TextAlign.start,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.focusNode,
    this.semanticLabel,
    this.dense = false,
    this.maxLines = 1,
    this.minLines,
    this.style,
  });

  final TextEditingController? controller;
  final String? initialValue;
  final String? label;
  final String? placeholder;
  final String? helperText;
  final String? errorText;
  final String? suffixText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextAlign textAlign;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final FocusNode? focusNode;
  final String? semanticLabel;
  final bool dense;
  final int? maxLines;
  final int? minLines;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final colors = theme.colorScheme;
    final small = theme.textTheme.small.copyWith(fontSize: 12);
    final error = errorText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: theme.textTheme.small.copyWith(
              color: colors.mutedForeground,
            ),
          ),
          const SizedBox(height: 6),
        ],
        Semantics(
          label: semanticLabel ?? label,
          child: ShadInput(
            controller: controller,
            initialValue: controller == null ? initialValue : null,
            placeholder: placeholder == null ? null : Text(placeholder!),
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            textAlign: textAlign,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            enabled: enabled,
            focusNode: focusNode,
            maxLines: maxLines,
            minLines: minLines,
            style: style,
            padding: dense
                ? const EdgeInsets.symmetric(horizontal: 6, vertical: 4)
                : null,
            decoration: error == null
                ? null
                : ShadDecoration(
                    border: ShadBorder.all(color: colors.destructive),
                  ),
            trailing: suffixText == null
                ? null
                : Text(
                    suffixText!,
                    style: small.copyWith(color: colors.mutedForeground),
                  ),
          ),
        ),
        if (error != null && error.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(error, style: small.copyWith(color: colors.destructive)),
        ] else if (helperText != null) ...[
          const SizedBox(height: 4),
          Text(
            helperText!,
            style: small.copyWith(color: colors.mutedForeground),
          ),
        ],
      ],
    );
  }
}

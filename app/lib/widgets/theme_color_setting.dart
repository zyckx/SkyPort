import 'package:flutter/material.dart' show Colors;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../theme.dart';
import 'ui/ui.dart';

String _hex(Color color) =>
    '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

class ThemeColorSetting extends ConsumerWidget {
  const ThemeColorSetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seed = ref.watch(themeColorProvider);
    final l10n = AppLocalizations.of(context);
    final presets = [
      (Colors.blue, l10n.themeBlue),
      (Colors.red, l10n.themeRed),
      (Colors.green, l10n.themeGreen),
      (Colors.teal, l10n.themeTeal),
      (Colors.indigo, l10n.themeIndigo),
      (const Color(0xff6750a4), l10n.themeViolet),
      (Colors.pink, l10n.themePink),
      (Colors.yellow, l10n.themeYellow),
      (Colors.orange, l10n.themeOrange),
    ];
    final preset = presets.where(
      (entry) => entry.$1.toARGB32() == seed.toARGB32(),
    );
    final custom = preset.isEmpty;
    final name = custom ? l10n.customSeedColor : preset.first.$2;

    return AppTooltip(
      message: _hex(seed),
      child: AppListTile(
        key: const ValueKey('theme-color-scheme'),
        icon: LucideIcons.palette,
        title: l10n.themeColor,
        subtitle: name,
        trailing: _Swatch(color: seed),
        onTap: () async {
          final chosen = await showShadDialog<Color>(
            context: context,
            builder: (dialogContext) => ShadDialog(
              title: Text(l10n.colorScheme),
              constraints: const BoxConstraints(maxWidth: 440),
              actions: [
                ShadButton.outline(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(l10n.cancel),
                ),
              ],
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (color, label) in presets)
                    _SchemeTile(
                      key: ValueKey('theme-preset-${color.toARGB32()}'),
                      seed: color,
                      label: label,
                      selected: color.toARGB32() == seed.toARGB32(),
                      onTap: () => Navigator.pop(dialogContext, color),
                    ),
                  _SchemeTile(
                    key: const ValueKey('theme-custom-color'),
                    seed: seed,
                    label: l10n.customSeedColor,
                    subtitle: custom ? _hex(seed) : null,
                    selected: custom,
                    onTap: () async {
                      final color = await showShadDialog<Color>(
                        context: dialogContext,
                        builder: (_) => _CustomColorDialog(initial: seed),
                      );
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext, color);
                      }
                    },
                  ),
                ],
              ),
            ),
          );
          if (chosen != null && context.mounted) {
            ref.read(themeColorProvider.notifier).setThemeColor(chosen);
          }
        },
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: ShadTheme.of(context).colorScheme.border),
          ),
        ),
        const SizedBox(width: 6),
        Icon(
          LucideIcons.chevronRight,
          size: 16,
          color: ShadTheme.of(context).colorScheme.mutedForeground,
        ),
      ],
    );
  }
}

class _SchemeTile extends StatelessWidget {
  const _SchemeTile({
    super.key,
    required this.seed,
    required this.label,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final Color seed;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final colors = theme.colorScheme;
    final accessibleLabel = subtitle == null ? label : '$label, $subtitle';
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: accessibleLabel,
      child: AppTooltip(
        message: accessibleLabel,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: SizedBox(
              width: 82,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: theme.radius,
                      border: Border.all(
                        color: selected ? colors.ring : colors.border,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        _SchemePreview(seed: seed, size: 40),
                        if (selected)
                          Icon(
                            LucideIcons.check,
                            color: colors.primaryForeground,
                            size: 16,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.small.copyWith(fontSize: 12),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.muted.copyWith(fontSize: 11),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows the accent colour the seed produces in the current brightness.
class _SchemePreview extends StatelessWidget {
  const _SchemePreview({required this.seed, this.size = 48});
  final Color seed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final brightness = ShadTheme.of(context).brightness;
    final accent = buildAccent(seed, brightness);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
      ),
    );
  }
}

class _CustomColorDialog extends StatefulWidget {
  const _CustomColorDialog({required this.initial});
  final Color initial;

  @override
  State<_CustomColorDialog> createState() => _CustomColorDialogState();
}

class _CustomColorDialogState extends State<_CustomColorDialog> {
  static const _channels = [('red', 16), ('green', 8), ('blue', 0)];

  late Color _draft;
  late final TextEditingController _controller;
  late final Map<int, ShadSliderController> _sliders;
  bool _valid = true;

  @override
  void initState() {
    super.initState();
    _draft = widget.initial.withValues(alpha: 1);
    _controller = TextEditingController(text: _hex(_draft));
    _sliders = {
      for (final (_, shift) in _channels)
        shift: ShadSliderController(initialValue: _channel(shift).toDouble()),
    };
  }

  @override
  void dispose() {
    _controller.dispose();
    for (final slider in _sliders.values) {
      slider.dispose();
    }
    super.dispose();
  }

  int _channel(int shift) => (_draft.toARGB32() >> shift) & 0xff;

  void _syncSliders() {
    for (final MapEntry(key: shift, value: slider) in _sliders.entries) {
      final value = _channel(shift).toDouble();
      if (slider.value != value) slider.value = value;
    }
  }

  void _editHex(String input) {
    final text = input.trim();
    setState(() {
      _valid = RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(text);
      if (_valid) {
        _draft = Color(0xff000000 | int.parse(text.substring(1), radix: 16));
        _syncSliders();
      }
    });
  }

  void _editChannel(int shift, double value) {
    setState(() {
      final argb = _draft.toARGB32();
      _draft = Color((argb & ~(0xff << shift)) | (value.round() << shift));
      _valid = true;
      _controller.value = TextEditingValue(
        text: _hex(_draft),
        selection: const TextSelection.collapsed(offset: 7),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final labels = {
      'red': l10n.colorChannelRed,
      'green': l10n.colorChannelGreen,
      'blue': l10n.colorChannelBlue,
    };
    return ShadDialog(
      title: Text(l10n.customSeedColor),
      constraints: const BoxConstraints(maxWidth: 400),
      actions: [
        ShadButton.outline(
          key: const ValueKey('theme-color-cancel'),
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ShadButton(
          key: const ValueKey('theme-color-apply'),
          onPressed: _valid ? () => Navigator.pop(context, _draft) : null,
          child: Text(l10n.applyColor),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 40,
                decoration: BoxDecoration(
                  color: _draft,
                  borderRadius: theme.radius,
                  border: Border.all(color: theme.colorScheme.border),
                ),
              ),
              const SizedBox(width: 12),
              _SchemePreview(seed: _draft, size: 32),
              const SizedBox(width: 12),
              Expanded(child: Text(_hex(_draft))),
            ],
          ),
          const SizedBox(height: 16),
          AppInput(
            key: const ValueKey('theme-color-hex'),
            controller: _controller,
            label: l10n.seedColorHex,
            errorText: _valid ? null : l10n.seedColorHexError,
            onChanged: _editHex,
          ),
          const SizedBox(height: 12),
          for (final (id, shift) in _channels) ...[
            Text(
              '${labels[id]} · ${_channel(shift)}',
              style: theme.textTheme.small,
            ),
            const SizedBox(height: 4),
            ShadSlider(
              key: ValueKey('theme-color-$id'),
              controller: _sliders[shift],
              max: 255,
              divisions: 255,
              semanticFormatterCallback: (value) =>
                  '${labels[id]} ${value.round()}',
              onChanged: (value) => _editChannel(shift, value),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

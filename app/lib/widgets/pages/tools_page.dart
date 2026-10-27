import 'package:flutter/material.dart' show SelectableText;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../utils/byte_codec.dart';
import '../../utils/checksum.dart';
import '../ui/ui.dart';

/// Offline calculators. Results are only displayed or copied; they are never
/// appended to or substituted into transmitted data.
class ToolsPage extends StatelessWidget {
  const ToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSection(
            title: l10n.toolChecksum,
            icon: LucideIcons.shieldCheck,
            children: const [
              Padding(padding: EdgeInsets.all(12), child: _ChecksumTool()),
            ],
          ),
          AppSection(
            title: l10n.toolHexText,
            icon: LucideIcons.arrowLeftRight,
            children: const [
              Padding(padding: EdgeInsets.all(12), child: _HexTextTool()),
            ],
          ),
          AppSection(
            title: l10n.toolNumberBase,
            icon: LucideIcons.hash,
            children: const [
              Padding(padding: EdgeInsets.all(12), child: _NumberBaseTool()),
            ],
          ),
        ],
      ),
    );
  }
}

String? hexErrorText(HexParseError? error, AppLocalizations l10n) =>
    switch (error) {
      HexParseError.invalidCharacter => l10n.invalidHexChars,
      HexParseError.oddLength => l10n.hexEvenLength,
      null => null,
    };

void _copy(BuildContext context, String value) {
  Clipboard.setData(ClipboardData(text: value));
  showAppToast(context, AppLocalizations.of(context).copied);
}

/// A labelled monospace result with a copy action.
class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value, this.copyKey});

  final String label;
  final String value;
  final Key? copyKey;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 136,
            child: Text(
              label,
              style: theme.textTheme.muted.copyWith(fontSize: 12),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: theme.textTheme.small.copyWith(fontFamily: 'monospace'),
            ),
          ),
          AppIconButton(
            key: copyKey,
            icon: LucideIcons.copy,
            tooltip: l10n.copy,
            size: 24,
            iconSize: 13,
            onPressed: value.isEmpty ? null : () => _copy(context, value),
          ),
        ],
      ),
    );
  }
}

enum _InputFormat { text, hex }

class _ChecksumTool extends StatefulWidget {
  const _ChecksumTool();

  @override
  State<_ChecksumTool> createState() => _ChecksumToolState();
}

class _ChecksumToolState extends State<_ChecksumTool> {
  _InputFormat _format = _InputFormat.hex;
  String _input = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final HexParse parsed = _format == _InputFormat.hex
        ? parseHex(_input)
        : (bytes: textBytes(_input), error: null);
    final bytes = parsed.bytes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSelect<_InputFormat>(
          key: const ValueKey('checksum-format'),
          label: l10n.toolInputFormat,
          initialValue: _format,
          options: [
            (_InputFormat.hex, 'Hex'),
            (_InputFormat.text, l10n.toolInputTextUtf8),
          ],
          onChanged: (value) => setState(() => _format = value),
        ),
        const SizedBox(height: 8),
        AppInput(
          key: const ValueKey('checksum-input'),
          semanticLabel: l10n.toolChecksum,
          placeholder: _format == _InputFormat.hex ? '01 03 00 00 00 0A' : '',
          minLines: 2,
          maxLines: 4,
          style: const TextStyle(fontFamily: 'monospace'),
          errorText: hexErrorText(parsed.error, l10n),
          onChanged: (value) => setState(() => _input = value),
        ),
        const SizedBox(height: 8),
        if (bytes != null) ...[
          Text(
            l10n.toolByteCount(bytes.length),
            style: theme.textTheme.muted.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 4),
          for (final algorithm in ChecksumAlgorithm.values)
            _ResultRow(
              copyKey: ValueKey('checksum-copy-${algorithm.name}'),
              label: algorithm.label,
              value: formatHex(
                checksumBytes(algorithm.compute(bytes), algorithm.width),
              ),
            ),
        ],
        const SizedBox(height: 6),
        Text(
          l10n.toolChecksumNote,
          style: theme.textTheme.muted.copyWith(fontSize: 11),
        ),
      ],
    );
  }
}

class _HexTextTool extends StatefulWidget {
  const _HexTextTool();

  @override
  State<_HexTextTool> createState() => _HexTextToolState();
}

class _HexTextToolState extends State<_HexTextTool> {
  String _text = '';
  String _hex = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final parsed = parseHex(_hex);
    final Uint8List? hexBytes = parsed.bytes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppInput(
          key: const ValueKey('text-to-hex-input'),
          label: l10n.toolTextToHex,
          maxLines: 3,
          onChanged: (value) => setState(() => _text = value),
        ),
        const SizedBox(height: 4),
        _ResultRow(label: 'Hex', value: formatHex(textBytes(_text))),
        const SizedBox(height: 12),
        AppInput(
          key: const ValueKey('hex-to-text-input'),
          label: l10n.toolHexToText,
          maxLines: 3,
          style: const TextStyle(fontFamily: 'monospace'),
          errorText: hexErrorText(parsed.error, l10n),
          onChanged: (value) => setState(() => _hex = value),
        ),
        const SizedBox(height: 4),
        _ResultRow(
          label: l10n.toolInputTextUtf8,
          value: hexBytes == null ? '' : describeBytes(hexBytes),
        ),
      ],
    );
  }
}

class _NumberBaseTool extends StatefulWidget {
  const _NumberBaseTool();

  @override
  State<_NumberBaseTool> createState() => _NumberBaseToolState();
}

class _NumberBaseToolState extends State<_NumberBaseTool> {
  NumberBase _base = NumberBase.decimal;
  String _input = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final value = parseNumber(_input, _base);
    final invalid = _input.trim().isNotEmpty && value == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 92,
              child: AppSelect<NumberBase>(
                key: const ValueKey('number-base'),
                label: l10n.toolInputFormat,
                showLabel: false,
                initialValue: _base,
                options: [
                  for (final base in NumberBase.values) (base, base.label),
                ],
                onChanged: (base) => setState(() => _base = base),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppInput(
                key: const ValueKey('number-input'),
                semanticLabel: l10n.toolNumberBase,
                style: const TextStyle(fontFamily: 'monospace'),
                errorText: invalid ? l10n.toolInvalidNumber : null,
                onChanged: (text) => setState(() => _input = text),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final base in NumberBase.values)
          _ResultRow(
            label: base.label,
            value: value == null ? '' : formatNumber(value, base),
          ),
      ],
    );
  }
}

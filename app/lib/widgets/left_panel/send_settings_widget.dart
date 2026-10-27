import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../models/ui_state.dart';
import '../../providers/ui_controller.dart';
import '../../utils/error_messages.dart';
import '../shared/error_notice.dart';
import '../ui/ui.dart';

class SendSettingsWidget extends ConsumerWidget {
  const SendSettingsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(
      uiControllerProvider.select(
        (state) => (
          hexSend: state.hexSend,
          autoSendEnabled: state.autoSendEnabled,
          autoSendIntervalMs: state.autoSendIntervalMs,
          autoSendError: state.autoSendError,
          appendNewline: state.appendNewline,
          newline: state.newline,
        ),
      ),
    );
    final controller = ref.read(uiControllerProvider.notifier);
    final l10n = AppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final muted = theme.colorScheme.mutedForeground;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSwitchRow(
          label: l10n.hexSend,
          icon: LucideIcons.binary,
          value: settings.hexSend,
          onChanged: (value) => controller.setSendSettings(
            hex: value,
            input: ref.read(autoSendDraftProvider.notifier).forMode(value),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(LucideIcons.repeat, size: 16, color: muted),
            const SizedBox(width: 8),
            Expanded(child: Text(l10n.autoSend, style: theme.textTheme.small)),
            SizedBox(
              width: 64,
              child: _IntervalField(
                intervalMs: settings.autoSendIntervalMs,
                label: l10n.autoSend,
                onChanged: (ms) => controller.setSendSettings(intervalMs: ms),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              l10n.secondsUnit,
              style: theme.textTheme.muted.copyWith(fontSize: 12),
            ),
            const SizedBox(width: 8),
            AppSwitch(
              label: l10n.autoSend,
              value: settings.autoSendEnabled,
              onChanged: (v) => controller.setSendSettings(
                enabled: v,
                input: v ? ref.read(autoSendDraftProvider) : null,
              ),
            ),
          ],
        ),
        if (settings.autoSendError != null) ...[
          const SizedBox(height: 6),
          Text(
            l10n.autoSendPaused(localizedError(l10n, settings.autoSendError!)),
            style: theme.textTheme.small.copyWith(
              color: theme.colorScheme.destructive,
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ShadButton.link(
              padding: EdgeInsets.zero,
              onPressed: () =>
                  showErrorDetails(context, settings.autoSendError!),
              child: Text(l10n.diagnosticDetails),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(LucideIcons.cornerDownLeft, size: 16, color: muted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(l10n.newlineMode, style: theme.textTheme.small),
            ),
            SizedBox(
              width: 145,
              child: AppSelect<UiNewline>(
                label: l10n.newlineMode,
                showLabel: false,
                initialValue: settings.appendNewline
                    ? settings.newline
                    : UiNewline.none,
                options: const [
                  (UiNewline.none, 'None'),
                  (UiNewline.lf, r'LF (\n)'),
                  (UiNewline.cr, r'CR (\r)'),
                  (UiNewline.crlf, r'CRLF (\r\n)'),
                ],
                onChanged: settings.hexSend
                    ? null
                    : (value) => controller.setSendSettings(
                        appendNewline: value != UiNewline.none,
                        newline: value == UiNewline.none ? null : value,
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Auto-send interval in seconds. Only values in 0.01–60 s are submitted;
/// the core remains the authority on the accepted range.
class _IntervalField extends StatefulWidget {
  const _IntervalField({
    required this.intervalMs,
    required this.label,
    required this.onChanged,
  });

  final int intervalMs;
  final String label;
  final ValueChanged<int> onChanged;

  @override
  State<_IntervalField> createState() => _IntervalFieldState();
}

class _IntervalFieldState extends State<_IntervalField> {
  late final TextEditingController _controller = TextEditingController(
    text: (widget.intervalMs / 1000).toString(),
  );
  bool _valid = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _edit(String value) {
    final interval = double.tryParse(value);
    final inRange = interval != null && interval >= 0.01 && interval <= 60;
    final valid = value.isEmpty || inRange;
    if (valid != _valid) setState(() => _valid = valid);
    if (inRange) widget.onChanged((interval * 1000).round());
  }

  @override
  Widget build(BuildContext context) {
    return AppInput(
      controller: _controller,
      semanticLabel: widget.label,
      dense: true,
      textAlign: TextAlign.center,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      errorText: _valid ? null : '',
      onChanged: _edit,
    );
  }
}

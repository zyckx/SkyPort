import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../models/quick_command.dart';
import '../../models/ui_state.dart';
import '../../providers/quick_commands_provider.dart';
import '../../providers/ui_controller.dart';
import '../../utils/byte_codec.dart';
import '../../utils/error_messages.dart';
import '../ui/ui.dart';
import 'tools_page.dart' show hexErrorText;

String newlineLabel(UiNewline newline) => switch (newline) {
  UiNewline.none => 'None',
  UiNewline.lf => r'LF (\n)',
  UiNewline.cr => r'CR (\r)',
  UiNewline.crlf => r'CRLF (\r\n)',
};

class QuickCommandsPage extends ConsumerWidget {
  const QuickCommandsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final commands = ref.watch(quickCommandsProvider);
    final connected = ref.watch(
      uiControllerProvider.select(
        (state) => state.connection == UiConnection.connected,
      ),
    );

    Future<void> edit([QuickCommand? command]) async {
      final result = await showQuickCommandEditor(context, command);
      if (result == null) return;
      final notifier = ref.read(quickCommandsProvider.notifier);
      if (command == null) {
        if (!notifier.add(result) && context.mounted) {
          showAppToast(context, l10n.quickCommandListFull, destructive: true);
        }
      } else {
        notifier.replace(result);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
          child: Row(
            children: [
              Icon(
                LucideIcons.listChecks,
                size: 16,
                color: theme.colorScheme.mutedForeground,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.quickCommandsPageLabel,
                  style: theme.textTheme.small.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              AppTooltip(
                message: l10n.quickCommandAdd,
                child: ShadButton.outline(
                  key: const ValueKey('quick-command-add'),
                  size: ShadButtonSize.sm,
                  leading: const Icon(LucideIcons.plus, size: 14),
                  onPressed: () => edit(),
                  // Icon-only on narrow drawers so the header never overflows.
                  child: MediaQuery.sizeOf(context).width < 600
                      ? null
                      : Text(l10n.quickCommandAdd),
                ),
              ),
            ],
          ),
        ),
        if (commands.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: _LoopBar(commands: commands),
          ),
        Expanded(
          child: commands.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    l10n.quickCommandsEmpty,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.muted,
                  ),
                )
              : ReorderableList(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                  itemCount: commands.length,
                  onReorderItem: ref.read(quickCommandsProvider.notifier).move,
                  itemBuilder: (context, index) {
                    final command = commands[index];
                    return _CommandTile(
                      key: ValueKey(command.id),
                      index: index,
                      command: command,
                      canSend: connected,
                      onSend: () => ref
                          .read(uiControllerProvider.notifier)
                          .sendCommand(
                            command.payload,
                            hex: command.hex,
                            newline: command.newline,
                          ),
                      onEdit: () => edit(command),
                      onDelete: () => ref
                          .read(quickCommandsProvider.notifier)
                          .remove(command.id),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _CommandTile extends StatelessWidget {
  const _CommandTile({
    super.key,
    required this.index,
    required this.command,
    required this.canSend,
    required this.onSend,
    required this.onEdit,
    required this.onDelete,
  });

  final int index;
  final QuickCommand command;
  final bool canSend;
  final VoidCallback onSend;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final colors = theme.colorScheme;
    final format = command.hex
        ? 'HEX'
        : command.newline == UiNewline.none
        ? 'TXT'
        : 'TXT+${command.newline.name.toUpperCase()}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: theme.radius,
          border: Border.all(color: colors.border),
        ),
        padding: const EdgeInsets.fromLTRB(4, 6, 6, 6),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: MouseRegion(
                cursor: SystemMouseCursors.grab,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    LucideIcons.gripVertical,
                    size: 14,
                    color: colors.mutedForeground,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          command.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.small.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      ShadBadge.secondary(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Text(
                          format,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    command.payload,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.muted.copyWith(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            AppIconButton(
              icon: LucideIcons.pencil,
              tooltip: l10n.quickCommandEdit,
              size: 26,
              iconSize: 13,
              onPressed: onEdit,
            ),
            AppIconButton(
              icon: LucideIcons.trash2,
              tooltip: l10n.delete,
              size: 26,
              iconSize: 13,
              onPressed: onDelete,
            ),
            const SizedBox(width: 2),
            AppTooltip(
              message: canSend ? l10n.send : l10n.quickCommandNotConnected,
              child: ShadIconButton(
                key: ValueKey('quick-command-send-${command.id}'),
                icon: const Icon(LucideIcons.send, size: 13),
                width: 28,
                height: 28,
                padding: EdgeInsets.zero,
                enabled: canSend,
                onPressed: canSend ? onSend : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

int _idCounter = 0;

String _newId() =>
    '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-${_idCounter++}';

/// Opens the add/edit dialog; returns the edited command or null if cancelled.
Future<QuickCommand?> showQuickCommandEditor(
  BuildContext context,
  QuickCommand? initial,
) => showShadDialog<QuickCommand>(
  context: context,
  builder: (context) => _QuickCommandDialog(initial: initial),
);

class _QuickCommandDialog extends StatefulWidget {
  const _QuickCommandDialog({this.initial});

  final QuickCommand? initial;

  @override
  State<_QuickCommandDialog> createState() => _QuickCommandDialogState();
}

class _QuickCommandDialogState extends State<_QuickCommandDialog> {
  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late final _payload = TextEditingController(
    text: widget.initial?.payload ?? '',
  );
  late bool _hex = widget.initial?.hex ?? false;
  late UiNewline _newline = widget.initial?.newline ?? UiNewline.none;
  bool _submitted = false;

  @override
  void dispose() {
    _name.dispose();
    _payload.dispose();
    super.dispose();
  }

  String? _payloadError(AppLocalizations l10n) {
    if (_payload.text.isEmpty) {
      return _submitted ? l10n.quickCommandPayloadRequired : null;
    }
    if (!_hex) return null;
    final parsed = parseHex(_payload.text);
    if (parsed.error == null && parsed.bytes!.isEmpty) {
      return _submitted ? l10n.quickCommandPayloadRequired : null;
    }
    return hexErrorText(parsed.error, l10n);
  }

  void _save(AppLocalizations l10n) {
    setState(() => _submitted = true);
    if (_payloadError(l10n) != null) return;
    final name = _name.text.trim();
    final payload = _payload.text;
    Navigator.of(context).pop(
      QuickCommand(
        id: widget.initial?.id ?? _newId(),
        name: name.isEmpty ? payload.split('\n').first : name,
        payload: payload,
        hex: _hex,
        newline: _newline,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ShadDialog(
      title: Text(
        widget.initial == null ? l10n.quickCommandAdd : l10n.quickCommandEdit,
      ),
      constraints: const BoxConstraints(maxWidth: 440),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        ShadButton(
          key: const ValueKey('quick-command-save'),
          onPressed: () => _save(l10n),
          child: Text(l10n.save),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppInput(
            key: const ValueKey('quick-command-name'),
            controller: _name,
            label: l10n.quickCommandName,
            placeholder: l10n.quickCommandNameHint,
          ),
          const SizedBox(height: 12),
          AppInput(
            key: const ValueKey('quick-command-payload'),
            controller: _payload,
            label: l10n.quickCommandPayload,
            minLines: 2,
            maxLines: 5,
            style: const TextStyle(fontFamily: 'monospace'),
            errorText: _payloadError(l10n),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppSelect<bool>(
                  key: const ValueKey('quick-command-format'),
                  label: l10n.toolInputFormat,
                  initialValue: _hex,
                  options: [(false, l10n.toolInputTextUtf8), (true, 'Hex')],
                  onChanged: (value) => setState(() => _hex = value),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppSelect<UiNewline>(
                  key: const ValueKey('quick-command-newline'),
                  label: l10n.newlineMode,
                  initialValue: _newline,
                  options: [
                    for (final value in UiNewline.values)
                      (value, newlineLabel(value)),
                  ],
                  onChanged: _hex
                      ? null
                      : (value) => setState(() => _newline = value),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Starts or stops the core's looping sender over the saved commands. The
/// schedule runs in the core; this only submits the request and shows state.
class _LoopBar extends ConsumerStatefulWidget {
  const _LoopBar({required this.commands});

  final List<QuickCommand> commands;

  @override
  ConsumerState<_LoopBar> createState() => _LoopBarState();
}

class _LoopBarState extends ConsumerState<_LoopBar> {
  final _interval = TextEditingController(text: '1.0');

  @override
  void dispose() {
    _interval.dispose();
    super.dispose();
  }

  int? get _intervalMs {
    final seconds = double.tryParse(_interval.text.trim());
    if (seconds == null || seconds < 0.01 || seconds > 60) return null;
    return (seconds * 1000).round();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final run = ref.watch(uiControllerProvider.select((s) => s.sequenceSend));
    final controller = ref.read(uiControllerProvider.notifier);
    final intervalMs = _intervalMs;
    final status = run.enabled
        ? l10n.sequenceRunning(run.nextIndex + 1, run.itemCount)
        : run.error != null
        ? l10n.sequenceStopped(localizedError(l10n, run.error!))
        : l10n.sequenceLoopHint;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        borderRadius: theme.radius,
        border: Border.all(color: theme.colorScheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.repeat,
                size: 14,
                color: theme.colorScheme.mutedForeground,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(l10n.sequenceLoop, style: theme.textTheme.small),
              ),
              SizedBox(
                width: 56,
                child: AppInput(
                  key: const ValueKey('sequence-interval'),
                  controller: _interval,
                  dense: true,
                  enabled: !run.enabled,
                  textAlign: TextAlign.center,
                  semanticLabel: l10n.sequenceLoop,
                  errorText: intervalMs == null ? '' : null,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                l10n.secondsUnit,
                style: theme.textTheme.muted.copyWith(fontSize: 12),
              ),
              const SizedBox(width: 6),
              AppIconButton(
                key: const ValueKey('sequence-toggle'),
                icon: run.enabled ? LucideIcons.square : LucideIcons.play,
                tooltip: run.enabled ? l10n.sequenceStop : l10n.sequenceStart,
                onPressed: run.enabled
                    ? () => controller.setSequenceSend(
                        enabled: false,
                        intervalMs: run.intervalMs,
                        commands: const [],
                      )
                    : intervalMs == null
                    ? null
                    : () => controller.setSequenceSend(
                        enabled: true,
                        intervalMs: intervalMs,
                        commands: widget.commands,
                      ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            status,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.muted.copyWith(
              fontSize: 11,
              color: run.error != null && !run.enabled
                  ? theme.colorScheme.destructive
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

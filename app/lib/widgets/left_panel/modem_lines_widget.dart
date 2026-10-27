import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../models/ui_state.dart';
import '../../providers/ui_controller.dart';
import '../ui/ui.dart';

/// DTR/RTS toggles. They show the levels the core reports as applied, not
/// the requested ones, and are only enabled while a port is open.
class ModemLinesWidget extends ConsumerWidget {
  const ModemLinesWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      uiControllerProvider.select(
        (s) => (
          connected: s.connection == UiConnection.connected,
          hardwareFlow: s.flowControl == UiFlowControl.hardware,
          dtr: s.dtr,
          rts: s.rts,
        ),
      ),
    );
    final controller = ref.read(uiControllerProvider.notifier);
    final l10n = AppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSwitchRow(
          key: const ValueKey('dtr-switch'),
          label: 'DTR',
          icon: LucideIcons.zap,
          value: state.dtr,
          onChanged: state.connected
              ? (value) => controller.setModemLines(dtr: value)
              : null,
        ),
        AppTooltip(
          message: state.hardwareFlow ? l10n.modemLinesHardwareFlow : '',
          child: AppSwitchRow(
            key: const ValueKey('rts-switch'),
            label: 'RTS',
            icon: LucideIcons.zap,
            value: state.rts,
            onChanged: state.connected && !state.hardwareFlow
                ? (value) => controller.setModemLines(rts: value)
                : null,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.modemLinesHint,
          style: theme.textTheme.muted.copyWith(fontSize: 11),
        ),
      ],
    );
  }
}

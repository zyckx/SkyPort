import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../l10n/app_localizations.dart';
import '../providers/ui_controller.dart';
import '../utils/connection_status.dart';
import 'left_panel/modem_lines_widget.dart';
import 'left_panel/port_selection_widget.dart';
import 'left_panel/receive_settings_widget.dart';
import 'left_panel/send_settings_widget.dart';
import 'left_panel/serial_params_widget.dart';
import 'ui/ui.dart';

class LeftPanel extends StatelessWidget {
  const LeftPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      // The section's 12 px inset preserves the original 16 px control margins.
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSection(
            title: l10n.serialPortSettings,
            icon: LucideIcons.usb,
            trailing: const _ConnectionStatus(),
            children: const [
              Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  children: [
                    PortSelectionWidget(),
                    SizedBox(height: 12),
                    SerialParamsWidget(),
                  ],
                ),
              ),
            ],
          ),
          AppSection(
            title: l10n.modemLines,
            icon: LucideIcons.cable,
            children: const [
              Padding(padding: EdgeInsets.all(12), child: ModemLinesWidget()),
            ],
          ),
          AppSection(
            title: l10n.receiveSettings,
            icon: LucideIcons.monitor,
            children: const [
              Padding(
                padding: EdgeInsets.all(12),
                child: ReceiveSettingsWidget(),
              ),
            ],
          ),
          AppSection(
            title: l10n.sendSettings,
            icon: LucideIcons.send,
            children: const [
              Padding(padding: EdgeInsets.all(12), child: SendSettingsWidget()),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConnectionStatus extends ConsumerWidget {
  const _ConnectionStatus();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connection = ref.watch(
      uiControllerProvider.select((state) => state.connection),
    );
    final theme = ShadTheme.of(context);
    final label = connectionStatusLabel(
      connection,
      AppLocalizations.of(context),
    );
    final color = connectionStatusColor(connection, theme);
    return Semantics(
      liveRegion: true,
      label: label,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.small.copyWith(
                  color: color,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

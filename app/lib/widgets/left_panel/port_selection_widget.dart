import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../models/ui_state.dart';
import '../../providers/ui_controller.dart';
import '../../utils/connection_status.dart';
import '../ui/ui.dart';

class PortSelectionWidget extends ConsumerWidget {
  const PortSelectionWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      uiControllerProvider.select(
        (state) => (
          connection: state.connection,
          ports: state.ports,
          portName: state.portName,
        ),
      ),
    );
    final controller = ref.read(uiControllerProvider.notifier);

    final connectionState = state.connection;
    final isConnected = connectionState == UiConnection.connected;
    final isBusy =
        connectionState == UiConnection.connecting ||
        connectionState == UiConnection.disconnecting ||
        connectionState == UiConnection.reconfiguring ||
        connectionState == UiConnection.closing ||
        connectionState == UiConnection.closed;
    final ports = state.ports;
    final selectedPort = state.portName.isEmpty ? null : state.portName;
    final isUnavailable =
        !isConnected && selectedPort != null && !ports.contains(selectedPort);

    final disconnect =
        isConnected || connectionState == UiConnection.reconnecting;
    final l10n = AppLocalizations.of(context);
    final onPressed =
        isBusy || (!disconnect && (selectedPort == null || isUnavailable))
        ? null
        : () => disconnect ? controller.disconnect() : controller.connect();
    final leading = isBusy
        ? const AppSpinner()
        : Icon(disconnect ? LucideIcons.unlink : LucideIcons.link, size: 16);
    final label = Text(
      isBusy
          ? connectionStatusLabel(connectionState, l10n)
          : disconnect
          ? l10n.disconnect
          : l10n.connect,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildPortDropdown(
            context: context,
            ports: ports,
            selectedPort: selectedPort,
            isUnavailable: isUnavailable,
            isReconnecting: connectionState == UiConnection.reconnecting,
            isDisabled: isConnected || isBusy,
            onSelected: controller.setPort,
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(top: 21),
          child: isConnected
              ? ShadButton.destructive(
                  height: 36,
                  onPressed: onPressed,
                  leading: leading,
                  child: label,
                )
              : ShadButton(
                  height: 36,
                  onPressed: onPressed,
                  leading: leading,
                  child: label,
                ),
        ),
      ],
    );
  }

  Widget _buildPortDropdown({
    required BuildContext context,
    required List<String> ports,
    required String? selectedPort,
    required bool isUnavailable,
    required bool isReconnecting,
    required bool isDisabled,
    required ValueChanged<String> onSelected,
  }) {
    final l10n = AppLocalizations.of(context);

    return AppSelect<String>(
      selectKey: ValueKey('${ports.join('\u0000')}\u0001$selectedPort'),
      initialValue: ports.contains(selectedPort) ? selectedPort : null,
      options: [for (final port in ports) (port, port)],
      onChanged: isDisabled ? null : onSelected,
      placeholder: ports.isEmpty ? l10n.noPortsFound : null,
      errorText: isReconnecting && selectedPort != null
          ? '${l10n.reconnecting}: $selectedPort'
          : isUnavailable
          ? '${l10n.unavailable}: $selectedPort'
          : null,
      label: l10n.portName,
      enabled: !isDisabled && ports.isNotEmpty,
    );
  }
}

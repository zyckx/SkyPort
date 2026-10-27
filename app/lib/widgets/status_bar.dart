import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../providers/ui_controller.dart';
import '../l10n/app_localizations.dart';
import '../models/ui_state.dart';
import '../utils/connection_status.dart';
import '../utils/error_messages.dart';
import 'shared/error_notice.dart';
import 'ui/ui.dart';

class StatusBar extends ConsumerWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      uiControllerProvider.select(
        (state) => (
          rxBytes: state.rxBytes,
          txBytes: state.txBytes,
          lastRxBytes: state.lastRxBytes,
          rxBytesPerSecond: state.rxBytesPerSecond,
          connection: state.connection,
          portName: state.portName,
          baudRate: state.baudRate,
          dataBits: state.dataBits,
          parity: state.parity,
          stopBits: state.stopBits,
          error: state.error,
          dataGap: state.dataGap,
          dtr: state.dtr,
          rts: state.rts,
          trimmedRecords: state.trimmedRecords,
          trimmedBytes: state.trimmedBytes,
        ),
      ),
    );
    final theme = ShadTheme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final small = theme.textTheme.small.copyWith(fontSize: 12);
    final muted = small.copyWith(color: colors.mutedForeground);

    final rxText = formatIecBytes(state.rxBytes);
    final lastRxText = formatIecBytes(state.lastRxBytes);
    final txText = formatIecBytes(state.txBytes);
    final rateText = '${formatIecBytes(state.rxBytesPerSecond)}/s';
    final disconnect =
        state.connection == UiConnection.connected ||
        state.connection == UiConnection.reconnecting;
    final canToggle =
        disconnect ||
        (state.connection == UiConnection.disconnected &&
            state.portName.isNotEmpty);
    final statusColor = connectionStatusColor(state.connection, theme);
    final status = connectionStatusLabel(state.connection, l10n);
    final reconnecting = state.connection == UiConnection.reconnecting;
    final diagnostic = reconnecting ? state.error : null;
    final serialSettings =
        '${state.baudRate} · ${state.dataBits}'
        '${switch (state.parity) {
          UiParity.none => 'N',
          UiParity.odd => 'O',
          UiParity.even => 'E',
        }}${state.stopBits}';
    final logWarning = [
      if (state.dataGap) l10n.logDataGap,
      if (state.trimmedRecords > 0)
        l10n.logTrimmed(state.trimmedRecords, state.trimmedBytes),
    ].join('\n');

    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.border)),
        color: colors.background,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final roomy = constraints.maxWidth >= 360;
          return Row(
            children: [
              AppTooltip(
                message:
                    '$status\n${disconnect ? l10n.disconnect : l10n.connect}',
                child: ShadButton.ghost(
                  key: const ValueKey('status-connection-toggle'),
                  height: 24,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  onPressed: !canToggle
                      ? null
                      : () {
                          final controller = ref.read(
                            uiControllerProvider.notifier,
                          );
                          if (disconnect) {
                            controller.disconnect();
                          } else {
                            controller.connect();
                          }
                        },
                  leading: Container(
                    key: const ValueKey('status-dot'),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  child: roomy
                      ? Text(
                          status,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: small.copyWith(color: statusColor),
                        )
                      : null,
                ),
              ),
              if (roomy) ...[
                const SizedBox(width: 6),
                Icon(LucideIcons.usb, size: 13, color: colors.mutedForeground),
              ],
              const SizedBox(width: 4),
              Expanded(
                child: AppTooltip(
                  message:
                      '$status\n${state.portName}  $serialSettings'
                      '${diagnostic == null ? '' : '\n${localizedError(l10n, diagnostic)}'}',
                  child: Text.rich(
                    TextSpan(
                      text: state.portName.isEmpty
                          ? l10n.noPortSelected
                          : state.portName,
                      children: [
                        if (state.portName.isNotEmpty)
                          TextSpan(text: '  $serialSettings', style: muted),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: small,
                  ),
                ),
              ),
              if (diagnostic != null)
                AppIconButton(
                  tooltip:
                      '${l10n.diagnosticDetails}: ${localizedError(l10n, diagnostic)}',
                  icon: LucideIcons.info,
                  size: 24,
                  iconSize: 14,
                  onPressed: () => showErrorDetails(context, diagnostic),
                ),
              if (roomy && state.connection == UiConnection.connected) ...[
                const SizedBox(width: 6),
                _LineBadge(label: 'DTR', active: state.dtr),
                const SizedBox(width: 4),
                _LineBadge(label: 'RTS', active: state.rts),
              ],
              if (logWarning.isNotEmpty) ...[
                const SizedBox(width: 4),
                AppTooltip(
                  message: logWarning,
                  child: Icon(
                    LucideIcons.triangleAlert,
                    key: const ValueKey('status-log-warning'),
                    size: 14,
                    color: colors.destructive,
                  ),
                ),
              ],
              if (!reconnecting) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: AppTooltip(
                    message:
                        'RX $rxText - $lastRxText    TX $txText    $rateText\n'
                        '${l10n.trafficStats(state.rxBytes, state.txBytes, state.lastRxBytes)}'
                        '\n${l10n.trafficStatsTooltip}',
                    // One line that truncates instead of overflowing when narrow.
                    child: Text.rich(
                      TextSpan(
                        children: [
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: _ActivityLed(
                              key: const ValueKey('rx-led'),
                              counter: state.rxBytes,
                              color: const Color(0xff16a34a),
                            ),
                          ),
                          TextSpan(text: ' RX $rxText - $lastRxText   '),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: _ActivityLed(
                              key: const ValueKey('tx-led'),
                              counter: state.txBytes,
                              color: const Color(0xfff59e0b),
                            ),
                          ),
                          TextSpan(text: ' TX $txText   '),
                          TextSpan(text: rateText, style: muted),
                        ],
                      ),
                      maxLines: 1,
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                      style: small,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Lights briefly whenever [counter] increases, like a hardware RX/TX LED.
class _ActivityLed extends StatefulWidget {
  const _ActivityLed({super.key, required this.counter, required this.color});

  final int counter;
  final Color color;

  @override
  State<_ActivityLed> createState() => _ActivityLedState();
}

class _ActivityLedState extends State<_ActivityLed> {
  Timer? _timer;
  bool _lit = false;

  @override
  void didUpdateWidget(covariant _ActivityLed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.counter > oldWidget.counter) {
      _timer?.cancel();
      _lit = true;
      _timer = Timer(const Duration(milliseconds: 150), () {
        if (mounted) setState(() => _lit = false);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final border = ShadTheme.of(context).colorScheme.border;
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _lit ? widget.color : border,
      ),
    );
  }
}

String formatIecBytes(num bytes) {
  const units = ['B', 'KiB', 'MiB', 'GiB', 'TiB', 'PiB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  return unit == 0
      ? '${value.round()} ${units[unit]}'
      : '${value.toStringAsFixed(1)} ${units[unit]}';
}

/// Compact indicator for an output modem line level.
class _LineBadge extends StatelessWidget {
  const _LineBadge({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final colors = theme.colorScheme;
    return Semantics(
      label: '$label ${active ? 'on' : 'off'}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: active ? colors.primary : null,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: active ? colors.primary : colors.border),
        ),
        child: Text(
          label,
          style: theme.textTheme.small.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: active ? colors.primaryForeground : colors.mutedForeground,
          ),
        ),
      ),
    );
  }
}

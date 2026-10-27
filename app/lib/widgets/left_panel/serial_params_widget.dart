import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../models/ui_state.dart';
import '../../providers/ui_controller.dart';
import '../ui/ui.dart';

const _baudRates = [
  1200,
  2400,
  4800,
  9600,
  19200,
  38400,
  57600,
  115200,
  230400,
  460800,
  921600,
];

class SerialParamsWidget extends ConsumerWidget {
  const SerialParamsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isReconfiguring = ref.watch(
      uiControllerProvider.select(
        (state) => state.connection == UiConnection.reconfiguring,
      ),
    );

    return _buildSerialParamsGrid(context, ref, isReconfiguring);
  }

  Widget _buildSerialParamsGrid(
    BuildContext context,
    WidgetRef ref,
    bool isReconfiguring,
  ) {
    final state = ref.watch(
      uiControllerProvider.select(
        (state) => (
          baudRate: state.baudRate,
          flowControl: state.flowControl,
          dataBits: state.dataBits,
          parity: state.parity,
          stopBits: state.stopBits,
        ),
      ),
    );
    final controller = ref.read(uiControllerProvider.notifier);
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 250;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: compact ? 5 : 1,
                  child: AppSelect<int>(
                    initialValue: state.baudRate,
                    label: l10n.baudRate,
                    options: [
                      for (final rate in _baudRates) (rate, rate.toString()),
                    ],
                    onChanged: controller.setBaudRate,
                  ),
                ),
                SizedBox(width: compact ? 8 : 12),
                Expanded(
                  flex: compact ? 4 : 1,
                  child: AppTooltip(
                    message: state.flowControl == UiFlowControl.software
                        ? l10n.flowControlSoftwareWarning
                        : '',
                    child: AppSelect<UiFlowControl>(
                      initialValue: state.flowControl,
                      label: l10n.flowControl,
                      options: [
                        (UiFlowControl.none, l10n.flowControlNone),
                        (UiFlowControl.hardware, l10n.flowControlHardware),
                        (UiFlowControl.software, l10n.flowControlSoftware),
                      ],
                      onChanged: controller.setFlowControl,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        if (isReconfiguring)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 40, top: 4),
              child: AppSpinner(
                color: ShadTheme.of(context).colorScheme.primary,
              ),
            ),
          ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppSelect<int>(
                initialValue: state.dataBits,
                options: [
                  for (final bits in [8, 7, 6, 5]) (bits, '$bits'),
                ],
                label: l10n.dataBits,
                onChanged: controller.setDataBits,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppSelect<int>(
                initialValue: state.stopBits,
                options: [
                  for (final bits in [1, 2]) (bits, '$bits'),
                ],
                label: l10n.stopBits,
                onChanged: controller.setStopBits,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppSelect<UiParity>(
                initialValue: state.parity,
                options: [
                  (UiParity.none, l10n.parityNone),
                  (UiParity.odd, l10n.parityOdd),
                  (UiParity.even, l10n.parityEven),
                ],
                label: l10n.parity,
                onChanged: controller.setParity,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

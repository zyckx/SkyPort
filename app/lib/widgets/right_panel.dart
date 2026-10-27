import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../l10n/app_localizations.dart';
import 'right_panel/chart_view.dart';
import 'right_panel/receive_display_widget.dart';
import 'right_panel/send_input_widget.dart';
import 'ui/ui.dart';

enum _WorkspaceView { receive, chart }

class RightPanel extends StatefulWidget {
  const RightPanel({super.key});

  @override
  State<RightPanel> createState() => _RightPanelState();
}

class _RightPanelState extends State<RightPanel> {
  _WorkspaceView _view = _WorkspaceView.receive;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSegmented<_WorkspaceView>(
            selected: _view,
            onChanged: (view) => setState(() => _view = view),
            segments: [
              (
                _WorkspaceView.receive,
                LucideIcons.messageSquareText,
                l10n.receiveTab,
              ),
              (_WorkspaceView.chart, LucideIcons.chartLine, l10n.chartTab),
            ],
          ),
          const SizedBox(height: 8),
          // Both views stay mounted so scroll position and chart state persist.
          Expanded(
            child: IndexedStack(
              index: _view.index,
              sizing: StackFit.expand,
              children: const [ReceiveDisplayWidget(), ChartView()],
            ),
          ),
          const SizedBox(height: 8),
          const SendInputWidget(),
        ],
      ),
    );
  }
}

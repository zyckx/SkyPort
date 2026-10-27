import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/ui_settings_provider.dart';
import '../ui/ui.dart';

class ReceiveSettingsWidget extends ConsumerWidget {
  const ReceiveSettingsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(uiSettingsProvider);
    final notifier = ref.read(uiSettingsProvider.notifier);

    return Column(
      children: [
        AppSwitchRow(
          label: AppLocalizations.of(context).hexDisplay,
          icon: LucideIcons.binary,
          value: settings.hexDisplay,
          onChanged: (v) => notifier.setHexDisplay(v),
        ),
        AppSwitchRow(
          label: AppLocalizations.of(context).showTimestamp,
          icon: LucideIcons.clock,
          value: settings.showTimestamp,
          onChanged: (v) => notifier.setShowTimestamp(v),
        ),
        AppSwitchRow(
          label: AppLocalizations.of(context).showSent,
          icon: LucideIcons.arrowUpRight,
          value: settings.showSent,
          onChanged: (v) => notifier.setShowSent(v),
        ),
      ],
    );
  }
}

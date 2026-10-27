import 'package:flutter/material.dart' show SelectableText;
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../utils/error_messages.dart';
import '../ui/ui.dart';

void showErrorNotice(BuildContext context, Object error, {String? message}) {
  final l10n = AppLocalizations.of(context);
  showAppToast(
    context,
    message ?? localizedError(l10n, error),
    destructive: true,
    actionLabel: l10n.diagnosticDetails,
    onAction: () => showErrorDetails(context, error),
  );
}

Future<void> showErrorDetails(BuildContext context, Object error) {
  final l10n = AppLocalizations.of(context);
  return showAppDialog<void>(
    context,
    title: l10n.diagnosticDetails,
    actions: [
      Builder(
        builder: (context) => ShadButton.outline(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ),
    ],
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 420),
      child: SingleChildScrollView(
        child: SelectableText(errorDiagnostics(error)),
      ),
    ),
  );
}

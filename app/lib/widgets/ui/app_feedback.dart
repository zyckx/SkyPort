import 'package:flutter/material.dart' show SelectableText;
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// How long a toast stays visible unless closed manually.
const kAppToastDuration = Duration(seconds: 4);

/// Shows a transient toast. [actionLabel] adds an inline action button.
void showAppToast(
  BuildContext context,
  String message, {
  bool destructive = false,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final toaster = ShadToaster.maybeOf(context);
  if (toaster == null) return;
  final action = actionLabel == null
      ? null
      : ShadButton.outline(
          size: ShadButtonSize.sm,
          onPressed: () {
            toaster.hide();
            onAction?.call();
          },
          child: Text(actionLabel),
        );
  toaster.show(
    destructive
        ? ShadToast.destructive(
            description: SelectableText(message),
            action: action,
            duration: kAppToastDuration,
            showCloseIconOnlyWhenHovered: false,
          )
        : ShadToast(
            description: SelectableText(message),
            action: action,
            duration: kAppToastDuration,
            showCloseIconOnlyWhenHovered: false,
          ),
  );
}

/// Shows a modal dialog with a title, body and action buttons.
Future<T?> showAppDialog<T>(
  BuildContext context, {
  required String title,
  required Widget child,
  List<Widget> actions = const [],
  double maxWidth = 640,
}) {
  return showShadDialog<T>(
    context: context,
    builder: (context) => ShadDialog(
      title: Text(title),
      constraints: BoxConstraints(maxWidth: maxWidth),
      actions: actions,
      child: child,
    ),
  );
}

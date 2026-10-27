import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Hover tooltip with a plain-text message; empty messages render [child] only.
class AppTooltip extends StatelessWidget {
  const AppTooltip({super.key, required this.message, required this.child});

  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return child;
    return Semantics(
      tooltip: message,
      child: ShadTooltip(
        builder: (context) => ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Text(message),
        ),
        child: child,
      ),
    );
  }
}

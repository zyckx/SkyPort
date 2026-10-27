import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../l10n/app_localizations.dart';
import 'ui/ui.dart';

/// Pages hosted in the collapsible configuration drawer.
enum WorkspacePage { port, commands, tools, settings }

class NavRail extends StatelessWidget {
  const NavRail({
    super.key,
    required this.panelOpen,
    required this.page,
    required this.onSelect,
  });

  static const double width = 80;

  final bool panelOpen;
  final WorkspacePage page;
  final ValueChanged<WorkspacePage> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget entry(WorkspacePage value, IconData icon, String label) =>
        _RailEntry(
          icon: icon,
          label: label,
          selected: panelOpen && page == value,
          onPressed: () => onSelect(value),
        );
    return SizedBox(
      width: width,
      child: Column(
        children: [
          const SizedBox(height: 8),
          entry(WorkspacePage.port, LucideIcons.cable, l10n.serialPageLabel),
          entry(
            WorkspacePage.commands,
            LucideIcons.listChecks,
            l10n.quickCommandsPageLabel,
          ),
          entry(WorkspacePage.tools, LucideIcons.wrench, l10n.toolsPageLabel),
          const Spacer(),
          entry(
            WorkspacePage.settings,
            LucideIcons.settings,
            l10n.settingsPageLabel,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _RailEntry extends StatefulWidget {
  const _RailEntry({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  State<_RailEntry> createState() => _RailEntryState();
}

class _RailEntryState extends State<_RailEntry> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final colors = theme.colorScheme;
    final foreground = widget.selected
        ? colors.foreground
        : colors.mutedForeground;
    final background = widget.selected
        ? colors.secondary
        : _hovered || _focused
        ? colors.accent
        : const Color(0x00000000);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: AppTooltip(
        message: widget.label,
        child: Semantics(
          button: true,
          selected: widget.selected,
          label: widget.label,
          excludeSemantics: true,
          child: FocusableActionDetector(
            mouseCursor: SystemMouseCursors.click,
            onShowHoverHighlight: (value) => setState(() => _hovered = value),
            onShowFocusHighlight: (value) => setState(() => _focused = value),
            actions: {
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (_) {
                  widget.onPressed();
                  return null;
                },
              ),
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onPressed,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                height: 56,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: theme.radius,
                ),
                child: Stack(
                  children: [
                    if (widget.selected)
                      PositionedDirectional(
                        start: 0,
                        top: 14,
                        bottom: 14,
                        child: Container(
                          width: 3,
                          decoration: BoxDecoration(
                            color: colors.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(widget.icon, size: 18, color: foreground),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Text(
                              widget.label,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.small.copyWith(
                                fontSize: 11,
                                color: foreground,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

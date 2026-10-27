import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import 'ui/ui.dart';

String languageLabel(AppLanguage language, AppLocalizations l10n) =>
    language.nativeName ?? l10n.followSystem;

/// Settings-page language selector.
class LanguageSelect extends ConsumerWidget {
  const LanguageSelect({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return AppSelect<AppLanguage>(
      key: const ValueKey('language-select'),
      label: l10n.language,
      showLabel: false,
      initialValue: ref.watch(languageProvider),
      options: [
        for (final language in AppLanguage.values)
          (language, languageLabel(language, l10n)),
      ],
      onChanged: ref.read(languageProvider.notifier).setLanguage,
    );
  }
}

/// Compact title-bar button that opens a language menu.
class LanguageMenuButton extends ConsumerStatefulWidget {
  const LanguageMenuButton({super.key});

  @override
  ConsumerState<LanguageMenuButton> createState() => _LanguageMenuButtonState();
}

class _LanguageMenuButtonState extends ConsumerState<LanguageMenuButton> {
  final _popover = ShadPopoverController();

  @override
  void dispose() {
    _popover.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final current = ref.watch(languageProvider);
    return ShadPopover(
      controller: _popover,
      padding: const EdgeInsets.all(4),
      popover: (context) => SizedBox(
        width: 168,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final language in AppLanguage.values)
              ShadButton.ghost(
                key: ValueKey('language-option-${language.name}'),
                height: 32,
                mainAxisAlignment: MainAxisAlignment.start,
                onPressed: () {
                  _popover.hide();
                  ref.read(languageProvider.notifier).setLanguage(language);
                },
                leading: SizedBox.square(
                  dimension: 16,
                  child: language == current
                      ? const Icon(LucideIcons.check, size: 14)
                      : null,
                ),
                child: Expanded(
                  child: Text(
                    languageLabel(language, l10n),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.small,
                  ),
                ),
              ),
          ],
        ),
      ),
      // The tooltip would cover the open menu, so it only shows when closed.
      child: ListenableBuilder(
        listenable: _popover,
        builder: (context, _) => AppIconButton(
          key: const ValueKey('language-menu-button'),
          icon: LucideIcons.languages,
          tooltip: _popover.isOpen ? '' : l10n.language,
          size: 32,
          onPressed: _popover.toggle,
        ),
      ),
    );
  }
}

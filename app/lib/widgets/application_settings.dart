import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../l10n/app_localizations.dart';
import '../providers/ui_controller.dart';
import '../providers/ui_settings_provider.dart';
import '../providers/theme_provider.dart';
import 'language_menu.dart';
import 'theme_color_setting.dart';
import 'ui/ui.dart';

class ApplicationSettings extends ConsumerStatefulWidget {
  /// Owned by the host page so an unsubmitted draft survives page switches.
  final TextEditingController controller;

  const ApplicationSettings({super.key, required this.controller});

  @override
  ConsumerState<ApplicationSettings> createState() =>
      _ApplicationSettingsState();
}

class _ApplicationSettingsState extends ConsumerState<ApplicationSettings> {
  String? _bufferError;

  bool get _isDesktop =>
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS;

  void _submitBuffer(AppLocalizations l10n) {
    final size = int.tryParse(widget.controller.text.trim());
    if (size == null || size < 16 || size > 512) {
      setState(() => _bufferError = l10n.logBufferSizeError);
      return;
    }
    setState(() => _bufferError = null);
    ref.read(uiControllerProvider.notifier).setLogCapacity(size);
  }

  Future<void> _chooseExportDirectory() async {
    final path = await getDirectoryPath();
    if (path != null) {
      ref.read(uiSettingsProvider.notifier).setLogExportPath(path);
    }
  }

  Future<void> _setDynamicColor(bool enabled, AppLocalizations l10n) async {
    try {
      await ref.read(dynamicColorEnabledProvider.notifier).setEnabled(enabled);
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'SkyPort theme settings',
        ),
      );
      if (mounted) {
        showAppToast(context, l10n.themeColorSaveFailed, destructive: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final autoReconnect = ref.watch(
      uiControllerProvider.select((state) => state.autoReconnect),
    );
    final controllerNotifier = ref.read(uiControllerProvider.notifier);
    final uiSettings = ref.watch(uiSettingsProvider);
    final dynamicColorEnabled = ref.watch(dynamicColorEnabledProvider);
    final manualSeed = ref.watch(themeColorProvider);
    final hasManualSeed = ref.watch(hasManualThemeColorProvider);
    final systemAccent = ref.watch(systemAccentColorProvider);
    final showManualColor =
        resolveThemeColor(
          dynamicEnabled: dynamicColorEnabled,
          manualSeed: hasManualSeed ? manualSeed : null,
          systemAccent: systemAccent,
          brightness: theme.brightness,
        ).source !=
        ThemeColorSource.system;
    final supportsSystemAccent =
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;
    final exportLabel = uiSettings.logExportPath.isEmpty
        ? l10n.exportPathHint
        : uiSettings.logExportPath;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSection(
          title: l10n.settingsAppearance,
          icon: LucideIcons.paintbrush,
          children: [
            _SettingBlock(
              icon: LucideIcons.languages,
              title: l10n.language,
              child: const LanguageSelect(),
            ),
            _SettingBlock(
              icon: LucideIcons.sunMoon,
              title: l10n.theme,
              child: AppSelect<ThemeMode>(
                label: l10n.theme,
                showLabel: false,
                initialValue: ref.watch(themeModeProvider),
                options: [
                  (ThemeMode.system, l10n.followSystem),
                  (ThemeMode.light, l10n.light),
                  (ThemeMode.dark, l10n.dark),
                ],
                onChanged: ref.read(themeModeProvider.notifier).setThemeMode,
              ),
            ),
            if (supportsSystemAccent)
              _SettingBlock(
                icon: LucideIcons.swatchBook,
                title: l10n.dynamicColor,
                trailing: AppSwitch(
                  key: const ValueKey('dynamic-color-switch'),
                  label: l10n.dynamicColor,
                  value: dynamicColorEnabled,
                  onChanged: (enabled) => _setDynamicColor(enabled, l10n),
                ),
              ),
            if (showManualColor) const ThemeColorSetting(),
          ],
        ),
        AppSection(
          title: l10n.settingsConnection,
          icon: LucideIcons.plug,
          children: [
            _SettingBlock(
              icon: LucideIcons.refreshCw,
              title: l10n.autoReconnect,
              trailing: AppSwitch(
                key: const ValueKey('auto-reconnect-switch'),
                label: l10n.autoReconnect,
                value: autoReconnect,
                onChanged: controllerNotifier.setAutoReconnect,
              ),
            ),
          ],
        ),
        AppSection(
          title: l10n.settingsLogs,
          icon: LucideIcons.scrollText,
          children: [
            _SettingBlock(
              icon: LucideIcons.terminal,
              title: l10n.enableAnsi,
              trailing: AppSwitch(
                label: l10n.enableAnsi,
                value: uiSettings.enableAnsi,
                onChanged: ref.read(uiSettingsProvider.notifier).setEnableAnsi,
              ),
            ),
            _SettingBlock(
              icon: LucideIcons.database,
              title: l10n.logBufferSize,
              child: AppInput(
                key: const ValueKey('log-buffer-input'),
                controller: widget.controller,
                semanticLabel: l10n.logBufferSize,
                keyboardType: TextInputType.number,
                suffixText: 'MB',
                helperText: l10n.logBufferSizeHint,
                errorText: _bufferError,
                onSubmitted: (_) => _submitBuffer(l10n),
              ),
            ),
            if (_isDesktop)
              _SettingBlock(
                icon: LucideIcons.folderOpen,
                title: l10n.exportPath,
                child: AppTooltip(
                  message: exportLabel,
                  child: ShadButton.outline(
                    width: double.infinity,
                    mainAxisAlignment: MainAxisAlignment.start,
                    onPressed: _chooseExportDirectory,
                    trailing: const Icon(LucideIcons.chevronRight, size: 16),
                    child: Expanded(
                      child: Text(
                        exportLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// A settings row: icon and title, with an inline [trailing] control or a
/// full-width [child] control below.
class _SettingBlock extends StatelessWidget {
  const _SettingBlock({
    required this.icon,
    required this.title,
    this.trailing,
    this.child,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: theme.colorScheme.mutedForeground),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: theme.textTheme.small)),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
          if (child != null) ...[const SizedBox(height: 8), child!],
        ],
      ),
    );
  }
}

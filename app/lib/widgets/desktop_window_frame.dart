import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../l10n/app_localizations.dart';
import '../services/app_logger.dart';
import 'ui/ui.dart';

/// Widths shared with the native runners' title bar hit testing.
const double kCaptionButtonWidth = 46;
const double kTitlebarToolWidth = 46;

/// Smallest macOS bar; the runner reports the real native title bar height.
const double kMacTitlebarMinHeight = 28;

/// How the desktop runner decorates the window.
enum WindowFrameStyle {
  /// No custom frame; the platform draws everything.
  system,

  /// Undecorated window: Flutter draws the bar and the caption buttons.
  captionButtons,

  /// Transparent native title bar: Flutter draws the bar beside the traffic lights.
  macos;

  static WindowFrameStyle get platform => Platform.isMacOS
      ? macos
      : Platform.isWindows || Platform.isLinux
      ? captionButtons
      : system;
}

/// Windows/Linux native hit testing uses the same 48px bar and 46px widths.
class DesktopWindowFrame extends StatefulWidget {
  const DesktopWindowFrame({
    required this.child,
    this.tool,
    this.style,
    super.key,
  });
  final Widget child;

  /// Optional compact control shown at the trailing end of the bar.
  final Widget? tool;

  /// Defaults to [WindowFrameStyle.platform].
  final WindowFrameStyle? style;

  @override
  State<DesktopWindowFrame> createState() => _DesktopWindowFrameState();
}

typedef _WindowState = ({
  bool maximized,
  bool active,
  bool maximizeHovered,
  double titlebarHeight,
  double leadingInset,
});

class _DesktopWindowFrameState extends State<DesktopWindowFrame> {
  static const _channel = MethodChannel('skyport/window');
  ({String title, bool dark})? _configuration;
  _WindowState _window = (
    maximized: false,
    active: true,
    maximizeHovered: false,
    titlebarHeight: 0,
    leadingInset: 0,
  );
  bool _scheduled = false;

  WindowFrameStyle get _style => widget.style ?? WindowFrameStyle.platform;
  bool get _supported => _style != WindowFrameStyle.system;

  @override
  void initState() {
    super.initState();
    if (_supported) {
      _channel.setMethodCallHandler((call) async {
        if (call.method != 'windowState') throw MissingPluginException();
        _updateWindow(call.arguments as Map);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_supported) return;
    final configuration = (
      title: AppLocalizations.of(context).appTitle,
      dark: ShadTheme.of(context).brightness == Brightness.dark,
    );
    if (_configuration == configuration) return;
    _configuration = configuration;
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (mounted) unawaited(_configure());
    });
  }

  Future<void> _configure() async {
    final configuration = _configuration!;
    final result = await _invoke('configure', {
      'title': configuration.title,
      'dark': configuration.dark,
    });
    if (result != null && mounted) _updateWindow(result as Map);
  }

  void _updateWindow(Map value) {
    if (!mounted) return;
    final _WindowState window = (
      maximized: value['maximized'] as bool,
      active: value['active'] as bool,
      maximizeHovered: value['maximizeHovered'] as bool,
      // Reported by the macOS runner only.
      titlebarHeight: (value['titlebarHeight'] as num?)?.toDouble() ?? 0,
      leadingInset: (value['leadingInset'] as num?)?.toDouble() ?? 0,
    );
    if (_window != window) setState(() => _window = window);
  }

  Future<Object?> _invoke(String method, [Map<String, Object>? args]) async {
    try {
      return await _channel.invokeMethod<Object?>(method, args);
    } on PlatformException catch (error, stackTrace) {
      AppLogger.instance.error(
        'Native window action failed: $method',
        error: error,
        stackTrace: stackTrace,
      );
    } on MissingPluginException catch (error, stackTrace) {
      AppLogger.instance.error(
        'Native window channel is unavailable: $method',
        error: error,
        stackTrace: stackTrace,
      );
    }
    return null;
  }

  @override
  void dispose() {
    if (_supported) _channel.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_supported) return widget.child;
    final theme = ShadTheme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final foreground = _window.active
        ? colors.foreground
        : colors.mutedForeground;
    final mac = _style == WindowFrameStyle.macos;
    final height = mac
        ? math.max(_window.titlebarHeight, kMacTitlebarMinHeight)
        : 48.0;
    final iconSize = mac ? 16.0 : 22.0;
    Widget heading = Row(
      children: [
        SizedBox(width: mac ? math.max(_window.leadingInset, 12) : 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(mac ? 4 : 5),
          child: SvgPicture.asset(
            'assets/icon.svg',
            width: iconSize,
            height: iconSize,
            excludeFromSemantics: true,
          ),
        ),
        SizedBox(width: mac ? 8 : 10),
        Expanded(
          child: Text(
            l10n.appTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.large.copyWith(
              fontSize: mac ? 13 : 15,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ),
      ],
    );
    if (mac) {
      // Windows/Linux drag natively through hit testing; macOS asks the runner.
      heading = GestureDetector(
        key: const ValueKey('titlebar-drag-region'),
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) => unawaited(_invoke('startDrag')),
        onDoubleTap: () => unawaited(_invoke('titlebarDoubleClick')),
        child: SizedBox(height: height, child: heading),
      );
    }
    return Overlay.wrap(
      child: Column(
        children: [
          Container(
            height: height,
            decoration: BoxDecoration(
              color: colors.background,
              border: Border(bottom: BorderSide(color: colors.border)),
            ),
            child: Row(
              children: [
                Expanded(child: heading),
                // Native hit testing reserves this slot as client area.
                SizedBox(
                  width: kTitlebarToolWidth,
                  height: height,
                  child: Center(child: widget.tool),
                ),
                if (mac)
                  const SizedBox(width: 6)
                else ...[
                  _CaptionButton(
                    label: l10n.windowMinimize,
                    icon: LucideIcons.minus,
                    foreground: foreground,
                    onPressed: () => unawaited(_invoke('minimize')),
                  ),
                  _CaptionButton(
                    label: _window.maximized
                        ? l10n.windowRestore
                        : l10n.windowMaximize,
                    icon: _window.maximized
                        ? LucideIcons.copy
                        : LucideIcons.square,
                    foreground: foreground,
                    nativeHovered: _window.maximizeHovered,
                    onPressed: () => unawaited(_invoke('toggleMaximize')),
                  ),
                  _CaptionButton(
                    label: l10n.windowClose,
                    icon: LucideIcons.x,
                    foreground: foreground,
                    isClose: true,
                    onPressed: () => unawaited(_invoke('close')),
                  ),
                ],
              ],
            ),
          ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}

class _CaptionButton extends StatefulWidget {
  const _CaptionButton({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.onPressed,
    this.nativeHovered = false,
    this.isClose = false,
  });

  final String label;
  final IconData icon;
  final Color foreground;
  final VoidCallback onPressed;
  final bool nativeHovered;
  final bool isClose;

  @override
  State<_CaptionButton> createState() => _CaptionButtonState();
}

class _CaptionButtonState extends State<_CaptionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = ShadTheme.of(context).colorScheme;
    final hovered = _hovered || widget.nativeHovered;
    final closeHot = widget.isClose && _hovered;
    return Semantics(
      button: true,
      label: widget.label,
      child: AppTooltip(
        message: widget.label,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onPressed,
            child: Container(
              width: kCaptionButtonWidth,
              height: 48,
              color: closeHot
                  ? const Color(0xffc42b1c)
                  : hovered
                  ? colors.accent
                  : const Color(0x00000000),
              child: Icon(
                widget.icon,
                size: 16,
                color: closeHot ? const Color(0xffffffff) : widget.foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_app.dart';
import 'package:skyport/l10n/app_localizations.dart';
import 'package:skyport/widgets/desktop_window_frame.dart';
import 'package:skyport/theme.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

const _channel = MethodChannel('skyport/window');
const _codec = StandardMethodCodec();

Future<void> _notifyWindow(
  WidgetTester tester, {
  required bool maximized,
}) async {
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    _channel.name,
    _codec.encodeMethodCall(
      MethodCall('windowState', {
        'maximized': maximized,
        'active': true,
        'maximizeHovered': maximized,
      }),
    ),
    (_) {},
  );
  await tester.pumpAndSettle();
}

Widget _frame({WindowFrameStyle? style, Widget? tool}) => ShadTheme(
  data: getShadLightTheme(),
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) =>
        DesktopWindowFrame(style: style, tool: tool, child: child!),
    home: const Scaffold(body: Text('serial content')),
  ),
);

void main() {
  testWidgets(
    'external maximize and restore update the available caption action',
    (tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        _channel,
        (call) async => {
          'maximized': false,
          'active': true,
          'maximizeHovered': false,
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          _channel,
          null,
        ),
      );
      await tester.pumpWidget(_frame());
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(DesktopWindowFrame)),
      );
      expect(findTooltip(l10n.windowMaximize), findsOneWidget);
      expect(findTooltip(l10n.windowRestore), findsNothing);

      await _notifyWindow(tester, maximized: true);
      expect(findTooltip(l10n.windowRestore), findsOneWidget);
      expect(findTooltip(l10n.windowMaximize), findsNothing);
      expect(find.text('serial content'), findsOneWidget);

      await _notifyWindow(tester, maximized: false);
      expect(findTooltip(l10n.windowMaximize), findsOneWidget);
      expect(findTooltip(l10n.windowRestore), findsNothing);
    },
  );

  testWidgets(
    'macOS frame leaves the traffic lights to the runner and drags natively',
    (tester) async {
      final calls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(_channel, (
        call,
      ) async {
        calls.add(call.method);
        return {
          'maximized': false,
          'active': true,
          'maximizeHovered': false,
          'titlebarHeight': 28.0,
          'leadingInset': 80.0,
        };
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          _channel,
          null,
        ),
      );
      await tester.pumpWidget(
        _frame(
          style: WindowFrameStyle.macos,
          tool: const SizedBox(key: ValueKey('frame-tool')),
        ),
      );
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(DesktopWindowFrame)),
      );
      expect(calls, ['configure']);
      for (final caption in [
        l10n.windowMinimize,
        l10n.windowMaximize,
        l10n.windowClose,
      ]) {
        expect(findTooltip(caption), findsNothing);
      }
      expect(find.byKey(const ValueKey('frame-tool')), findsOneWidget);
      final region = find.byKey(const ValueKey('titlebar-drag-region'));
      // The native 28px title bar, minus the bar's 1px divider.
      expect(tester.getSize(region).height, 27);
      // The title starts after the reported traffic-light inset.
      expect(
        tester.getTopLeft(find.byType(SvgPicture)).dx,
        greaterThanOrEqualTo(80),
      );

      await tester.drag(region, const Offset(40, 0));
      await tester.pumpAndSettle();
      expect(calls.last, 'startDrag');

      await tester.tap(region);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(region);
      await tester.pumpAndSettle();
      expect(calls.last, 'titlebarDoubleClick');
      expect(find.text('serial content'), findsOneWidget);
    },
  );
}

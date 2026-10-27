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

Widget _frame() => ShadTheme(
  data: getShadLightTheme(),
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => DesktopWindowFrame(child: child!),
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
}

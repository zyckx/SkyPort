import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skyport/models/quick_command.dart';
import 'package:skyport/models/ui_state.dart';
import 'package:skyport/providers/common_providers.dart';
import 'package:skyport/providers/quick_commands_provider.dart';
import 'package:skyport/providers/ui_controller.dart';
import 'package:skyport/widgets/left_panel/modem_lines_widget.dart';
import 'package:skyport/widgets/pages/quick_commands_page.dart';
import 'package:skyport/widgets/pages/tools_page.dart';

import '../helpers/test_app.dart';
import 'package:skyport/widgets/ui/ui.dart';
import 'right_panel/receive_display_widget_test.dart' show ReceiveController;

class _CommandController extends ReceiveController {
  final sent = <(String, bool, UiNewline)>[];

  @override
  Future<void> sendCommand(
    String payload, {
    required bool hex,
    required UiNewline newline,
  }) async => sent.add((payload, hex, newline));

  final loops = <(bool, int, int)>[];
  final lines = <(bool?, bool?)>[];

  @override
  Future<void> setSequenceSend({
    required bool enabled,
    required int intervalMs,
    required List<QuickCommand> commands,
  }) async => loops.add((enabled, intervalMs, commands.length));

  @override
  Future<void> setModemLines({bool? dtr, bool? rts}) async =>
      lines.add((dtr, rts));
}

Future<void> _enter(WidgetTester tester, String key, String text) =>
    tester.enterText(findInputText(ValueKey(key)), text);

void main() {
  testWidgets('checksum tool computes values for Hex input', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 1200);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      shadTestApp(home: const Scaffold(body: ToolsPage())),
    );

    await _enter(tester, 'checksum-input', '31 32 33 34 35 36 37 38 39');
    await tester.pump();
    expect(find.text('4B 37'), findsOneWidget); // CRC-16/MODBUS
    expect(find.text('CB F4 39 26'), findsOneWidget); // CRC-32

    await _enter(tester, 'checksum-input', '313');
    await tester.pump();
    expect(find.text('4B 37'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('number base tool converts across radixes', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 1200);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      shadTestApp(home: const Scaffold(body: ToolsPage())),
    );
    await tester.ensureVisible(find.byKey(const ValueKey('number-input')));
    await _enter(tester, 'number-input', '255');
    await tester.pump();
    expect(find.text('11111111'), findsOneWidget);
    expect(find.text('FF'), findsOneWidget);
    expect(find.text('377'), findsOneWidget);
  });

  testWidgets('quick commands are added, then sent with their own encoding', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final controller = _CommandController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          uiControllerProvider.overrideWith(() => controller),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: shadTestApp(
          home: const Scaffold(
            body: SizedBox(width: 310, child: QuickCommandsPage()),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('quick-command-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('quick-command-save')));
    await tester.pumpAndSettle();
    // Empty content is rejected and the dialog stays open.
    expect(find.byKey(const ValueKey('quick-command-save')), findsOneWidget);

    await _enter(tester, 'quick-command-name', 'Read regs');
    await _enter(tester, 'quick-command-payload', '01 03 00 00 00 0A');
    await tester.tap(find.byType(ShadSelect<bool>));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ShadOption<bool>, 'Hex'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('quick-command-save')));
    await tester.pumpAndSettle();

    final commands = ProviderScope.containerOf(
      tester.element(find.byType(QuickCommandsPage)),
    ).read(quickCommandsProvider);
    expect(commands.single.name, 'Read regs');
    expect(commands.single.hex, isTrue);
    expect(find.text('Read regs'), findsOneWidget);

    await tester.tap(
      find.byKey(ValueKey('quick-command-send-${commands.single.id}')),
    );
    await tester.pump();
    expect(controller.sent, [('01 03 00 00 00 0A', true, UiNewline.none)]);
    expect(tester.takeException(), isNull);
  });
  testWidgets('loop bar submits the whole list and the interval', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      QuickCommandsNotifier.storageKey:
          '[{"id":"a","name":"a","payload":"AT","hex":false,"newline":"crlf"},'
          '{"id":"b","name":"b","payload":"01","hex":true,"newline":"none"}]',
    });
    final prefs = await SharedPreferences.getInstance();
    final controller = _CommandController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          uiControllerProvider.overrideWith(() => controller),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: shadTestApp(
          home: const Scaffold(
            body: SizedBox(width: 310, child: QuickCommandsPage()),
          ),
        ),
      ),
    );
    await _enter(tester, 'sequence-interval', '0.25');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('sequence-toggle')));
    await tester.pump();
    expect(controller.loops, [(true, 250, 2)]);

    await _enter(tester, 'sequence-interval', '0');
    await tester.pump();
    final toggle = tester.widget<AppIconButton>(
      find.byKey(const ValueKey('sequence-toggle')),
    );
    expect(toggle.onPressed, isNull);
  });

  testWidgets('modem switches request single-line changes', (tester) async {
    final controller = _CommandController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [uiControllerProvider.overrideWith(() => controller)],
        child: shadTestApp(
          home: const Scaffold(
            body: SizedBox(width: 300, child: ModemLinesWidget()),
          ),
        ),
      ),
    );
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('dtr-switch')),
        matching: find.byType(ShadSwitch),
      ),
    );
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('rts-switch')),
        matching: find.byType(ShadSwitch),
      ),
    );
    expect(controller.lines, [(true, null), (null, true)]);
  });
}

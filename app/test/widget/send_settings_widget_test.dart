import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_app.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:skyport/models/log_model.dart';
import 'package:skyport/models/ui_state.dart';
import 'package:skyport/providers/ui_controller.dart';
import 'package:skyport/widgets/left_panel/send_settings_widget.dart';

class _SendController extends UiController {
  bool append = false;
  bool hexMode = false;
  UiNewline mode = UiNewline.crlf;

  @override
  UiState build() => _snapshot();

  UiState _snapshot() => UiState(
    sequence: 0,
    connection: UiConnection.disconnected,
    portName: '',
    baudRate: 115200,
    dataBits: 8,
    parity: UiParity.none,
    flowControl: UiFlowControl.none,
    stopBits: 1,
    autoReconnect: false,
    hexSend: hexMode,
    newline: mode,
    appendNewline: append,
    autoSendEnabled: false,
    autoSendIntervalMs: 1000,
    logCapacityBytes: 1024,
    sendHistory: const [],
    autoSendInput: '',
    ports: const [],
    rxBytes: 0,
    txBytes: 0,
    lastRxBytes: 0,
    error: null,
    logs: const LogState(),
    trimmedBytes: 0,
    trimmedRecords: 0,
    logIncomplete: false,
  );

  void update({required bool hex}) {
    hexMode = hex;
    state = _snapshot();
  }

  @override
  Future<void> setSendSettings({
    bool? hex,
    UiNewline? newline,
    bool? appendNewline,
    bool? enabled,
    int? intervalMs,
    String? input,
  }) async {
    // None is not a valid stored newline: disabling must retain the mode.
    expect(newline, isNot(UiNewline.none));
    mode = newline ?? mode;
    append = appendNewline ?? append;
    state = _snapshot();
  }
}

void main() {
  testWidgets('None disables appending and selecting a mode enables it', (
    tester,
  ) async {
    final controller = _SendController();
    final container = ProviderContainer(
      overrides: [uiControllerProvider.overrideWith(() => controller)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: shadTestApp(
          home: const Scaffold(
            body: SizedBox(width: 280, child: SendSettingsWidget()),
          ),
        ),
      ),
    );

    final dropdown = find.byType(ShadSelect<UiNewline>);
    Finder selected(String label) =>
        find.descendant(of: dropdown, matching: find.text(label));
    Future<void> choose(String label) async {
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ShadOption<UiNewline>, label));
      await tester.pumpAndSettle();
    }

    expect(selected('None'), findsOneWidget);
    await choose(r'LF (\n)');
    expect(controller.append, isTrue);
    expect(controller.mode, UiNewline.lf);
    expect(selected(r'LF (\n)'), findsOneWidget);

    await choose('None');
    expect(controller.append, isFalse);
    expect(controller.mode, UiNewline.lf);
    expect(selected('None'), findsOneWidget);

    await choose(r'CRLF (\r\n)');
    expect(controller.append, isTrue);
    expect(controller.mode, UiNewline.crlf);
    expect(selected(r'CRLF (\r\n)'), findsOneWidget);

    controller.update(hex: true);
    await tester.pumpAndSettle();
    expect(tester.widget<ShadSelect<UiNewline>>(dropdown).enabled, isFalse);
    controller.update(hex: false);
    await tester.pumpAndSettle();
    expect(selected(r'CRLF (\r\n)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

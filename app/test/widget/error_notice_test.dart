import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:skyport/host_core.dart';
import 'package:skyport/l10n/app_localizations.dart';
import 'package:skyport/main.dart';
import 'package:skyport/src/rust/api.dart' as rust;
import 'package:skyport/widgets/shared/error_notice.dart';

import '../helpers/test_app.dart';

Widget _trigger(Object error) => Builder(
  builder: (context) => GestureDetector(
    onTap: () => showErrorNotice(context, error),
    child: const Icon(Icons.warning),
  ),
);

void main() {
  testWidgets('error notices expire and can be closed manually', (
    tester,
  ) async {
    await tester.pumpWidget(
      shadTestApp(home: Scaffold(body: _trigger(StateError('failure')))),
    );

    await tester.tap(find.byIcon(Icons.warning));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(ShadToast), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.byType(ShadToast), findsNothing);

    await tester.tap(find.byIcon(Icons.warning));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(ShadToast),
        matching: find.byIcon(LucideIcons.x),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ShadToast), findsNothing);
  });

  testWidgets(
    'partial writes keep byte progress and reveal raw diagnostics only on request',
    (tester) async {
      const rawMessage = 'native failure /dev/private-port';
      const error = rust.CoreError(
        kind: rust.ErrorKind.timeout,
        message: rawMessage,
        bytesWritten: 42,
      );
      await tester.pumpWidget(
        shadTestApp(
          locale: const Locale('zh'),
          home: Scaffold(body: _trigger(error)),
        ),
      );
      await tester.tap(find.byIcon(Icons.warning));
      await tester.pumpAndSettle();
      final notice = tester
          .widget<SelectableText>(
            find.descendant(
              of: find.byType(ShadToast),
              matching: find.byType(SelectableText),
            ),
          )
          .data!;
      expect(notice, contains('42'));
      expect(notice, matches(RegExp(r'[一-鿿]')));
      expect(notice, isNot(contains(rawMessage)));
      final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)));
      await tester.tap(find.text(l10n.diagnosticDetails));
      await tester.pumpAndSettle();
      final diagnostics = tester
          .widget<SelectableText>(
            find.descendant(
              of: find.byType(ShadDialog),
              matching: find.byType(SelectableText),
            ),
          )
          .data!;
      expect(diagnostics, contains(rawMessage));
      expect(diagnostics, contains('42'));
      expect(diagnostics, contains('timeout'));
    },
  );

  testWidgets(
    'startup summaries follow locale without exposing or losing the cause',
    (tester) async {
      final cause = StateError('private migration diagnostic');
      final locale = ValueNotifier(const Locale('zh'));
      addTearDown(locale.dispose);
      await tester.pumpWidget(
        ValueListenableBuilder<Locale>(
          valueListenable: locale,
          builder: (_, value, _) => shadTestApp(
            locale: value,
            home: StartupFailurePage(
              details: HostStartupException(
                HostFailure.preferenceMigration,
                cause,
              ),
            ),
          ),
        ),
      );
      final chinese = tester
          .widget<SelectableText>(find.byType(SelectableText))
          .data!;
      expect(chinese, matches(RegExp(r'[一-鿿]')));
      expect(chinese, isNot(contains(cause.message)));
      locale.value = const Locale('en');
      await tester.pumpAndSettle();
      final english = tester
          .widget<SelectableText>(find.byType(SelectableText))
          .data!;
      expect(english, isNot(chinese));
      expect(english, isNot(matches(RegExp(r'[一-鿿]'))));
      expect(english, isNot(contains(cause.message)));
      await tester.tap(find.byType(ShadButton));
      await tester.pumpAndSettle();
      final diagnostics = tester
          .widget<SelectableText>(
            find.descendant(
              of: find.byType(ShadDialog),
              matching: find.byType(SelectableText),
            ),
          )
          .data!;
      expect(diagnostics, contains(cause.message));
    },
  );
}

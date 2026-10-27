import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skyport/models/quick_command.dart';
import 'package:skyport/models/ui_state.dart';
import 'package:skyport/providers/common_providers.dart';
import 'package:skyport/providers/quick_commands_provider.dart';

QuickCommand _command(String id, {bool hex = false}) => QuickCommand(
  id: id,
  name: 'cmd $id',
  payload: hex ? '01 02' : 'AT+$id',
  hex: hex,
  newline: hex ? UiNewline.none : UiNewline.crlf,
);

Future<ProviderContainer> _container([
  Map<String, Object> values = const {},
]) async {
  SharedPreferences.setMockInitialValues(values);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('commands round-trip through JSON', () {
    final command = _command('a');
    expect(QuickCommand.fromJson(command.toJson()), command);
  });

  test('add, edit, move and remove persist across restarts', () async {
    final container = await _container();
    final notifier = container.read(quickCommandsProvider.notifier);
    notifier.add(_command('a'));
    notifier.add(_command('b', hex: true));
    notifier.add(_command('c'));
    notifier.replace(_command('b').copyWith(name: 'renamed'));
    notifier.move(2, 0);
    notifier.remove('a');

    final prefs = container.read(sharedPreferencesProvider);
    final restarted = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(restarted.dispose);
    final ids = restarted.read(quickCommandsProvider).map((c) => c.id);
    expect(ids, ['c', 'b']);
    expect(restarted.read(quickCommandsProvider).last.name, 'renamed');
  });

  test('malformed storage keeps valid entries and survives bad JSON', () async {
    final good = _command('ok').toJson();
    var container = await _container({
      QuickCommandsNotifier.storageKey: jsonEncode([
        good,
        {'id': 1},
        'junk',
      ]),
    });
    expect(container.read(quickCommandsProvider).single.id, 'ok');

    container = await _container({QuickCommandsNotifier.storageKey: '{oops'});
    expect(container.read(quickCommandsProvider), isEmpty);
  });

  test('the list is capped', () async {
    final container = await _container();
    final notifier = container.read(quickCommandsProvider.notifier);
    for (var i = 0; i < QuickCommandsNotifier.maxCommands; i++) {
      expect(notifier.add(_command('$i')), isTrue);
    }
    expect(notifier.add(_command('overflow')), isFalse);
    expect(
      container.read(quickCommandsProvider),
      hasLength(QuickCommandsNotifier.maxCommands),
    );
  });
}

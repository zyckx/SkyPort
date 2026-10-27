import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/quick_command.dart';
import 'common_providers.dart';

/// The saved quick-command list, persisted as a frontend preference.
class QuickCommandsNotifier extends Notifier<List<QuickCommand>> {
  static const String storageKey = 'quick_commands';

  /// Upper bound so a corrupted or runaway list cannot bloat preferences.
  static const int maxCommands = 200;

  @override
  List<QuickCommand> build() {
    final raw = ref.read(sharedPreferencesProvider).getString(storageKey);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return List.unmodifiable(
        decoded
            .map(QuickCommand.fromJson)
            .whereType<QuickCommand>()
            .take(maxCommands),
      );
    } on FormatException {
      return const [];
    }
  }

  /// Adds [command] unless the list is full; returns whether it was added.
  bool add(QuickCommand command) {
    if (state.length >= maxCommands) return false;
    _set([...state, command]);
    return true;
  }

  void replace(QuickCommand command) => _set([
    for (final existing in state)
      existing.id == command.id ? command : existing,
  ]);

  void remove(String id) => _set([
    for (final existing in state)
      if (existing.id != id) existing,
  ]);

  /// Moves the item at [from] so that it ends up at index [to].
  void move(int from, int to) {
    if (from < 0 || from >= state.length) return;
    final items = [...state];
    final item = items.removeAt(from);
    items.insert(to.clamp(0, items.length), item);
    _set(items);
  }

  void _set(List<QuickCommand> commands) {
    state = List.unmodifiable(commands);
    ref
        .read(sharedPreferencesProvider)
        .setString(
          storageKey,
          jsonEncode([for (final command in commands) command.toJson()]),
        );
  }
}

final quickCommandsProvider =
    NotifierProvider<QuickCommandsNotifier, List<QuickCommand>>(
      QuickCommandsNotifier.new,
    );

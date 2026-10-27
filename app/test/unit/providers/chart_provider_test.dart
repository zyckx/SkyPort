import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skyport/providers/chart_provider.dart';
import 'package:skyport/providers/ui_controller.dart';
import 'package:skyport/src/rust/api.dart' as rust;
import 'package:skyport/utils/chart_parser.dart';

import '../../widget/right_panel/receive_display_widget_test.dart'
    show ReceiveController;

class _ChartController extends ReceiveController {
  int _nextId = 1;

  void lines(
    List<String> texts, {
    rust.Direction direction = rust.Direction.received,
  }) {
    state = state.withLogDelta(
      rust.LogDelta(
        upsert: [
          for (final text in texts)
            rust.LogRecord(
              id: _nextId++,
              timestampMs: 0,
              direction: direction,
              data: Uint8List.fromList(utf8.encode(text)),
              pending: false,
            ),
        ],
        removedIds: const [],
        earliestId: 1,
        totalBytes: 0,
        trimmedBytes: 0,
        trimmedRecords: 0,
        incomplete: false,
      ),
    );
  }

  void gap() => state = state.withDataGap(true);
}

void main() {
  late ProviderContainer container;
  late _ChartController controller;

  setUp(() {
    controller = _ChartController();
    container = ProviderContainer(
      overrides: [uiControllerProvider.overrideWith(() => controller)],
    );
    container.read(uiControllerProvider);
  });
  tearDown(() => container.dispose());

  ChartState chart() => container.read(chartProvider);

  test('plots numeric lines and counts non-numeric ones', () {
    chart();
    controller.lines(['1,2', 'hello', '3 4', 'temp:5 hum=6']);
    final state = chart();
    expect(state.rows.map((row) => row.values), [
      [1, 2],
      [3, 4],
      [5, 6],
    ]);
    expect(state.skippedLines, 1);
    expect(state.seriesNames, ['temp', 'hum']);
  });

  test('ignores sent records', () {
    chart();
    controller.lines(['9,9'], direction: rust.Direction.sent);
    expect(chart().rows, isEmpty);
  });

  test('pausing skips data and resuming marks a gap', () {
    chart();
    controller.lines(['1']);
    container.read(chartProvider.notifier).setPaused(true);
    controller.lines(['2']);
    expect(chart().rows.where((row) => !row.gap), hasLength(1));
    container.read(chartProvider.notifier).setPaused(false);
    controller.lines(['3']);
    final rows = chart().rows;
    expect(rows.map((row) => row.gap), [false, true, false]);
    expect(rows.last.values, [3]);
  });

  test('event data gaps break the series', () {
    chart();
    controller.lines(['1']);
    controller.gap();
    controller.lines(['2']);
    expect(chart().rows.map((row) => row.gap), [false, true, false]);
  });

  test('keeps a bounded window of the newest rows', () {
    chart();
    controller.lines([
      for (var i = 0; i < ChartNotifier.maxRows + 10; i++) '$i',
    ]);
    final rows = chart().rows;
    expect(rows, hasLength(ChartNotifier.maxRows));
    expect(rows.first.values, [10]);
  });

  test('clear empties rows without replaying old records', () {
    chart();
    controller.lines(['1', 'x']);
    container.read(chartProvider.notifier).clear();
    expect(chart().rows, isEmpty);
    expect(chart().skippedLines, 0);
    controller.lines(['2']);
    expect(chart().rows.single.values, [2]);
  });

  group('parseChartLine', () {
    Uint8List bytes(String text) => Uint8List.fromList(utf8.encode(text));

    test('rejects partially numeric and non-finite lines', () {
      expect(parseChartLine(bytes('1,abc')), isNull);
      expect(parseChartLine(bytes('NaN')), isNull);
      expect(parseChartLine(bytes('')), isNull);
      expect(parseChartLine(Uint8List.fromList([0xff])), isNull);
    });

    test('caps the number of series', () {
      final sample = parseChartLine(bytes('1 2 3 4'), maxSeries: 2)!;
      expect(sample.values, [1, 2]);
    });
  });
}

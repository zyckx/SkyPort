import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/log_model.dart';
import '../utils/chart_parser.dart';
import 'ui_controller.dart';

/// A plotted row; [gap] rows mark where data may be missing (log trimmed,
/// event data gap or cleared) so lines are not drawn across them.
class ChartRow {
  const ChartRow(this.values) : gap = false;
  const ChartRow.gap() : values = const [], gap = true;

  final List<double?> values;
  final bool gap;
}

class ChartState {
  const ChartState({
    this.rows = const [],
    this.seriesNames = const [],
    this.skippedLines = 0,
    this.paused = false,
    this.hidden = const {},
  });

  final List<ChartRow> rows;
  final List<String> seriesNames;

  /// Received lines that were not purely numeric.
  final int skippedLines;
  final bool paused;

  /// Series indices hidden from the plot.
  final Set<int> hidden;

  ChartState copyWith({
    List<ChartRow>? rows,
    List<String>? seriesNames,
    int? skippedLines,
    bool? paused,
    Set<int>? hidden,
  }) => ChartState(
    rows: rows ?? this.rows,
    seriesNames: seriesNames ?? this.seriesNames,
    skippedLines: skippedLines ?? this.skippedLines,
    paused: paused ?? this.paused,
    hidden: hidden ?? this.hidden,
  );
}

/// Projects completed received log records (one record per line, as split
/// by the core) into bounded numeric series. Read-only: it never alters the
/// retained or exported log.
class ChartNotifier extends Notifier<ChartState> {
  static const int maxRows = 2000;
  static const int maxSeries = 8;
  static const int _pendingId = 0xFFFFFFFFFFFFFFFF;

  final _rows = ListQueue<ChartRow>();
  int _lastId = -1;
  bool _dataGap = false;

  @override
  ChartState build() {
    _rows.clear();
    _lastId = -1;
    final ui = ref.read(uiControllerProvider);
    _dataGap = ui.dataGap;
    ref.listen(
      uiControllerProvider.select((s) => (logs: s.logs, dataGap: s.dataGap)),
      (_, next) => _ingest(next.logs, next.dataGap),
    );
    return _consume(const ChartState(), ui.logs);
  }

  void _ingest(LogState logs, bool dataGap) {
    var next = state;
    if (dataGap && !_dataGap) _addGap();
    _dataGap = dataGap;
    if (logs.chunks.isEmpty && _rows.isNotEmpty && !_rows.last.gap) {
      _addGap(); // The log was cleared; later data is not contiguous.
    }
    next = _consume(next, logs);
    state = next.copyWith(rows: List.unmodifiable(_rows));
  }

  ChartState _consume(ChartState current, LogState logs) {
    var names = current.seriesNames;
    var skipped = current.skippedLines;
    final fresh = <LogChunk>[];
    for (var i = logs.chunks.length - 1; i >= 0; i--) {
      final chunk = logs.chunks[i];
      if (chunk.id == _pendingId) continue; // Line still being received.
      if (chunk.id <= _lastId) break;
      fresh.add(chunk);
    }
    for (final chunk in fresh.reversed) {
      _lastId = chunk.id;
      if (current.paused) continue;
      for (final entry in chunk.rxEntries) {
        final sample = parseChartLine(entry.data, maxSeries: maxSeries);
        if (sample == null) {
          skipped++;
          continue;
        }
        if (sample.values.length > names.length || sample.labels.isNotEmpty) {
          names = [
            for (var s = 0; s < maxSeries; s++)
              if (s < sample.values.length || s < names.length)
                sample.labels[s] ??
                    (s < names.length ? names[s] : 'CH${s + 1}'),
          ];
        }
        _rows.add(ChartRow(sample.values));
        while (_rows.length > maxRows) {
          _rows.removeFirst();
        }
      }
    }
    return current.copyWith(
      rows: List.unmodifiable(_rows),
      seriesNames: names,
      skippedLines: skipped,
    );
  }

  void _addGap() {
    if (_rows.isEmpty || _rows.last.gap) return;
    _rows.add(const ChartRow.gap());
  }

  /// Pausing skips incoming lines; resuming continues from new data and
  /// marks the skipped interval as a gap.
  void setPaused(bool paused) {
    if (!paused) _addGap();
    state = state.copyWith(paused: paused, rows: List.unmodifiable(_rows));
  }

  void clear() {
    _rows.clear();
    state = state.copyWith(
      rows: const [],
      seriesNames: const [],
      skippedLines: 0,
      hidden: const {},
    );
  }

  void toggleSeries(int index) {
    final hidden = {...state.hidden};
    if (!hidden.remove(index)) hidden.add(index);
    state = state.copyWith(hidden: hidden);
  }
}

final chartProvider = NotifierProvider<ChartNotifier, ChartState>(
  ChartNotifier.new,
);

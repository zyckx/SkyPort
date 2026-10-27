import 'dart:convert';
import 'dart:typed_data';

/// One parsed line: a value (or null when absent) per series column, plus
/// labels found in `label:value` / `label=value` tokens.
typedef ChartSample = ({List<double?> values, Map<int, String> labels});

final _separators = RegExp(r'[,;\s]+');
final _labelled = RegExp(r'^([^:=]+)[:=](.+)$');

/// Parses a received line such as `1.5,2.0`, `12 34 56` or
/// `temp:23.5,hum=41`. Returns null if any token is not a finite number, so
/// partially numeric text is never plotted as data.
ChartSample? parseChartLine(Uint8List line, {int maxSeries = 8}) {
  final String text;
  try {
    text = utf8.decode(line);
  } on FormatException {
    return null;
  }
  final tokens = text.trim().split(_separators).where((t) => t.isNotEmpty);
  if (tokens.isEmpty) return null;
  final values = <double?>[];
  final labels = <int, String>{};
  for (final token in tokens) {
    var number = token;
    final match = _labelled.firstMatch(token);
    if (match != null) {
      labels[values.length] = match.group(1)!;
      number = match.group(2)!;
    }
    final value = double.tryParse(number);
    if (value == null || !value.isFinite) return null;
    if (values.length < maxSeries) values.add(value);
  }
  labels.removeWhere((index, _) => index >= maxSeries);
  return (values: values, labels: labels);
}

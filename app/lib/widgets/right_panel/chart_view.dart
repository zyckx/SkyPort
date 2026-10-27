import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/chart_provider.dart';
import '../ui/ui.dart';

/// Series colours; chosen to stay distinguishable in light and dark themes.
const List<Color> kChartPalette = [
  Color(0xff2563eb),
  Color(0xffdc2626),
  Color(0xff16a34a),
  Color(0xffd97706),
  Color(0xff9333ea),
  Color(0xff0891b2),
  Color(0xffdb2777),
  Color(0xff65a30d),
];

class ChartView extends ConsumerWidget {
  const ChartView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final colors = theme.colorScheme;
    final chart = ref.watch(chartProvider);
    final notifier = ref.read(chartProvider.notifier);
    final hasData = chart.rows.any((row) => !row.gap);
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (var i = 0; i < chart.seriesNames.length; i++)
                        _LegendChip(
                          key: ValueKey('chart-series-$i'),
                          label: chart.seriesNames[i],
                          color: kChartPalette[i % kChartPalette.length],
                          hidden: chart.hidden.contains(i),
                          onTap: () => notifier.toggleSeries(i),
                        ),
                    ],
                  ),
                ),
                if (chart.skippedLines > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: AppTooltip(
                      message: l10n.chartSkippedHint,
                      child: Text(
                        l10n.chartSkipped(chart.skippedLines),
                        style: theme.textTheme.muted.copyWith(fontSize: 11),
                      ),
                    ),
                  ),
                AppIconButton(
                  key: const ValueKey('chart-pause'),
                  icon: chart.paused ? LucideIcons.play : LucideIcons.pause,
                  tooltip: chart.paused ? l10n.chartResume : l10n.chartPause,
                  onPressed: () => notifier.setPaused(!chart.paused),
                ),
                AppIconButton(
                  key: const ValueKey('chart-clear'),
                  icon: LucideIcons.eraser,
                  tooltip: l10n.chartClear,
                  onPressed: hasData || chart.skippedLines > 0
                      ? notifier.clear
                      : null,
                ),
              ],
            ),
          ),
          Expanded(
            child: hasData
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 12, 12),
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: _ChartPainter(
                          rows: chart.rows,
                          hidden: chart.hidden,
                          grid: colors.border,
                          label: colors.mutedForeground,
                          gapColor: colors.destructive.withValues(alpha: 0.5),
                          textStyle: TextStyle(
                            color: colors.mutedForeground,
                            fontSize: 10,
                            fontFamily: theme.textTheme.family,
                          ),
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  )
                : Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.chartLine,
                            size: 28,
                            color: colors.mutedForeground,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            chart.paused
                                ? l10n.chartPausedEmpty
                                : l10n.chartEmpty,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.muted,
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    super.key,
    required this.label,
    required this.color,
    required this.hidden,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool hidden;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Semantics(
      button: true,
      toggled: !hidden,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: theme.colorScheme.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: hidden ? null : color,
                    border: Border.all(color: color),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: theme.textTheme.small.copyWith(
                    fontSize: 11,
                    color: hidden
                        ? theme.colorScheme.mutedForeground
                        : theme.colorScheme.foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.rows,
    required this.hidden,
    required this.grid,
    required this.label,
    required this.gapColor,
    required this.textStyle,
  });

  final List<ChartRow> rows;
  final Set<int> hidden;
  final Color grid;
  final Color label;
  final Color gapColor;
  final TextStyle textStyle;

  static const double _axisWidth = 52;

  @override
  void paint(Canvas canvas, Size size) {
    var minY = double.infinity;
    var maxY = double.negativeInfinity;
    for (final row in rows) {
      for (var s = 0; s < row.values.length; s++) {
        final value = row.values[s];
        if (value == null || hidden.contains(s)) continue;
        minY = math.min(minY, value);
        maxY = math.max(maxY, value);
      }
    }
    if (!minY.isFinite) return;
    if (minY == maxY) {
      final pad = minY == 0 ? 1.0 : minY.abs() * 0.1;
      minY -= pad;
      maxY += pad;
    }
    final plot = Rect.fromLTWH(
      _axisWidth,
      0,
      math.max(1, size.width - _axisWidth),
      math.max(1, size.height),
    );
    double yOf(double value) =>
        plot.bottom - (value - minY) / (maxY - minY) * plot.height;
    final step = rows.length <= 1 ? 0.0 : plot.width / (rows.length - 1);
    double xOf(int index) => plot.left + index * step;

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    const ticks = 4;
    for (var t = 0; t <= ticks; t++) {
      final value = minY + (maxY - minY) * t / ticks;
      final y = yOf(value);
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
      final painter = TextPainter(
        text: TextSpan(text: _format(value), style: textStyle),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: _axisWidth - 6);
      painter.paint(
        canvas,
        Offset(
          _axisWidth - 6 - painter.width,
          (y - painter.height / 2).clamp(0, size.height - painter.height),
        ),
      );
    }

    final gapPaint = Paint()
      ..color = gapColor
      ..strokeWidth = 1;
    final seriesCount = rows.fold(
      0,
      (count, row) => math.max(count, row.values.length),
    );
    for (var i = 0; i < rows.length; i++) {
      if (rows[i].gap) {
        final x = xOf(i);
        canvas.drawLine(Offset(x, plot.top), Offset(x, plot.bottom), gapPaint);
      }
    }
    for (var s = 0; s < seriesCount; s++) {
      if (hidden.contains(s)) continue;
      final paint = Paint()
        ..color = kChartPalette[s % kChartPalette.length]
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round;
      final path = Path();
      var drawing = false;
      for (var i = 0; i < rows.length; i++) {
        final row = rows[i];
        final value = row.gap || s >= row.values.length ? null : row.values[s];
        if (value == null) {
          drawing = false; // Never bridge a gap or a missing value.
          continue;
        }
        final point = Offset(xOf(i), yOf(value));
        if (drawing) {
          path.lineTo(point.dx, point.dy);
        } else {
          path.moveTo(point.dx, point.dy);
          drawing = true;
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  static String _format(double value) {
    final magnitude = value.abs();
    if (magnitude != 0 && (magnitude >= 1e6 || magnitude < 1e-3)) {
      return value.toStringAsExponential(2);
    }
    return magnitude >= 100
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(magnitude >= 10 ? 1 : 2);
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      !identical(old.rows, rows) ||
      old.hidden != hidden ||
      old.grid != grid ||
      old.label != label;
}

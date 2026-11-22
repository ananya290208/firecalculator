import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/fire_results.dart';
import '../theme/app_theme.dart';

class ProjectionChart extends StatelessWidget {
  final List<YearlyProjection> projections;
  final double currentTarget25xCr;
  final double currentTarget30xCr;
  final double height;

  const ProjectionChart({
    super.key,
    required this.projections,
    required this.currentTarget25xCr,
    required this.currentTarget30xCr,
    this.height = 280.0,
  });

  @override
  Widget build(BuildContext context) {
    if (projections.isEmpty) {
      return const SizedBox.shrink();
    }

    final double maxVal = projections
        .map((p) => [
              p.totalCorpusCrores,
              p.target30x / 10000000.0,
            ])
        .expand((x) => x)
        .reduce((a, b) => a > b ? a : b);

    final double maxY = ((maxVal * 1.15) / 2).ceil() * 2.0;

    return Column(
      children: [
        // Legend
        Wrap(
          spacing: 12,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: const [
            _LegendItem(color: AppTheme.primaryGreen, label: 'Total Corpus (Cr)', isDashed: false),
            _LegendItem(color: Color(0xFF0284C7), label: 'Mutual Funds (Cr)', isDashed: false),
            _LegendItem(color: Color(0xFFD97706), label: 'EPF (Cr)', isDashed: false),
            _LegendItem(color: AppTheme.blue25x, label: '25x FIRE Target', isDashed: true),
            _LegendItem(color: AppTheme.purple30x, label: '30x FIRE Target', isDashed: true),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: height,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY > 10 ? 2 : 1,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: AppTheme.borderLight,
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final int year = value.toInt();
                      if (year >= 0 && year <= 10) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Y$year',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    interval: maxY > 10 ? 2 : 1,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '₹${value.toInt()}Cr',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMuted,
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: const Border(
                  bottom: BorderSide(color: AppTheme.borderLight, width: 1.5),
                  left: BorderSide(color: AppTheme.borderLight, width: 1.5),
                ),
              ),
              minX: 0,
              maxX: 10,
              minY: 0,
              maxY: maxY,
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final int yr = spot.x.toInt();
                      String prefix = '';
                      if (spot.barIndex == 0) prefix = 'Total: ';
                      if (spot.barIndex == 1) prefix = 'MF: ';
                      if (spot.barIndex == 2) prefix = 'EPF: ';
                      if (spot.barIndex == 3) prefix = '25x: ';
                      if (spot.barIndex == 4) prefix = '30x: ';

                      return LineTooltipItem(
                        '$prefix₹${spot.y.toStringAsFixed(2)} Cr\n(Yr $yr)',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                // 0: Total Corpus (Green)
                LineChartBarData(
                  spots: projections
                      .map((p) => FlSpot(p.year.toDouble(), p.totalCorpusCrores))
                      .toList(),
                  isCurved: true,
                  color: AppTheme.primaryGreen,
                  barWidth: 3.5,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppTheme.primaryGreen.withOpacity(0.12),
                  ),
                ),
                // 1: MF Corpus (Sky Blue)
                LineChartBarData(
                  spots: projections
                      .map((p) => FlSpot(p.year.toDouble(), p.projectedMF / 10000000.0))
                      .toList(),
                  isCurved: true,
                  color: const Color(0xFF0284C7),
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                ),
                // 2: EPF Corpus (Amber)
                LineChartBarData(
                  spots: projections
                      .map((p) => FlSpot(p.year.toDouble(), p.projectedEPF / 10000000.0))
                      .toList(),
                  isCurved: true,
                  color: const Color(0xFFD97706),
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                ),
                // 3: 25x Target Line (Blue Dashed)
                LineChartBarData(
                  spots: projections
                      .map((p) => FlSpot(p.year.toDouble(), (p.target25x / 10000000.0)))
                      .toList(),
                  isCurved: false,
                  color: AppTheme.blue25x,
                  barWidth: 2,
                  dashArray: [5, 5],
                  dotData: const FlDotData(show: false),
                ),
                // 4: 30x Target Line (Purple Dashed)
                LineChartBarData(
                  spots: projections
                      .map((p) => FlSpot(p.year.toDouble(), (p.target30x / 10000000.0)))
                      .toList(),
                  isCurved: false,
                  color: AppTheme.purple30x,
                  barWidth: 2,
                  dashArray: [4, 4],
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDashed;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.isDashed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }
}

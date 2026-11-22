import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/swp_sip_models.dart';
import '../theme/app_theme.dart';

class SwpSipChart extends StatelessWidget {
  final List<MonthlyTrajectoryPoint> points;
  final double height;

  const SwpSipChart({
    super.key,
    required this.points,
    this.height = 280.0,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();

    double maxVal = 0.0;
    for (final p in points) {
      if (p.combinedMF > maxVal) maxVal = p.combinedMF;
      if (p.stayInvestedMF > maxVal) maxVal = p.stayInvestedMF;
    }

    final double maxValCr = maxVal / 10000000.0;
    final double maxY = ((maxValCr * 1.15) / 2).ceil() * 2.0;

    return Column(
      children: [
        // Legend
        Wrap(
          spacing: 12,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: const [
            _ChartLegendItem(color: AppTheme.primaryNavy, label: 'Stay Invested Baseline'),
            _ChartLegendItem(color: AppTheme.secondaryTeal, label: 'Combined SWP+SIP MF'),
            _ChartLegendItem(color: Color(0xFFD97706), label: 'SWP Remaining Bucket'),
            _ChartLegendItem(color: Color(0xFF2563EB), label: 'SIP Accumulated Bucket'),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: height,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY > 10 ? 2 : 1,
                getDrawingHorizontalLine: (val) => FlLine(
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
                    reservedSize: 26,
                    interval: 12,
                    getTitlesWidget: (val, meta) {
                      final int month = val.toInt();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'M$month',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    interval: maxY > 10 ? 2 : 1,
                    getTitlesWidget: (val, meta) {
                      return Text(
                        '₹${val.toInt()}Cr',
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
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: points.last.month.toDouble(),
              minY: 0,
              maxY: maxY,
              lineBarsData: [
                // Stay Invested
                LineChartBarData(
                  spots: points
                      .map((p) => FlSpot(p.month.toDouble(), p.stayInvestedMF / 10000000.0))
                      .toList(),
                  isCurved: true,
                  color: AppTheme.primaryNavy,
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                ),
                // Combined SWP+SIP
                LineChartBarData(
                  spots: points
                      .map((p) => FlSpot(p.month.toDouble(), p.combinedMF / 10000000.0))
                      .toList(),
                  isCurved: true,
                  color: AppTheme.secondaryTeal,
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                ),
                // SWP Remaining
                LineChartBarData(
                  spots: points
                      .map((p) => FlSpot(p.month.toDouble(), p.swpRemaining / 10000000.0))
                      .toList(),
                  isCurved: true,
                  color: const Color(0xFFD97706),
                  barWidth: 2,
                  dashArray: [5, 4],
                  dotData: const FlDotData(show: false),
                ),
                // SIP Accumulated
                LineChartBarData(
                  spots: points
                      .map((p) => FlSpot(p.month.toDouble(), p.sipAccumulated / 10000000.0))
                      .toList(),
                  isCurved: true,
                  color: const Color(0xFF2563EB),
                  barWidth: 2,
                  dashArray: [3, 3],
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

class _ChartLegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _ChartLegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textDark),
        ),
      ],
    );
  }
}

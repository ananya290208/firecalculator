import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../controllers/fire_calculator_controller.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/exit_dialog.dart';
import '../widgets/metric_badge.dart';
import '../widgets/projection_chart.dart';

class ProjectionScheduleScreen extends StatefulWidget {
  final FireCalculatorController controller;

  const ProjectionScheduleScreen({
    super.key,
    required this.controller,
  });

  @override
  State<ProjectionScheduleScreen> createState() => _ProjectionScheduleScreenState();
}

class _ProjectionScheduleScreenState extends State<ProjectionScheduleScreen> {
  bool _showChart = true;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final results = widget.controller.results;
        final inputs = widget.controller.inputs;
        final projections = results.yearlyProjections;
        final int targetYear = inputs.targetYears.round();

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Schedule & Chart',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            actions: [
              if (!kIsWeb) ...[
                const ExitButton(),
                const SizedBox(width: 8),
              ],
            ],
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double width = constraints.maxWidth;
                final bool isMobile = width < 600;
                final bool isDesktop = width >= 1024;

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 12 : (isDesktop ? 24 : 16),
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // View Mode Switcher (Chart vs Table)
                          SizedBox(
                            width: double.infinity,
                            child: SegmentedButton<bool>(
                              segments: [
                                ButtonSegment(
                                  value: true,
                                  icon: const Icon(Icons.show_chart_rounded, size: 18),
                                  label: Text(isMobile ? 'Chart' : 'Growth Chart'),
                                ),
                                ButtonSegment(
                                  value: false,
                                  icon: const Icon(Icons.table_chart_rounded, size: 18),
                                  label: Text(isMobile ? 'Table' : 'Yearly Table'),
                                ),
                              ],
                              selected: {_showChart},
                              onSelectionChanged: (set) {
                                setState(() {
                                  _showChart = set.first;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Header Card
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreenLight.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_month_rounded, color: AppTheme.primaryGreen, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          '3. YEAR-BY-YEAR PROJECTION SCHEDULE (0 TO 10 YRS)',
                                          maxLines: 1,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: AppTheme.primaryGreenDark,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Target Retirement Horizon: $targetYear Years (${CurrencyFormatter.formatCrores(results.totalCorpusCrores)})',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Chart Section
                          if (_showChart) ...[
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Expanded(
                                          child: Text(
                                            'Portfolio Compounding & Targets',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryGreenLight,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Retirement Year: Y$targetYear',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.primaryGreen,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    ProjectionChart(
                                      projections: projections,
                                      currentTarget25xCr: results.fireTarget25x / 10000000.0,
                                      currentTarget30xCr: results.fireTarget30x / 10000000.0,
                                      height: isMobile ? 240.0 : (isDesktop ? 360.0 : 300.0),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Schedule Table Section
                          const Text(
                            'Detailed Year-by-Year Breakdown (Years 0 to 10)',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Responsive Horizontal Scroll Table
                          Card(
                            clipBehavior: Clip.antiAlias,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(
                                  AppTheme.primaryGreen.withOpacity(0.08),
                                ),
                                columnSpacing: isMobile ? 12 : 20,
                                horizontalMargin: 12,
                                columns: const [
                                  DataColumn(label: Text('Year', style: TextStyle(fontWeight: FontWeight.w800))),
                                  DataColumn(label: Text('Total (₹ Cr)', style: TextStyle(fontWeight: FontWeight.w800))),
                                  DataColumn(label: Text('Projected MF (₹)', style: TextStyle(fontWeight: FontWeight.w800))),
                                  DataColumn(label: Text('Projected EPF (₹)', style: TextStyle(fontWeight: FontWeight.w800))),
                                  DataColumn(label: Text('Total Corpus (₹)', style: TextStyle(fontWeight: FontWeight.w800))),
                                  DataColumn(label: Text('Annual Expense (₹)', style: TextStyle(fontWeight: FontWeight.w800))),
                                  DataColumn(label: Text('25x Rule Gap', style: TextStyle(fontWeight: FontWeight.w800))),
                                  DataColumn(label: Text('30x Rule Gap', style: TextStyle(fontWeight: FontWeight.w800))),
                                ],
                                rows: projections.map((p) {
                                  final bool isTargetYear = p.year == targetYear;
                                  final rowColor = isTargetYear
                                      ? AppTheme.accentAmberLight.withOpacity(0.6)
                                      : (p.year % 2 == 0 ? Colors.transparent : Colors.grey.withOpacity(0.03));

                                  return DataRow(
                                    color: WidgetStateProperty.all(rowColor),
                                    cells: [
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Year ${p.year}',
                                              style: TextStyle(
                                                fontWeight: isTargetYear ? FontWeight.w900 : FontWeight.w600,
                                                color: isTargetYear ? const Color(0xFFB45309) : null,
                                              ),
                                            ),
                                            if (isTargetYear) ...[
                                              const SizedBox(width: 4),
                                              const Icon(Icons.star, size: 14, color: Color(0xFFB45309)),
                                            ],
                                          ],
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          CurrencyFormatter.formatCrores(p.totalCorpusCrores),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: isTargetYear ? AppTheme.primaryGreenDark : AppTheme.primaryGreen,
                                          ),
                                        ),
                                      ),
                                      DataCell(Text(CurrencyFormatter.formatINR(p.projectedMF))),
                                      DataCell(Text(CurrencyFormatter.formatINR(p.projectedEPF))),
                                      DataCell(Text(CurrencyFormatter.formatINR(p.totalCorpus))),
                                      DataCell(Text(CurrencyFormatter.formatINR(p.annualExpense))),
                                      DataCell(MetricBadge(surplus: p.surplus25x, compact: true)),
                                      DataCell(MetricBadge(surplus: p.surplus30x, compact: true)),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

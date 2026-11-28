import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../controllers/fire_calculator_controller.dart';
import '../models/fire_results.dart';
import '../models/scenario_item.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/exit_dialog.dart';
import '../widgets/metric_badge.dart';
import '../widgets/projection_chart.dart';

class ScheduleMatrixScreen extends StatefulWidget {
  final FireCalculatorController controller;
  final VoidCallback onNavigateToCalculator;

  const ScheduleMatrixScreen({
    super.key,
    required this.controller,
    required this.onNavigateToCalculator,
  });

  @override
  State<ScheduleMatrixScreen> createState() => _ScheduleMatrixScreenState();
}

class _ScheduleMatrixScreenState extends State<ScheduleMatrixScreen> {
  int _selectedTab = 0; // 0: Schedule & Chart, 1: Scenario Matrix

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final results = widget.controller.results;
        final inputs = widget.controller.inputs;
        final projections = results.yearlyProjections;
        final scenarios = widget.controller.preBuiltScenarios;
        final int targetYear = inputs.targetYears.round();

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Schedule & Scenario Matrix',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
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
                          // Tab switcher between Schedule and Scenario Matrix
                          SegmentedButton<int>(
                            segments: [
                              ButtonSegment(
                                value: 0,
                                icon: const Icon(Icons.calendar_month_rounded, size: 18),
                                label: Text(isMobile ? '0-10Y Schedule' : 'Year-by-Year Schedule (0-10 Yrs)'),
                              ),
                              ButtonSegment(
                                value: 1,
                                icon: const Icon(Icons.grid_view_rounded, size: 18),
                                label: Text(isMobile ? 'Scenario Matrix' : 'Pre-Built Scenario Matrix (3Y, 6Y, 7Y)'),
                              ),
                            ],
                            selected: {_selectedTab},
                            onSelectionChanged: (set) {
                              setState(() {
                                _selectedTab = set.first;
                              });
                            },
                          ),
                          const SizedBox(height: 14),

                          if (_selectedTab == 0) ...[
                            // Header Banner
                            _buildScheduleBanner(targetYear, results),
                            const SizedBox(height: 14),

                            // Chart Card
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
                                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryGreenLight,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Retirement: Y$targetYear',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.secondaryTeal,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    ProjectionChart(
                                      projections: projections,
                                      currentTarget25xCr: results.fireTarget25x / 10000000.0,
                                      currentTarget30xCr: results.fireTarget30x / 10000000.0,
                                      height: isMobile ? 240.0 : (isDesktop ? 340.0 : 280.0),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Detailed Breakdown Section
                            const Text(
                              'Detailed Year-by-Year Breakdown (Years 0 to 10)',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),

                            // Mobile Card View vs Tablet/Desktop DataTable
                            if (isMobile)
                              ...projections.map((p) => _buildMobileProjectionCard(p, targetYear))
                            else
                              _buildDesktopProjectionTable(projections, targetYear),
                          ] else ...[
                            // Pre-Built Matrix View
                            _buildMatrixBanner(),
                            const SizedBox(height: 14),

                            // Scenario Cards
                            _buildScenarioCardsGrid(scenarios, isMobile),
                            const SizedBox(height: 20),

                            const Text(
                              'Comparison Matrix Table',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),

                            if (isMobile)
                              ...scenarios.map((s) => _buildMobileScenarioItemCard(s))
                            else
                              _buildDesktopScenarioTable(scenarios),
                          ],

                          const SizedBox(height: 36),
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

  Widget _buildScheduleBanner(int targetYear, FireResults results) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreenLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.secondaryTeal.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month_rounded, color: AppTheme.secondaryTeal, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'YEAR-BY-YEAR PROJECTION SCHEDULE (0 TO 10 YRS)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Target Horizon: $targetYear Years (${CurrencyFormatter.formatCrores(results.totalCorpusCrores)})',
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
    );
  }

  Widget _buildMatrixBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Row(
        children: [
          Icon(Icons.grid_view_rounded, color: Color(0xFF1D4ED8), size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PRE-BUILT RETIREMENT HORIZON & EXPENSE MATRIX',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E40AF),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Pre-calculated across 3Y, 6Y, and 7Y horizons comparing ₹1.25L Base vs ₹2.00L Upper monthly lifestyles.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF3B82F6)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileProjectionCard(YearlyProjection p, int targetYear) {
    final bool isTarget = p.year == targetYear;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isTarget ? AppTheme.accentAmberLight.withOpacity(0.4) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isTarget ? AppTheme.accentAmber : AppTheme.borderLight,
          width: isTarget ? 1.5 : 1.0,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Year ${p.year}',
                    style: TextStyle(
                      fontWeight: isTarget ? FontWeight.w900 : FontWeight.w700,
                      fontSize: 14,
                      color: isTarget ? const Color(0xFFB45309) : AppTheme.primaryNavy,
                    ),
                  ),
                  if (isTarget) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.star, size: 14, color: Color(0xFFB45309)),
                    const SizedBox(width: 2),
                    const Text('Target', style: TextStyle(fontSize: 11, color: Color(0xFFB45309), fontWeight: FontWeight.bold)),
                  ],
                ],
              ),
              Text(
                CurrencyFormatter.formatCrores(p.totalCorpusCrores),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: isTarget ? AppTheme.secondaryTeal : AppTheme.primaryNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildMiniStat('Projected MF', CurrencyFormatter.formatCompactINR(p.projectedMF)),
              _buildMiniStat('Projected EPF', CurrencyFormatter.formatCompactINR(p.projectedEPF)),
              _buildMiniStat('Annual Exp', CurrencyFormatter.formatCompactINR(p.annualExpense)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MetricBadge(surplus: p.surplus25x, compact: true, labelPrefix: '25x'),
              MetricBadge(surplus: p.surplus30x, compact: true, labelPrefix: '30x'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopProjectionTable(List<YearlyProjection> projections, int targetYear) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppTheme.primaryNavy.withOpacity(0.06)),
          columnSpacing: 18,
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
                      color: isTargetYear ? AppTheme.secondaryTeal : AppTheme.primaryNavy,
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
    );
  }

  Widget _buildScenarioCardsGrid(List<ScenarioItem> scenarios, bool isMobile) {
    if (isMobile) {
      return Column(
        children: scenarios.map((s) => _buildScenarioCard(s, isMobile: true)).toList(),
      );
    }

    final List<Widget> rows = [];
    for (int i = 0; i < scenarios.length; i += 2) {
      final first = scenarios[i];
      final second = (i + 1 < scenarios.length) ? scenarios[i + 1] : null;

      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildScenarioCard(first, isMobile: false)),
                const SizedBox(width: 12),
                if (second != null)
                  Expanded(child: _buildScenarioCard(second, isMobile: false))
                else
                  const Spacer(),
              ],
            ),
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _buildScenarioCard(ScenarioItem scenario, {bool isMobile = true}) {
    final bool isCurrent =
        (widget.controller.inputs.targetYears - scenario.horizonYears).abs() < 0.1 &&
        (widget.controller.inputs.currentMonthlyExpenses - scenario.monthlyExpenseToday).abs() < 1.0;

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 12 : 0),
      decoration: BoxDecoration(
        color: isCurrent ? AppTheme.navyLight : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCurrent ? AppTheme.primaryNavy : AppTheme.borderLight,
          width: isCurrent ? 1.5 : 1.0,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  scenario.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
              if (isCurrent) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryTeal,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'ACTIVE NOW',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildStatMini('Horizon', '${scenario.horizonYears.toInt()} Years', Icons.schedule_rounded),
              _buildStatMini('Monthly Exp', CurrencyFormatter.formatCompactINR(scenario.monthlyExpenseToday), Icons.payments_outlined),
              _buildStatMini('Corpus', CurrencyFormatter.formatCrores(scenario.projectedCorpusCrores), Icons.account_balance_rounded, isHighlight: true),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.bgLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('25x Benchmark', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          CurrencyFormatter.formatCrores(scenario.target25xCrores),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 3),
                      MetricBadge(surplus: scenario.surplus25xCrores * 10000000.0, compact: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.bgLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('30x Conservative', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          CurrencyFormatter.formatCrores(scenario.target30xCrores),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 3),
                      MetricBadge(surplus: scenario.surplus30xCrores * 10000000.0, compact: true),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: Icon(isCurrent ? Icons.check_circle_outline : Icons.play_arrow_rounded, size: 18),
              label: Text(
                isCurrent ? 'Currently Loaded in Simulator' : 'Load Into Live Simulator',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              onPressed: () {
                widget.controller.applyScenario(scenario);
                widget.onNavigateToCalculator();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileScenarioItemCard(ScenarioItem s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(s.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              Text(
                CurrencyFormatter.formatCrores(s.projectedCorpusCrores),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.primaryNavy),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildMiniStat('Horizon', '${s.horizonYears.toInt()} Yrs'),
              _buildMiniStat('Monthly', CurrencyFormatter.formatCompactINR(s.monthlyExpenseToday)),
              _buildMiniStat('25x Gap', CurrencyFormatter.formatCrores(s.surplus25xCrores)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopScenarioTable(List<ScenarioItem> scenarios) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppTheme.primaryNavy.withOpacity(0.06)),
          columnSpacing: 18,
          columns: const [
            DataColumn(label: Text('Scenario', style: TextStyle(fontWeight: FontWeight.w800))),
            DataColumn(label: Text('Horizon', style: TextStyle(fontWeight: FontWeight.w800))),
            DataColumn(label: Text('Monthly Exp Today', style: TextStyle(fontWeight: FontWeight.w800))),
            DataColumn(label: Text('Projected Corpus', style: TextStyle(fontWeight: FontWeight.w800))),
            DataColumn(label: Text('25x Target', style: TextStyle(fontWeight: FontWeight.w800))),
            DataColumn(label: Text('Surplus 25x', style: TextStyle(fontWeight: FontWeight.w800))),
            DataColumn(label: Text('30x Target', style: TextStyle(fontWeight: FontWeight.w800))),
            DataColumn(label: Text('Surplus 30x', style: TextStyle(fontWeight: FontWeight.w800))),
          ],
          rows: scenarios.map((s) {
            return DataRow(
              cells: [
                DataCell(Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                DataCell(Text('${s.horizonYears.toInt()} Yrs')),
                DataCell(Text(CurrencyFormatter.formatINR(s.monthlyExpenseToday))),
                DataCell(Text(
                  CurrencyFormatter.formatCrores(s.projectedCorpusCrores),
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.secondaryTeal),
                )),
                DataCell(Text(CurrencyFormatter.formatCrores(s.target25xCrores))),
                DataCell(MetricBadge(surplus: s.surplus25xCrores * 10000000.0, compact: true)),
                DataCell(Text(CurrencyFormatter.formatCrores(s.target30xCrores))),
                DataCell(MetricBadge(surplus: s.surplus30xCrores * 10000000.0, compact: true)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatMini(String title, String value, IconData icon, {bool isHighlight = false}) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: isHighlight ? AppTheme.secondaryTeal : AppTheme.textMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted), overflow: TextOverflow.ellipsis),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isHighlight ? AppTheme.secondaryTeal : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

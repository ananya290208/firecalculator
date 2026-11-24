import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../controllers/fire_calculator_controller.dart';
import '../models/scenario_item.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/exit_dialog.dart';
import '../widgets/metric_badge.dart';

class ScenarioMatrixScreen extends StatelessWidget {
  final FireCalculatorController controller;
  final VoidCallback onNavigateToCalculator;

  const ScenarioMatrixScreen({
    super.key,
    required this.controller,
    required this.onNavigateToCalculator,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final scenarios = controller.preBuiltScenarios;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Scenario Matrix',
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

                // Build responsive cards list
                final List<Widget> cardWidgets = [];
                if (isMobile) {
                  for (final s in scenarios) {
                    cardWidgets.add(_buildScenarioCard(context, s, isMobile: true));
                  }
                } else {
                  for (int i = 0; i < scenarios.length; i += 2) {
                    final first = scenarios[i];
                    final second = (i + 1 < scenarios.length) ? scenarios[i + 1] : null;
                    cardWidgets.add(
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: _buildScenarioCard(context, first, isMobile: false)),
                              const SizedBox(width: 12),
                              if (second != null)
                                Expanded(child: _buildScenarioCard(context, second, isMobile: false))
                              else
                                const Spacer(),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                }

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
                          // Info Banner
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.grid_view_rounded,
                                    color: Color(0xFF1D4ED8), size: 22),
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
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF3B82F6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Cards list with one-tap "Apply to Simulator"
                          ...cardWidgets,

                          const SizedBox(height: 20),

                          // Full Matrix Data Table
                          const Text(
                            'Comparison Matrix Table',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),

                          Card(
                            clipBehavior: Clip.antiAlias,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(
                                  AppTheme.primaryGreen.withOpacity(0.08),
                                ),
                                columnSpacing: isMobile ? 12 : 20,
                                columns: const [
                                  DataColumn(label: Text('Scenario', style: TextStyle(fontWeight: FontWeight.w800))),
                                  DataColumn(label: Text('Horizon', style: TextStyle(fontWeight: FontWeight.w800))),
                                  DataColumn(label: Text('Monthly Exp Today', style: TextStyle(fontWeight: FontWeight.w800))),
                                  DataColumn(label: Text('Projected Corpus', style: TextStyle(fontWeight: FontWeight.w800))),
                                  DataColumn(label: Text('25x Target', style: TextStyle(fontWeight: FontWeight.w800))),
                                  DataColumn(label: Text('Surplus/Deficit 25x', style: TextStyle(fontWeight: FontWeight.w800))),
                                  DataColumn(label: Text('30x Target', style: TextStyle(fontWeight: FontWeight.w800))),
                                  DataColumn(label: Text('Surplus/Deficit 30x', style: TextStyle(fontWeight: FontWeight.w800))),
                                ],
                                rows: scenarios.map((s) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(
                                        s.name,
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      )),
                                      DataCell(Text('${s.horizonYears.toInt()} Yrs')),
                                      DataCell(Text(CurrencyFormatter.formatINR(s.monthlyExpenseToday))),
                                      DataCell(Text(
                                        CurrencyFormatter.formatCrores(s.projectedCorpusCrores),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.primaryGreen,
                                        ),
                                      )),
                                      DataCell(Text(CurrencyFormatter.formatCrores(s.target25xCrores))),
                                      DataCell(MetricBadge(
                                        surplus: s.surplus25xCrores * 10000000.0,
                                        compact: true,
                                      )),
                                      DataCell(Text(CurrencyFormatter.formatCrores(s.target30xCrores))),
                                      DataCell(MetricBadge(
                                        surplus: s.surplus30xCrores * 10000000.0,
                                        compact: true,
                                      )),
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

  Widget _buildScenarioCard(BuildContext context, ScenarioItem scenario, {bool isMobile = true}) {
    final bool isCurrent =
        (controller.inputs.targetYears - scenario.horizonYears).abs() < 0.1 &&
        (controller.inputs.currentMonthlyExpenses - scenario.monthlyExpenseToday).abs() < 1.0;

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 12 : 0),
      decoration: BoxDecoration(
        color: isCurrent ? AppTheme.primaryGreenLight.withOpacity(0.4) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent ? AppTheme.primaryGreen : AppTheme.borderLight,
          width: isCurrent ? 2 : 1,
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
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (isCurrent) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'ACTIVE NOW',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // Key metrics row
          Row(
            children: [
              _buildStatMini(
                'Horizon',
                '${scenario.horizonYears.toInt()} Years',
                Icons.schedule_rounded,
              ),
              _buildStatMini(
                'Monthly Expense',
                CurrencyFormatter.formatCompactINR(scenario.monthlyExpenseToday),
                Icons.payments_outlined,
              ),
              _buildStatMini(
                'Projected Corpus',
                CurrencyFormatter.formatCrores(scenario.projectedCorpusCrores),
                Icons.account_balance_rounded,
                isHighlight: true,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 25x and 30x benchmarks
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.bgLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '25x FIRE Benchmark',
                        style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Target: ${CurrencyFormatter.formatCrores(scenario.target25xCrores)}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 4),
                      MetricBadge(
                        surplus: scenario.surplus25xCrores * 10000000.0,
                        compact: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.bgLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '30x Conservative',
                        style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Target: ${CurrencyFormatter.formatCrores(scenario.target30xCrores)}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 4),
                      MetricBadge(
                        surplus: scenario.surplus30xCrores * 10000000.0,
                        compact: true,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          // Action button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: Icon(
                isCurrent ? Icons.check_circle_outline : Icons.play_arrow_rounded,
                size: 18,
              ),
              label: Text(
                isCurrent ? 'Currently Loaded in Simulator' : 'Load Into Live Simulator',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: isCurrent ? AppTheme.primaryGreen : null,
                side: BorderSide(
                  color: isCurrent ? AppTheme.primaryGreen : AppTheme.borderLight,
                ),
              ),
              onPressed: () {
                controller.applyScenario(scenario);
                onNavigateToCalculator();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Applied "${scenario.name}" to live simulator!'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatMini(String title, String value, IconData icon, {bool isHighlight = false}) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: isHighlight ? AppTheme.primaryGreen : AppTheme.textMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isHighlight ? AppTheme.primaryGreen : null,
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

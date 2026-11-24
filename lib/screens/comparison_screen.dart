import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../controllers/fire_calculator_controller.dart';
import '../models/saved_combination.dart';
import '../services/history_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/exit_dialog.dart';
import '../widgets/metric_badge.dart';

class ComparisonScreen extends StatelessWidget {
  final FireCalculatorController controller;
  final VoidCallback onNavigateToCalculator;

  const ComparisonScreen({
    super.key,
    required this.controller,
    required this.onNavigateToCalculator,
  });

  @override
  Widget build(BuildContext context) {
    final historyService = controller.historyService;

    return ListenableBuilder(
      listenable: historyService,
      builder: (context, _) {
        final combinations = historyService.combinations;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Combinations Dashboard',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            actions: [
              if (combinations.isNotEmpty)
                IconButton(
                  tooltip: 'Clear History',
                  icon: const Icon(Icons.delete_sweep_outlined),
                  onPressed: () => _confirmClearHistory(context, historyService),
                ),
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

                if (combinations.isEmpty) {
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: _buildEmptyState(context),
                    ),
                  );
                }

                // Build responsive combinations cards list
                final List<Widget> cardWidgets = [];
                final entries = combinations.asMap().entries.toList();
                if (isMobile) {
                  for (final entry in entries) {
                    cardWidgets.add(
                      _buildCombinationCard(context, entry.value, entry.key + 1, isMobile: true),
                    );
                  }
                } else {
                  for (int i = 0; i < entries.length; i += 2) {
                    final first = entries[i];
                    final second = (i + 1 < entries.length) ? entries[i + 1] : null;
                    cardWidgets.add(
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _buildCombinationCard(
                                  context,
                                  first.value,
                                  first.key + 1,
                                  isMobile: false,
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (second != null)
                                Expanded(
                                  child: _buildCombinationCard(
                                    context,
                                    second.value,
                                    second.key + 1,
                                    isMobile: false,
                                  ),
                                )
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
                          // Header info banner
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.accentAmberLight.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.accentAmber.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.history_rounded, color: Color(0xFFB45309), size: 22),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'LAST 5 ATTEMPTED COMBINATIONS (${combinations.length}/5)',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF92400E),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Automatically retained for direct side-by-side comparison. Tap any combination to restore it to the live simulator.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFFB45309),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Side-by-side Horizontal Comparison Table
                          _buildComparisonTable(context, combinations, isMobile),
                          const SizedBox(height: 20),

                          // Cards List for each combination
                          const Text(
                            'Combination Snapshots & Details',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),

                          ...cardWidgets,

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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreenLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.compare_arrows_rounded,
                size: 48,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Saved Combinations Yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Simulate different retirement horizons, SIPs, and expenses in the Calculator. The last 5 combinations will appear here for comparison.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onNavigateToCalculator,
              icon: const Icon(Icons.tune_rounded),
              label: const Text('Go to Simulator'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonTable(BuildContext context, List<SavedCombination> combinations, bool isMobile) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            AppTheme.primaryGreen.withOpacity(0.08),
          ),
          columnSpacing: isMobile ? 12 : 20,
          columns: [
            const DataColumn(label: Text('Parameter', style: TextStyle(fontWeight: FontWeight.w800))),
            ...combinations.asMap().entries.map((entry) {
              final int index = entry.key;
              final c = entry.value;
              return DataColumn(
                label: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${index + 1} ${index == 0 ? "(Latest)" : ""}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: index == 0 ? AppTheme.primaryGreen : null,
                      ),
                    ),
                    Text(
                      c.title,
                      style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              );
            }),
          ],
          rows: [
            // Row 1: Target Years
            DataRow(cells: [
              const DataCell(Text('Retirement Horizon', style: TextStyle(fontWeight: FontWeight.w600))),
              ...combinations.map((c) => DataCell(Text('${c.inputs.targetYears.toInt()} Years'))),
            ]),
            // Row 2: Monthly Expenses Today
            DataRow(cells: [
              const DataCell(Text('Monthly Expenses Today', style: TextStyle(fontWeight: FontWeight.w600))),
              ...combinations.map((c) => DataCell(Text(CurrencyFormatter.formatINR(c.inputs.currentMonthlyExpenses)))),
            ]),
            // Row 3: Monthly MF SIP
            DataRow(cells: [
              const DataCell(Text('Monthly MF SIP', style: TextStyle(fontWeight: FontWeight.w600))),
              ...combinations.map((c) => DataCell(Text(CurrencyFormatter.formatINR(c.inputs.monthlyMFSIP)))),
            ]),
            // Row 4: Monthly EPF SIP
            DataRow(cells: [
              const DataCell(Text('Monthly EPF', style: TextStyle(fontWeight: FontWeight.w600))),
              ...combinations.map((c) => DataCell(Text(CurrencyFormatter.formatINR(c.inputs.monthlyEPFContribution)))),
            ]),
            // Row 5: Projected Corpus
            DataRow(
              color: WidgetStateProperty.all(AppTheme.primaryGreenLight.withOpacity(0.3)),
              cells: [
                const DataCell(Text('Projected Corpus (₹ Cr)', style: TextStyle(fontWeight: FontWeight.w800))),
                ...combinations.map((c) => DataCell(
                      Text(
                        CurrencyFormatter.formatCrores(c.projectedCorpusCrores),
                        style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primaryGreen),
                      ),
                    )),
              ],
            ),
            // Row 6: 25x Surplus / Gap
            DataRow(cells: [
              const DataCell(Text('25x Rule Gap', style: TextStyle(fontWeight: FontWeight.w600))),
              ...combinations.map((c) => DataCell(
                    MetricBadge(surplus: c.surplus25xCrores * 10000000.0, compact: true),
                  )),
            ]),
            // Row 7: 30x Surplus / Gap
            DataRow(cells: [
              const DataCell(Text('30x Rule Gap', style: TextStyle(fontWeight: FontWeight.w600))),
              ...combinations.map((c) => DataCell(
                    MetricBadge(surplus: c.surplus30xCrores * 10000000.0, compact: true),
                  )),
            ]),
            // Row 8: Post-Tax Corpus
            DataRow(cells: [
              const DataCell(Text('Est. Post-Tax Corpus', style: TextStyle(fontWeight: FontWeight.w600))),
              ...combinations.map((c) => DataCell(
                    Text(CurrencyFormatter.formatCrores(c.estPostTaxCorpusCrores)),
                  )),
            ]),
            // Row 9: Action
            DataRow(cells: [
              const DataCell(Text('Action', style: TextStyle(fontWeight: FontWeight.w600))),
              ...combinations.map((c) => DataCell(
                    FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      ),
                      onPressed: () {
                        controller.loadCombination(c.inputs, c.title);
                        onNavigateToCalculator();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Loaded "${c.title}" into simulator!')),
                        );
                      },
                      child: const Text('Restore', style: TextStyle(fontSize: 11)),
                    ),
                  )),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildCombinationCard(BuildContext context, SavedCombination c, int orderNumber, {bool isMobile = true}) {
    final bool isCurrent = controller.inputs == c.inputs;

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 12 : 0),
      decoration: BoxDecoration(
        color: isCurrent ? AppTheme.primaryGreenLight.withOpacity(0.3) : Colors.white,
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
              CircleAvatar(
                radius: 14,
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                child: Text('$orderNumber', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    Text(
                      'Saved on ${_formatDate(c.timestamp)}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'ACTIVE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () => controller.historyService.removeCombination(c.id),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Core metrics display
          Row(
            children: [
              _buildCardMiniMetric(
                'Corpus',
                CurrencyFormatter.formatCrores(c.projectedCorpusCrores),
                AppTheme.primaryGreen,
              ),
              _buildCardMiniMetric(
                '25x Gap',
                CurrencyFormatter.formatCompactINR(c.surplus25xCrores * 10000000.0),
                c.surplus25xCrores >= 0 ? AppTheme.surplusGreen : AppTheme.shortfallRed,
              ),
              _buildCardMiniMetric(
                '30x Gap',
                CurrencyFormatter.formatCompactINR(c.surplus30xCrores * 10000000.0),
                c.surplus30xCrores >= 0 ? AppTheme.surplusGreen : AppTheme.shortfallRed,
              ),
              _buildCardMiniMetric(
                'Post-Tax',
                CurrencyFormatter.formatCrores(c.estPostTaxCorpusCrores),
                const Color(0xFF4338CA),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Inputs details chips
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _buildChip('${c.inputs.targetYears.toInt()} Yrs Horizon'),
              _buildChip('Exp: ${CurrencyFormatter.formatCompactINR(c.inputs.currentMonthlyExpenses)}/mo'),
              _buildChip('MF SIP: ${CurrencyFormatter.formatCompactINR(c.inputs.monthlyMFSIP)}/mo'),
              _buildChip('EPF SIP: ${CurrencyFormatter.formatCompactINR(c.inputs.monthlyEPFContribution)}/mo'),
              _buildChip('MF: ${CurrencyFormatter.formatPercentage(c.inputs.expectedMFReturn)}'),
              _buildChip('EPF: ${CurrencyFormatter.formatPercentage(c.inputs.expectedEPFReturn)}'),
            ],
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: Icon(isCurrent ? Icons.check : Icons.restore_rounded, size: 18),
              label: Text(
                isCurrent ? 'Currently in Simulator' : 'Load Into Live Simulator',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              onPressed: () {
                controller.loadCombination(c.inputs, c.title);
                onNavigateToCalculator();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Restored "${c.title}" into simulator!')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardMiniMetric(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.bgLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _confirmClearHistory(BuildContext context, HistoryService historyService) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Comparison History?'),
        content: const Text('Are you sure you want to remove all saved combinations from this dashboard?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              historyService.clearHistory();
              Navigator.pop(ctx);
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

import 'dart:math';
import 'package:flutter/material.dart';
import '../models/debt_bucket_models.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';

class DebtBucketAllocationWidget extends StatelessWidget {
  final DebtBucketResults results;

  const DebtBucketAllocationWidget({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    final eqPct = results.equityPct;
    final debtPct = results.debtPct;
    final epfPct = results.epfPct;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Corpus Asset Allocation Shift',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textDark),
              ),
              Text(
                'Total: ${CurrencyFormatter.formatCrores(results.totalCombinedCrores)}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.primaryNavy),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Stacked horizontal multi-colored progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 18,
              child: (results.totalCombinedCorpus <= 0)
                  ? Container(color: Colors.grey.shade200)
                  : Row(
                      children: [
                        Expanded(
                          flex: max(1, (eqPct * 10).round()),
                          child: Container(color: AppTheme.primaryNavy),
                        ),
                        Expanded(
                          flex: max(1, (debtPct * 10).round()),
                          child: Container(color: const Color(0xFFD97706)),
                        ),
                        Expanded(
                          flex: max(1, (epfPct * 10).round()),
                          child: Container(color: AppTheme.secondaryTeal),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 14),
          // Legend badges with exact amounts and percentages
          Row(
            children: [
              _buildLegend(
                color: AppTheme.primaryNavy,
                title: 'Equity MF',
                pct: eqPct,
                value: results.existingEquityCorpus,
              ),
              const SizedBox(width: 8),
              _buildLegend(
                color: const Color(0xFFD97706),
                title: 'Debt/Arbitrage',
                pct: debtPct,
                value: results.accumulatedDebtBucket,
              ),
              const SizedBox(width: 8),
              _buildLegend(
                color: AppTheme.secondaryTeal,
                title: 'EPF Safe',
                pct: epfPct,
                value: results.projectedEPF,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend({
    required Color color,
    required String title,
    required double pct,
    required double value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                CurrencyFormatter.formatCompactINR(value),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textDark),
              ),
            ),
            Text(
              '${pct.toStringAsFixed(1)}% of total',
              style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

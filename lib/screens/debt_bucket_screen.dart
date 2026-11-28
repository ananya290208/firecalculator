import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../controllers/fire_calculator_controller.dart';
import '../models/debt_bucket_models.dart';
import '../services/debt_bucket_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/currency_input_field.dart';
import '../widgets/debt_bucket_chart.dart';
import '../widgets/exit_dialog.dart';
import '../widgets/stat_card.dart';

class DebtBucketScreen extends StatefulWidget {
  final FireCalculatorController controller;

  const DebtBucketScreen({super.key, required this.controller});

  @override
  State<DebtBucketScreen> createState() => _DebtBucketScreenState();
}

class _DebtBucketScreenState extends State<DebtBucketScreen> {
  late DebtBucketInputs _inputs;

  @override
  void initState() {
    super.initState();
    final cInputs = widget.controller.inputs;
    _inputs = DebtBucketInputs(
      initialEquityMF: cInputs.currentMFValue,
      redirectedMonthlySIP: cInputs.monthlyMFSIP,
      horizonYears: cInputs.targetYears,
      equityReturnRate: cInputs.expectedMFReturn,
      debtReturnRate: 0.0,
      currentEPF: cInputs.currentEPFBalance,
      monthlyEPF: cInputs.monthlyEPFContribution,
      epfReturnRate: cInputs.expectedEPFReturn,
      capitalShiftAmount: 0.0,
      currentMonthlyExpenses: cInputs.currentMonthlyExpenses,
      expectedInflationRate: cInputs.expectedInflationRate,
    );
  }

  void _updateInputs(DebtBucketInputs newInputs) {
    setState(() {
      _inputs = newInputs;
    });
  }

  @override
  Widget build(BuildContext context) {
    final results = DebtBucketService.calculate(_inputs);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SIP Debt / Arbitrage Bucket Shift',
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
                      // Info Banner
                      _buildInfoBanner(),
                      const SizedBox(height: 14),

                      // Parameters inputs
                      _buildInputsSection(isMobile),
                      const SizedBox(height: 16),

                      // Asset Allocation Progress
                      DebtBucketAllocationWidget(results: results),
                      const SizedBox(height: 16),

                      // Key Summary Stat Cards
                      _buildSummaryStatCards(results, isMobile),
                      const SizedBox(height: 20),

                      // Trade-off Comparison Section
                      const Text(
                        'Strategic Trade-Off & Allocation Options',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),

                      ...results.tradeoffOptions.map((opt) => _buildOptionCard(opt)),

                      const SizedBox(height: 16),
                      _buildInsightCard(results),

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
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: Color(0xFFB45309), size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₹90K SIP DEBT / ARBITRAGE BUCKET SHIFT SIMULATOR',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF92400E),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Keeps existing ₹3.50 Cr equity untouched compounding at 12%, while diverting the fresh ₹90,000/mo SIP into a 7.00% p.a. low-volatility Debt/Arbitrage bucket. Eliminates capital gains tax on existing funds while building safe liquidity.',
                  style: TextStyle(fontSize: 12, color: Color(0xFFB45309), height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputsSection(bool isMobile) {
    final fields = [
      CurrencyInputField(
        label: 'Existing Equity MF (₹)',
        guidance: 'Kept fully invested',
        initialValue: _inputs.initialEquityMF,
        type: InputType.currency,
        min: 0,
        max: 500000000,
        step: 1000000,
        quickChips: const [0, 20000000, 30000000, 35000000, 40000000],
        onChanged: (val) => _updateInputs(_inputs.copyWith(initialEquityMF: val)),
      ),
      CurrencyInputField(
        label: 'Redirected Monthly SIP (₹)',
        guidance: 'Redirected to Debt',
        initialValue: _inputs.redirectedMonthlySIP,
        type: InputType.currency,
        min: 0,
        max: 1000000,
        step: 5000,
        quickChips: const [0, 50000, 75000, 90000, 100000],
        onChanged: (val) => _updateInputs(_inputs.copyWith(redirectedMonthlySIP: val)),
      ),
      CurrencyInputField(
        label: 'Horizon (Years)',
        guidance: 'e.g. 3 Years (36 mo)',
        initialValue: _inputs.horizonYears,
        type: InputType.years,
        min: 0,
        max: 10,
        step: 1,
        quickChips: const [0, 1, 2, 3, 5, 6, 7],
        onChanged: (val) => _updateInputs(_inputs.copyWith(horizonYears: val)),
      ),
      CurrencyInputField(
        label: 'Debt / Arbitrage Return (%)',
        guidance: 'e.g. 7.00% p.a.',
        initialValue: _inputs.debtReturnRate,
        type: InputType.percentage,
        min: 0,
        max: 0.12,
        step: 0.005,
        quickChips: const [0.0, 0.06, 0.07, 0.075, 0.08],
        onChanged: (val) => _updateInputs(_inputs.copyWith(debtReturnRate: val)),
      ),
      CurrencyInputField(
        label: 'Equity Expected Return (%)',
        guidance: 'e.g. 12.00% p.a.',
        initialValue: _inputs.equityReturnRate,
        type: InputType.percentage,
        min: 0,
        max: 0.20,
        step: 0.005,
        quickChips: const [0.0, 0.10, 0.12, 0.14, 0.15],
        onChanged: (val) => _updateInputs(_inputs.copyWith(equityReturnRate: val)),
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Debt Shift Parameters',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                Wrap(
                  spacing: 6,
                  children: [
                    TextButton(
                      onPressed: () => _updateInputs(const DebtBucketInputs()),
                      child: const Text('Clear (Blank)', style: TextStyle(fontSize: 11)),
                    ),
                    TextButton(
                      onPressed: () => _updateInputs(DebtBucketInputs.promptDefaults()),
                      child: const Text('Load 3Y Example', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isMobile)
              Column(
                children: fields
                    .map((f) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: f,
                        ))
                    .toList(),
              )
            else
              _buildTwoColumnFields(fields),
          ],
        ),
      ),
    );
  }

  Widget _buildTwoColumnFields(List<Widget> fields) {
    final List<Widget> rows = [];
    for (int i = 0; i < fields.length; i += 2) {
      final first = fields[i];
      final second = (i + 1 < fields.length) ? fields[i + 1] : null;
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: i + 2 < fields.length ? 16 : 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: first),
              const SizedBox(width: 18),
              Expanded(
                child: second ?? const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
  }

  Widget _buildSummaryStatCards(DebtBucketResults results, bool isMobile) {
    final c1 = StatCard(
      title: 'Existing Equity MF (No New SIP)',
      primaryValue: CurrencyFormatter.formatCrores(results.existingEquityCrores),
      subtitle: '${CurrencyFormatter.formatINR(results.existingEquityCorpus)} (${results.equityPct.toStringAsFixed(1)}%)',
      note: 'Compounded at ${(results.inputs.equityReturnRate * 100).toStringAsFixed(0)}% for ${results.inputs.horizonYears.toInt()} yrs',
      icon: Icons.trending_up_rounded,
      accentColor: AppTheme.primaryNavy,
    );

    final c2 = StatCard(
      title: 'Accumulated Debt / Arbitrage Bucket',
      primaryValue: CurrencyFormatter.formatCompactINR(results.accumulatedDebtBucket),
      subtitle: '${CurrencyFormatter.formatCrores(results.accumulatedDebtCrores)} (${results.debtPct.toStringAsFixed(1)}%)',
      note: '₹${(results.inputs.redirectedMonthlySIP / 1000).toInt()}k/mo at ${(results.inputs.debtReturnRate * 100).toStringAsFixed(1)}% p.a.',
      icon: Icons.account_balance_wallet_outlined,
      accentColor: const Color(0xFFD97706),
      isHighlighted: true,
    );

    final c3 = StatCard(
      title: 'Projected Safe EPF Corpus',
      primaryValue: CurrencyFormatter.formatCrores(results.projectedEPFCrores),
      subtitle: '${CurrencyFormatter.formatINR(results.projectedEPF)} (${results.epfPct.toStringAsFixed(1)}%)',
      note: 'Compounded at ${(results.inputs.epfReturnRate * 100).toStringAsFixed(2)}% p.a.',
      icon: Icons.security_rounded,
      accentColor: AppTheme.secondaryTeal,
    );

    final c4 = StatCard(
      title: 'Total Combined Corpus',
      primaryValue: CurrencyFormatter.formatCrores(results.totalCombinedCrores),
      subtitle: 'Delta vs 100% Equity SIP: -₹${(-results.deltaVsAllEquity / 100000).toStringAsFixed(2)}L',
      note: '= Equity MF + Debt Bucket + EPF',
      icon: Icons.savings_outlined,
      accentColor: AppTheme.primaryNavy,
      isHighlighted: true,
    );

    if (isMobile) {
      return Column(
        children: [
          c1,
          const SizedBox(height: 10),
          c2,
          const SizedBox(height: 10),
          c3,
          const SizedBox(height: 10),
          c4,
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: c1),
            const SizedBox(width: 12),
            Expanded(child: c2),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: c3),
            const SizedBox(width: 12),
            Expanded(child: c4),
          ],
        ),
      ],
    );
  }

  Widget _buildOptionCard(DebtShiftTradeoffOption opt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderLight),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  opt.title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.primaryNavy),
                ),
              ),
              Text(
                CurrencyFormatter.formatCrores(opt.totalCrores),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.primaryNavy),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            opt.description,
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.bgLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _buildOptionMetric('Equity MF', CurrencyFormatter.formatCrores(opt.equityCrores)),
                _buildOptionMetric('Debt Bucket', CurrencyFormatter.formatCompactINR(opt.debtBucketValue)),
                _buildOptionMetric('EPF', CurrencyFormatter.formatCrores(opt.epfCrores)),
                _buildOptionMetric(
                  'Delta vs Equity',
                  opt.deltaVsAllEquity == 0
                      ? 'Benchmark'
                      : '-₹${(-opt.deltaVsAllEquity / 100000).toStringAsFixed(1)}L',
                  color: opt.deltaVsAllEquity == 0 ? AppTheme.textMuted : AppTheme.shortfallRed,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.receipt_long_outlined, size: 14, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  opt.taxImplication,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionMetric(String label, String value, {Color? color}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color ?? AppTheme.textDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(DebtBucketResults results) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline_rounded, color: AppTheme.surplusGreen, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Key Takeaway: The "Cost of Peace of Mind"',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF065F46),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Diverting ₹90k/mo to 7% Debt accumulates ₹35.94 Lakhs of stable debt reserves at Year 3 while surrendering only ₹2.83 Lakhs in potential equity gains compared to an all-equity SIP. This provides a guaranteed cash-flow cushion heading into retirement with zero upfront capital gains tax.',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF047857), height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

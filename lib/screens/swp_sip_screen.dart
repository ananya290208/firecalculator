import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../controllers/fire_calculator_controller.dart';
import '../models/swp_sip_models.dart';
import '../services/swp_sip_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/currency_input_field.dart';
import '../widgets/exit_dialog.dart';
import '../widgets/metric_badge.dart';
import '../widgets/swp_sip_chart.dart';

class SwpSipScreen extends StatefulWidget {
  final FireCalculatorController controller;

  const SwpSipScreen({super.key, required this.controller});

  @override
  State<SwpSipScreen> createState() => _SwpSipScreenState();
}

class _SwpSipScreenState extends State<SwpSipScreen> {
  late SwpSipInputs _inputs;

  @override
  void initState() {
    super.initState();
    final cInputs = widget.controller.inputs;
    _inputs = SwpSipInputs(
      initialMFCorpus: cInputs.currentMFValue,
      monthlySwpAmount: 0.0,
      horizonYears: cInputs.targetYears,
      swpBucketReturn: 0.0,
      sipBucketReturn: 0.0,
      baselineReturn: cInputs.expectedMFReturn,
      baselineSIP: cInputs.monthlyMFSIP,
      currentEPF: cInputs.currentEPFBalance,
      monthlyEPF: cInputs.monthlyEPFContribution,
      epfReturn: cInputs.expectedEPFReturn,
      currentCostBasis: cInputs.currentMFCostBasis,
      ltcgTaxRate: cInputs.ltcgTaxRate,
      currentMonthlyExpenses: cInputs.currentMonthlyExpenses,
      expectedInflationRate: cInputs.expectedInflationRate,
    );
  }

  void _updateInputs(SwpSipInputs newInputs) {
    setState(() {
      _inputs = newInputs;
    });
  }

  @override
  Widget build(BuildContext context) {
    final results = SwpSipService.calculate(_inputs);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SWP-to-SIP Strategy Simulator',
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
                      // Overview Banner
                      _buildInfoBanner(),
                      const SizedBox(height: 14),

                      // Parameters Card
                      _buildParametersCard(isMobile),
                      const SizedBox(height: 16),

                      // Chart Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Portfolio Compounding Trajectory (Stay Invested vs. SWP-to-SIP)',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 14),
                              SwpSipChart(
                                points: results.trajectory,
                                height: isMobile ? 220.0 : (isDesktop ? 320.0 : 260.0),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Strategy Comparison Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Strategy Comparison Results',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreenLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Horizon: ${_inputs.horizonYears.toInt()} Yrs',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.secondaryTeal,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Mobile Card View vs Tablet/Desktop DataTable
                      if (isMobile)
                        ...results.scenarios.map((s) => _buildMobileScenarioCard(s, results.baselineResult))
                      else
                        _buildDesktopDataTable(results),

                      const SizedBox(height: 14),

                      // Upfront LTCG Cash-Out Callout
                      _buildTaxNoteCard(results),

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
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.swap_horiz_rounded, color: Color(0xFF1D4ED8), size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CASH OUT MF -> MONTHLY SWP INTO FRESH SIP SIMULATOR',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E40AF),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Simulates cashing out starting MF (₹3.50 Cr) into a conservative SWP bucket (8-9%) paying out a monthly SIP (₹1.75L) into an equity fund (12-14%), compared to leaving the money untouched compounding at 12% with a ₹90k SIP.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF3B82F6),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParametersCard(bool isMobile) {
    final fields = [
      CurrencyInputField(
        label: 'Starting MF Corpus (₹)',
        guidance: 'Initial equity to cash-out',
        initialValue: _inputs.initialMFCorpus,
        type: InputType.currency,
        min: 0,
        max: 500000000,
        step: 1000000,
        quickChips: const [0, 20000000, 30000000, 35000000, 40000000],
        onChanged: (val) => _updateInputs(_inputs.copyWith(initialMFCorpus: val)),
      ),
      CurrencyInputField(
        label: 'Monthly SWP-to-SIP (₹)',
        guidance: 'Piped into Equity SIP monthly',
        initialValue: _inputs.monthlySwpAmount,
        type: InputType.currency,
        min: 0,
        max: 2000000,
        step: 5000,
        quickChips: const [0, 100000, 150000, 175000, 200000],
        onChanged: (val) => _updateInputs(_inputs.copyWith(monthlySwpAmount: val)),
      ),
      CurrencyInputField(
        label: 'Horizon in Years',
        guidance: 'e.g. 6 yrs = 72 months',
        initialValue: _inputs.horizonYears,
        type: InputType.years,
        min: 0,
        max: 15,
        step: 1,
        quickChips: const [0, 3, 5, 6, 7, 10],
        onChanged: (val) => _updateInputs(_inputs.copyWith(horizonYears: val)),
      ),
      CurrencyInputField(
        label: 'SWP Bucket Return (% p.a.)',
        guidance: 'Conservative bucket rate',
        initialValue: _inputs.swpBucketReturn,
        type: InputType.percentage,
        min: 0,
        max: 0.16,
        step: 0.005,
        quickChips: const [0.0, 0.08, 0.09, 0.10, 0.12],
        onChanged: (val) => _updateInputs(_inputs.copyWith(swpBucketReturn: val)),
      ),
      CurrencyInputField(
        label: 'SIP Equity Return (% p.a.)',
        guidance: 'Equity growth rate',
        initialValue: _inputs.sipBucketReturn,
        type: InputType.percentage,
        min: 0,
        max: 0.20,
        step: 0.005,
        quickChips: const [0.0, 0.10, 0.12, 0.13, 0.14],
        onChanged: (val) => _updateInputs(_inputs.copyWith(sipBucketReturn: val)),
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
                  'Configurable Simulation Assumptions',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                Wrap(
                  spacing: 6,
                  children: [
                    TextButton(
                      onPressed: () => _updateInputs(const SwpSipInputs()),
                      child: const Text('Clear (Blank)', style: TextStyle(fontSize: 11)),
                    ),
                    TextButton(
                      onPressed: () => _updateInputs(SwpSipInputs.promptDefaults()),
                      child: const Text('Load ₹3.50Cr Example', style: TextStyle(fontSize: 11)),
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

  Widget _buildMobileScenarioCard(SwpSipScenarioResult s, SwpSipScenarioResult baseline) {
    final bool isGain = s.deltaVsStayInvested >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: s.isBaseline ? const Color(0xFFF0FDF4) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: s.isBaseline ? AppTheme.primaryNavy : AppTheme.borderLight,
          width: s.isBaseline ? 1.5 : 1.0,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  s.title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ),
              if (s.isBaseline)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryTeal,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'BASELINE',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildMiniCol('Combined Total', CurrencyFormatter.formatCrores(s.combinedTotalCrores), isBold: true),
              _buildMiniCol('SWP Rem.', CurrencyFormatter.formatCrores(s.swpRemainingCrores)),
              _buildMiniCol('SIP Acc.', CurrencyFormatter.formatCrores(s.sipAccumulatedCrores)),
              _buildMiniCol('EPF', CurrencyFormatter.formatCrores(s.projectedEPF / 10000000.0)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                s.isBaseline ? 'Benchmark' : 'Delta: ${isGain ? "+" : ""}${CurrencyFormatter.formatCompactINR(s.deltaVsStayInvested)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: s.isBaseline
                      ? AppTheme.textMuted
                      : (isGain ? AppTheme.surplusGreen : AppTheme.shortfallRed),
                ),
              ),
              MetricBadge(surplus: s.surplus25x, compact: true, labelPrefix: '25x'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopDataTable(SwpSipComparisonResults results) {
    final allScenarios = [results.baselineResult, ...results.scenarios];

    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppTheme.primaryNavy.withOpacity(0.06)),
          columnSpacing: 18,
          columns: const [
            DataColumn(label: Text('Strategy Scenario', style: TextStyle(fontWeight: FontWeight.w800))),
            DataColumn(label: Text('Combined MF (₹ Cr)', style: TextStyle(fontWeight: FontWeight.w800))),
            DataColumn(label: Text('SWP Rem. Bucket', style: TextStyle(fontWeight: FontWeight.w800))),
            DataColumn(label: Text('SIP Acc. Bucket', style: TextStyle(fontWeight: FontWeight.w800))),
            DataColumn(label: Text('EPF at Horizon', style: TextStyle(fontWeight: FontWeight.w800))),
            DataColumn(label: Text('Total Corpus (Cr)', style: TextStyle(fontWeight: FontWeight.w800))),
            DataColumn(label: Text('Delta vs. Stay Invested', style: TextStyle(fontWeight: FontWeight.w800))),
            DataColumn(label: Text('25x Gap', style: TextStyle(fontWeight: FontWeight.w800))),
          ],
          rows: allScenarios.map((s) {
            final isGain = s.deltaVsStayInvested >= 0;
            return DataRow(
              color: WidgetStateProperty.all(
                s.isBaseline ? const Color(0xFFF0FDF4) : Colors.transparent,
              ),
              cells: [
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      s.title,
                      style: TextStyle(
                        fontWeight: s.isBaseline ? FontWeight.w800 : FontWeight.w600,
                        color: s.isBaseline ? AppTheme.secondaryTeal : null,
                      ),
                    ),
                    if (s.isBaseline) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.star_rounded, size: 16, color: AppTheme.secondaryTeal),
                    ],
                  ],
                )),
                DataCell(Text(CurrencyFormatter.formatCrores(s.combinedMFCrores))),
                DataCell(Text(CurrencyFormatter.formatCrores(s.swpRemainingCrores))),
                DataCell(Text(CurrencyFormatter.formatCrores(s.sipAccumulatedCrores))),
                DataCell(Text(CurrencyFormatter.formatCrores(s.projectedEPF / 10000000.0))),
                DataCell(Text(
                  CurrencyFormatter.formatCrores(s.combinedTotalCrores),
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primaryNavy),
                )),
                DataCell(Text(
                  s.isBaseline ? 'Baseline' : '${isGain ? "+" : ""}${CurrencyFormatter.formatCompactINR(s.deltaVsStayInvested)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: s.isBaseline
                        ? AppTheme.textMuted
                        : (isGain ? AppTheme.surplusGreen : AppTheme.shortfallRed),
                  ),
                )),
                DataCell(MetricBadge(surplus: s.surplus25x, compact: true)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMiniCol(String label, String value, {bool isBold = false}) {
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
              style: TextStyle(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                color: isBold ? AppTheme.primaryNavy : AppTheme.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxNoteCard(SwpSipComparisonResults results) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFB45309), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Crucial Tax Drag Insight (Upfront LTCG Impact)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Cashing out ₹${(results.inputs.initialMFCorpus / 10000000).toStringAsFixed(2)} Cr upfront to start an SWP triggers an immediate 12.5% LTCG tax liability of ~₹${(results.upfrontCashoutLtcgTax / 100000).toStringAsFixed(2)} Lakhs on gains above ₹1.25L. By contrast, Staying Invested leaves 100% of the untaxed corpus compounding in equity undisturbed.',
                  style: const TextStyle(fontSize: 12, color: Color(0xFFB45309), height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

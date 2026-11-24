import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../controllers/fire_calculator_controller.dart';
import '../models/liabilities_emi_models.dart';
import '../models/physical_assets_models.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/currency_input_field.dart';
import '../widgets/exit_dialog.dart';
import '../widgets/metric_badge.dart';
import '../widgets/stat_card.dart';

class LiabilitiesEmiScreen extends StatefulWidget {
  final FireCalculatorController controller;

  const LiabilitiesEmiScreen({super.key, required this.controller});

  @override
  State<LiabilitiesEmiScreen> createState() => _LiabilitiesEmiScreenState();
}

class _LiabilitiesEmiScreenState extends State<LiabilitiesEmiScreen> {
  bool _showItemizedEmis = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final emiInputs = widget.controller.emiInputs;
        final emiResults = widget.controller.emiResults;
        final fireInputs = widget.controller.inputs;
        final physicalInputs = widget.controller.physicalAssetsInputs;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Liabilities & Post-Retirement EMI',
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

                if (isDesktop) {
                  // Desktop 2-pane view (Inputs 44% left, Results 56% right)
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildInfoBanner(),
                            const SizedBox(height: 18),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left 44%: Inputs & Assumptions
                                Expanded(
                                  flex: 44,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _buildSectionTitle(
                                        '1. LOAN & EMI PARAMETERS',
                                        'Current monthly loan commitments & remaining tenure',
                                        Icons.receipt_long_outlined,
                                        AppTheme.primaryNavy,
                                      ),
                                      const SizedBox(height: 12),
                                      _buildEmiInputsCard(
                                          emiInputs, fireInputs, physicalInputs,
                                          isMobile: false),
                                      const SizedBox(height: 16),
                                      _buildSectionTitle(
                                        '2. SIP SQUEEZE SIMULATION',
                                        'Model how active EMIs reduce your monthly equity investments',
                                        Icons.compress_rounded,
                                        const Color(0xFFB45309),
                                      ),
                                      const SizedBox(height: 12),
                                      _buildSipSqueezeCard(
                                          emiInputs, fireInputs),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 24),

                                // Right 56%: Live Results & Target Impact
                                Expanded(
                                  flex: 56,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _buildHeroCard(emiResults, emiInputs),
                                      const SizedBox(height: 16),
                                      _buildTenureBreakdownCard(
                                          emiResults, emiInputs, fireInputs),
                                      const SizedBox(height: 16),
                                      _buildSectionTitle(
                                        '3. ADJUSTED FIRE READINESS TARGETS',
                                        'Separating lifestyle 25x/30x targets from capitalized debt liability',
                                        Icons.analytics_outlined,
                                        AppTheme.secondaryTeal,
                                      ),
                                      const SizedBox(height: 12),
                                      _buildAdjustedTargetsCard(
                                          emiResults, isMobile: false),
                                      if (emiResults.isSipSqueezed) ...[
                                        const SizedBox(height: 16),
                                        _buildSipSqueezeResultCard(emiResults),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                // Mobile & Tablet Stacked View
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 12 : 16,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildInfoBanner(),
                          const SizedBox(height: 14),

                          // Top Hero Card
                          _buildHeroCard(emiResults, emiInputs),
                          const SizedBox(height: 16),

                          // Section 1: Inputs
                          _buildSectionTitle(
                            '1. LOAN & EMI PARAMETERS',
                            'Current monthly loan commitments & remaining tenure',
                            Icons.receipt_long_outlined,
                            AppTheme.primaryNavy,
                          ),
                          const SizedBox(height: 12),
                          _buildEmiInputsCard(
                              emiInputs, fireInputs, physicalInputs,
                              isMobile: isMobile),
                          const SizedBox(height: 16),

                          // Section 2: Tenure Breakdown
                          _buildTenureBreakdownCard(
                              emiResults, emiInputs, fireInputs),
                          const SizedBox(height: 16),

                          // Section 3: SIP Squeeze
                          _buildSectionTitle(
                            '2. SIP SQUEEZE SIMULATION',
                            'Model how active EMIs reduce your monthly equity investments',
                            Icons.compress_rounded,
                            const Color(0xFFB45309),
                          ),
                          const SizedBox(height: 12),
                          _buildSipSqueezeCard(emiInputs, fireInputs),
                          const SizedBox(height: 16),

                          // Section 4: Adjusted Targets
                          _buildSectionTitle(
                            '3. ADJUSTED FIRE READINESS TARGETS',
                            'Separating lifestyle 25x/30x targets from capitalized debt liability',
                            Icons.analytics_outlined,
                            AppTheme.secondaryTeal,
                          ),
                          const SizedBox(height: 12),
                          _buildAdjustedTargetsCard(emiResults,
                              isMobile: isMobile),

                          if (emiResults.isSipSqueezed) ...[
                            const SizedBox(height: 16),
                            _buildSipSqueezeResultCard(emiResults),
                          ],

                          const SizedBox(height: 40),
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
          Icon(Icons.account_balance_outlined,
              color: Color(0xFF1D4ED8), size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LIABILITIES & POST-RETIREMENT EMI INTEGRATION',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E40AF),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Differentiates your pure lifestyle FIRE targets from temporary loan commitments. EMIs extending past retirement are capitalized into an upfront liability Present Value (PV), so your day-to-day living expense multiple is never distorted.',
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

  Widget _buildSectionTitle(
      String title, String subtitle, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(
      LiabilitiesEmiResults results, LiabilitiesEmiInputs inputs) {
    final bool hasOverhang = results.hasPostRetirementEmi;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasOverhang
              ? [const Color(0xFF9A3412), const Color(0xFFEA580C)]
              : [AppTheme.primaryNavy, const Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (hasOverhang ? Colors.deepOrange : AppTheme.primaryNavy)
                .withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'POST-RETIREMENT EMI LIABILITY (PV)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  hasOverhang
                      ? '${results.postRetirementEmiMonths} Mo Overhang'
                      : 'Zero Debt Overhang',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyFormatter.formatINR(results.postRetirementEmiPv),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasOverhang
                ? 'Capitalized reserve required at retirement date to fund ₹${CurrencyFormatter.formatCompactINR(results.totalMonthlyEmi)}/mo for ${results.postRetirementEmiMonths} remaining months.'
                : 'All existing loan EMIs will be 100% paid off before your target retirement date (${results.retirementMonths} months).',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildHeroMetric(
                  'Total Monthly EMI',
                  CurrencyFormatter.formatINR(results.totalMonthlyEmi),
                ),
              ),
              Container(width: 1, height: 32, color: Colors.white24),
              const SizedBox(width: 10),
              Expanded(
                child: _buildHeroMetric(
                  'Remaining Tenure',
                  inputs.tenureFormatted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmiInputsCard(LiabilitiesEmiInputs inputs, dynamic fireInputs,
      PhysicalAssetsInputs physicalInputs,
      {required bool isMobile}) {
    final homeWithLoanList = physicalInputs.apartments
        .where((a) =>
            a.hasMortgage ||
            a.monthlyEmi > 0 ||
            a.mortgageBalance > 0 ||
            a.isSelfOccupied)
        .toList();
    final ApartmentProperty? primaryHome =
        homeWithLoanList.isNotEmpty ? homeWithLoanList.first : null;
    final double minRequiredHomeLoanEmi = primaryHome != null &&
            (primaryHome.hasMortgage || primaryHome.monthlyEmi > 0)
        ? primaryHome.monthlyEmi
        : 0.0;
    final bool isEmiLesserThanHomeLoan = minRequiredHomeLoanEmi > 0 &&
        (inputs.totalMonthlyEmi < minRequiredHomeLoanEmi ||
            (_showItemizedEmis && inputs.homeLoanEmi < minRequiredHomeLoanEmi));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Home Asset & Mortgage Integration Section
            _buildHomeAssetSection(
                context, physicalInputs, inputs, primaryHome),
            const SizedBox(height: 12),

            // Mode switch: Consolidated Total vs Itemized EMIs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Monthly EMI Structure',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  ),
                  icon: Icon(
                    _showItemizedEmis
                        ? Icons.unfold_less_rounded
                        : Icons.format_list_bulleted_rounded,
                    size: 16,
                  ),
                  label: Text(_showItemizedEmis ? 'Consolidate' : 'Itemize Loans',
                      style: const TextStyle(fontSize: 11)),
                  onPressed: () {
                    setState(() {
                      _showItemizedEmis = !_showItemizedEmis;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (!_showItemizedEmis) ...[
              // Consolidated Total Monthly EMI Field
              CurrencyInputField(
                label: 'Total Monthly EMI (₹)',
                guidance: 'All active loans combined',
                initialValue: inputs.totalMonthlyEmi,
                type: InputType.currency,
                min: 0,
                max: 2000000,
                step: 5000,
                quickChips: const [0, 25000, 50000, 75000, 100000],
                onChanged: (val) {
                  widget.controller.updateEmiField(
                    customTotalMonthlyEmi: val,
                  );
                },
              ),
            ] else ...[
              // Itemized Inputs
              CurrencyInputField(
                label: 'Home Loan EMI (₹)',
                guidance: 'Long-term housing debt',
                initialValue: inputs.homeLoanEmi,
                type: InputType.currency,
                min: 0,
                max: 1500000,
                step: 5000,
                quickChips: const [0, 30000, 50000, 75000],
                onChanged: (val) {
                  widget.controller.updateEmiField(
                    homeLoanEmi: val,
                    clearCustomTotal: true,
                  );
                },
              ),
              const SizedBox(height: 10),
              CurrencyInputField(
                label: 'Car Loan EMI (₹)',
                guidance: 'Vehicle debt',
                initialValue: inputs.carLoanEmi,
                type: InputType.currency,
                min: 0,
                max: 500000,
                step: 2000,
                quickChips: const [0, 15000, 25000],
                onChanged: (val) {
                  widget.controller.updateEmiField(
                    carLoanEmi: val,
                    clearCustomTotal: true,
                  );
                },
              ),
              const SizedBox(height: 10),
              CurrencyInputField(
                label: 'Personal / Other Loan EMIs (₹)',
                guidance: 'Unsecured or education debt',
                initialValue: inputs.personalLoanEmi + inputs.otherLoanEmi,
                type: InputType.currency,
                min: 0,
                max: 500000,
                step: 2000,
                quickChips: const [0, 10000, 20000],
                onChanged: (val) {
                  widget.controller.updateEmiField(
                    personalLoanEmi: val,
                    otherLoanEmi: 0.0,
                    clearCustomTotal: true,
                  );
                },
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.bgLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Summed Monthly EMI:',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600)),
                    Text(
                      CurrencyFormatter.formatINR(inputs.totalMonthlyEmi),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryNavy),
                    ),
                  ],
                ),
              ),
            ],

            // Warning Alert if entered EMI is lesser than the linked Home Loan EMI
            if (isEmiLesserThanHomeLoan) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFDC2626),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Warning: Entered EMI is less than Home Loan EMI!',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF991B1B),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Your linked Home Property has a mandatory monthly loan EMI of ₹${CurrencyFormatter.formatINR(minRequiredHomeLoanEmi)}. You entered ₹${CurrencyFormatter.formatINR(inputs.totalMonthlyEmi)}/mo. Total EMI should be at least ₹${CurrencyFormatter.formatINR(minRequiredHomeLoanEmi)}.',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFB91C1C),
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                              foregroundColor: Colors.white,
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              textStyle: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                            icon: const Icon(Icons.check_circle_outline,
                                size: 14),
                            label: Text(
                              'Auto-Fix: Set EMI to ₹${CurrencyFormatter.formatCompactINR(minRequiredHomeLoanEmi)}',
                            ),
                            onPressed: () {
                              widget.controller.updateEmiField(
                                homeLoanEmi: minRequiredHomeLoanEmi,
                                customTotalMonthlyEmi: minRequiredHomeLoanEmi,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Remaining EMI Tenure Stepper & Slider
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Remaining EMI Tenure',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreenLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        inputs.tenureFormatted,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.secondaryTeal,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Slider(
                  value: inputs.remainingEmiMonths.toDouble(),
                  min: 0,
                  max: 300,
                  divisions: 60,
                  label: '${inputs.remainingEmiMonths} Mo',
                  onChanged: (val) {
                    widget.controller
                        .updateEmiField(remainingEmiMonths: val.round());
                  },
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [0, 24, 36, 60, 84, 120, 180, 240].map((m) {
                      final bool isSel = inputs.remainingEmiMonths == m;
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: ChoiceChip(
                          label: Text('$m Mo',
                              style: const TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w600)),
                          selected: isSel,
                          visualDensity: VisualDensity.compact,
                          onSelected: (_) => widget.controller
                              .updateEmiField(remainingEmiMonths: m),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Loan Interest Rate & Outstanding Principal
            CurrencyInputField(
              label: 'Loan Interest Rate (% p.a.)',
              guidance: 'e.g. 8.50% p.a.',
              initialValue: inputs.loanInterestRate,
              type: InputType.percentage,
              min: 0.0,
              max: 0.20,
              step: 0.0025,
              quickChips: const [0.0, 0.075, 0.08, 0.085, 0.09, 0.10],
              onChanged: (val) =>
                  widget.controller.updateEmiField(loanInterestRate: val),
            ),
            const SizedBox(height: 10),
            CurrencyInputField(
              label: 'Outstanding Loan Principal (₹)',
              guidance: 'Total principal balance today (optional)',
              initialValue: inputs.outstandingLoanPrincipal,
              type: InputType.currency,
              min: 0,
              max: 50000000,
              step: 500000,
              quickChips: const [0, 2000000, 3500000, 5000000],
              onChanged: (val) => widget.controller
                  .updateEmiField(outstandingLoanPrincipal: val),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeAssetSection(
    BuildContext context,
    PhysicalAssetsInputs physicalInputs,
    LiabilitiesEmiInputs emiInputs,
    ApartmentProperty? primaryHome,
  ) {
    if (primaryHome != null &&
        (primaryHome.hasMortgage ||
            primaryHome.monthlyEmi > 0 ||
            primaryHome.marketValue > 0)) {
      return Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryNavy.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.home_outlined,
                            size: 18, color: AppTheme.primaryNavy),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              primaryHome.name.isNotEmpty
                                  ? primaryHome.name
                                  : 'Primary Residence',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryNavy,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              primaryHome.hasMortgage
                                  ? 'Linked Home Loan & Auto-Populated'
                                  : 'Primary Home (No Active Mortgage)',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      tooltip: 'Edit Home Asset & Loan',
                      visualDensity: VisualDensity.compact,
                      onPressed: () =>
                          _showAddHomeAssetDialog(context, primaryHome),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 16, color: Colors.redAccent),
                      tooltip: 'Remove Home Loan',
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        widget.controller.removeHomeAssetLoan(primaryHome.id);
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: Color(0xFFDCFCE7)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildMiniAssetMetric(
                    'Market Value',
                    CurrencyFormatter.formatINR(primaryHome.marketValue),
                  ),
                ),
                Expanded(
                  child: _buildMiniAssetMetric(
                    'Mortgage Balance',
                    CurrencyFormatter.formatINR(primaryHome.mortgageBalance),
                    valueColor: Colors.deepOrange,
                  ),
                ),
                Expanded(
                  child: _buildMiniAssetMetric(
                    'Home Loan EMI',
                    '₹${CurrencyFormatter.formatCompactINR(primaryHome.monthlyEmi)}/mo',
                    valueColor: AppTheme.primaryNavy,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Unlinked placeholder banner
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFFE0E7FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.add_home_work_outlined,
                size: 18, color: Color(0xFF4338CA)),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Have a Home Property with Loan?',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'Enter home market value & loan to auto-populate EMI.',
                  style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              backgroundColor: const Color(0xFFEEF2FF),
              foregroundColor: const Color(0xFF4338CA),
            ),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text(
              'Add Home Loan',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
            onPressed: () => _showAddHomeAssetDialog(context, null),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniAssetMetric(String label, String value,
      {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 9,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: valueColor ?? const Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddHomeAssetDialog(
      BuildContext context, ApartmentProperty? existing) {
    final nameController = TextEditingController(
      text: existing?.name ?? 'Primary Residence',
    );
    final marketValueController = TextEditingController(
      text: existing != null && existing.marketValue > 0
          ? existing.marketValue.toStringAsFixed(0)
          : '10000000',
    );
    final loanBalanceController = TextEditingController(
      text: existing != null && existing.mortgageBalance > 0
          ? existing.mortgageBalance.toStringAsFixed(0)
          : '4500000',
    );
    final emiController = TextEditingController(
      text: existing != null && existing.monthlyEmi > 0
          ? existing.monthlyEmi.toStringAsFixed(0)
          : '40000',
    );
    final tenureController = TextEditingController(
      text: existing != null && existing.remainingEmiMonths > 0
          ? existing.remainingEmiMonths.toString()
          : '180',
    );
    final rateController = TextEditingController(
      text: existing != null && existing.loanInterestRate > 0
          ? (existing.loanInterestRate * 100).toStringAsFixed(2)
          : '8.50',
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryNavy.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.home_work_outlined,
                    color: AppTheme.primaryNavy, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  existing == null
                      ? 'Link Home Property & Loan'
                      : 'Edit Home Property & Loan',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Values entered here will auto-populate your monthly EMI, outstanding debt liability, and link property equity to Net Worth.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Property Name / Identifier',
                      hintText: 'e.g. Primary Residence / 3BHK Flat',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: marketValueController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Current Market Value (₹)',
                      hintText: 'e.g. 10000000 for 1 Cr',
                      border: OutlineInputBorder(),
                      isDense: true,
                      prefixText: '₹ ',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: loanBalanceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Outstanding Loan Principal (₹)',
                      hintText: 'e.g. 4500000 for 45 Lakhs',
                      border: OutlineInputBorder(),
                      isDense: true,
                      prefixText: '₹ ',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emiController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Monthly Home Loan EMI (₹)',
                      hintText: 'e.g. 40000',
                      border: OutlineInputBorder(),
                      isDense: true,
                      prefixText: '₹ ',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: tenureController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Tenure (Months)',
                            hintText: 'e.g. 180',
                            border: OutlineInputBorder(),
                            isDense: true,
                            suffixText: 'Mo',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: rateController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Interest Rate',
                            hintText: 'e.g. 8.5',
                            border: OutlineInputBorder(),
                            isDense: true,
                            suffixText: '%',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryNavy,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Save & Auto-Populate EMI'),
              onPressed: () {
                final marketVal = double.tryParse(marketValueController.text
                        .replaceAll(RegExp(r'[^0-9.]'), '')) ??
                    0.0;
                final loanBal = double.tryParse(loanBalanceController.text
                        .replaceAll(RegExp(r'[^0-9.]'), '')) ??
                    0.0;
                final monthlyEmi = double.tryParse(
                        emiController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ??
                    0.0;
                final tenure = int.tryParse(tenureController.text
                        .replaceAll(RegExp(r'[^0-9]'), '')) ??
                    0;
                final rate = (double.tryParse(rateController.text
                            .replaceAll(RegExp(r'[^0-9.]'), '')) ??
                        8.5) /
                    100.0;

                widget.controller.setHomeAssetWithLoan(
                  id: existing?.id,
                  name: nameController.text.trim().isEmpty
                      ? 'Primary Residence'
                      : nameController.text.trim(),
                  marketValue: marketVal,
                  loanBalance: loanBal,
                  monthlyEmi: monthlyEmi,
                  remainingMonths: tenure,
                  loanInterestRate: rate,
                );

                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Home Asset and Loan EMI auto-populated successfully!',
                    ),
                    duration: Duration(seconds: 3),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTenureBreakdownCard(LiabilitiesEmiResults results,
      LiabilitiesEmiInputs emiInputs, dynamic fireInputs) {
    final int retMo = results.retirementMonths;
    final int preRetMo = results.emiMonthsBeforeRetirement;
    final int postRetMo = results.postRetirementEmiMonths;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Timeline: Active EMIs vs. Retirement Date',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildTimelineBox(
                  title: 'Retirement Horizon',
                  subtitle: '${fireInputs.targetYears.toInt()} Years',
                  value: '$retMo Months',
                  color: AppTheme.primaryNavy,
                ),
                const SizedBox(width: 8),
                _buildTimelineBox(
                  title: 'Pre-Retirement EMI',
                  subtitle: 'Funded from active income',
                  value: '$preRetMo Months',
                  color: AppTheme.secondaryTeal,
                ),
                const SizedBox(width: 8),
                _buildTimelineBox(
                  title: 'Post-Retirement Overhang',
                  subtitle: postRetMo > 0 ? 'Capitalized in PV' : 'Debt-Free',
                  value: '$postRetMo Months',
                  color: postRetMo > 0
                      ? const Color(0xFFDC2626)
                      : AppTheme.surplusGreen,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Discounting assumption switch
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.bgLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tune_rounded,
                      size: 18, color: AppTheme.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Post-Retirement PV Discount Rate:',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          emiInputs.discountPostRetirementEmiAtInflation
                              ? 'Inflation Rate (${(fireInputs.expectedInflationRate * 100).toStringAsFixed(1)}% p.a.)'
                              : 'Loan Interest Rate (${(emiInputs.loanInterestRate * 100).toStringAsFixed(2)}% p.a.)',
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: emiInputs.discountPostRetirementEmiAtInflation,
                    onChanged: (val) {
                      widget.controller.updateEmiField(
                          discountPostRetirementEmiAtInflation: val);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineBox({
    required String title,
    required String subtitle,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w600, color: color)),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800, color: color),
              ),
            ),
            Text(subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 9, color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildSipSqueezeCard(
      LiabilitiesEmiInputs emiInputs, dynamic fireInputs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enable Pre-Retirement SIP Squeeze',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Model lower MF SIP while actively paying EMIs',
                        style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: emiInputs.enableSipSqueeze,
                  onChanged: (val) {
                    widget.controller
                        .updateEmiField(enableSipSqueeze: val);
                  },
                ),
              ],
            ),
            if (emiInputs.enableSipSqueeze) ...[
              const SizedBox(height: 12),
              CurrencyInputField(
                label: 'Reduced Monthly MF SIP during EMI (₹)',
                guidance:
                    'Normal SIP: ₹${CurrencyFormatter.formatCompactINR(fireInputs.monthlyMFSIP)}/mo',
                initialValue: emiInputs.reducedMonthlyMfSipDuringEmi,
                type: InputType.currency,
                min: 0,
                max: fireInputs.monthlyMFSIP,
                step: 5000,
                quickChips: const [20000, 30000, 40000, 50000],
                onChanged: (val) {
                  widget.controller.updateEmiField(
                      reducedMonthlyMfSipDuringEmi: val);
                },
              ),
              const SizedBox(height: 8),
              Text(
                'During the first ${min(emiInputs.remainingEmiMonths, (fireInputs.targetYears * 12).round())} active EMI months, SIP is simulated at ₹${CurrencyFormatter.formatCompactINR(emiInputs.reducedMonthlyMfSipDuringEmi)}/mo. After EMI completes, it resumes at ₹${CurrencyFormatter.formatCompactINR(fireInputs.monthlyMFSIP)}/mo.',
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textMuted, height: 1.3),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdjustedTargetsCard(
      LiabilitiesEmiResults results, {required bool isMobile}) {
    final c1 = StatCard(
      title: '25x Adjusted FIRE Target',
      primaryValue: CurrencyFormatter.formatCompactINR(results.adjustedFire25x),
      subtitle:
          '= Lifestyle 25x (${CurrencyFormatter.formatCrores(results.lifestyleFire25xCrores)}) + EMI PV (${CurrencyFormatter.formatCrores(results.postRetirementEmiPvCrores)})',
      note: 'Target including full debt coverage',
      icon: Icons.flag_outlined,
      accentColor: AppTheme.blue25x,
    );

    final c2 = StatCard(
      title: 'Surplus / (Shortfall) 25x Adj.',
      primaryValue:
          CurrencyFormatter.formatCompactINR(results.surplus25xAdjusted),
      subtitle: results.surplus25xAdjusted >= 0
          ? 'Surplus with EMIs Covered'
          : 'Gap to Bridge with Debt',
      note: '= Total Available Corpus - 25x Adjusted',
      trailingBadge: MetricBadge(
          surplus: results.surplus25xAdjusted, compact: true),
      accentColor: results.surplus25xAdjusted >= 0
          ? AppTheme.surplusGreen
          : AppTheme.shortfallRed,
      isHighlighted: true,
    );

    final c3 = StatCard(
      title: '30x Adjusted FIRE Target',
      primaryValue: CurrencyFormatter.formatCompactINR(results.adjustedFire30x),
      subtitle:
          '= Lifestyle 30x (${CurrencyFormatter.formatCrores(results.lifestyleFire30xCrores)}) + EMI PV (${CurrencyFormatter.formatCrores(results.postRetirementEmiPvCrores)})',
      note: 'Conservative 3.33% SWR + Debt PV',
      icon: Icons.shield_moon_outlined,
      accentColor: AppTheme.purple30x,
    );

    final c4 = StatCard(
      title: 'Surplus / (Shortfall) 30x Adj.',
      primaryValue:
          CurrencyFormatter.formatCompactINR(results.surplus30xAdjusted),
      subtitle: results.surplus30xAdjusted >= 0
          ? 'Fully Funded with Debt Overhang'
          : 'Deficit vs Conservative Target',
      note: '= Total Available Corpus - 30x Adjusted',
      trailingBadge: MetricBadge(
          surplus: results.surplus30xAdjusted, compact: true),
      accentColor: results.surplus30xAdjusted >= 0
          ? AppTheme.surplusGreen
          : AppTheme.shortfallRed,
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

  Widget _buildSipSqueezeResultCard(LiabilitiesEmiResults results) {
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
          const Icon(Icons.trending_down_rounded,
              color: Color(0xFFB45309), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SIP Squeeze Compounding Wealth Penalty',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Reducing your monthly MF SIP during the active ${results.emiMonthsBeforeRetirement} EMI months lowers your final projected equity corpus from ₹${CurrencyFormatter.formatCrores(results.unsqueezedMFCorpus / 10000000)} to ₹${CurrencyFormatter.formatCrores(results.squeezedMFCorpus / 10000000)} (a net wealth sacrifice of -₹${(-results.sipSqueezeCorpusDelta / 100000).toStringAsFixed(2)} Lakhs at retirement).',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFFB45309), height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

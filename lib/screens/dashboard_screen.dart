import 'dart:math';
import 'package:flutter/material.dart';
import '../controllers/fire_calculator_controller.dart';
import '../models/dashboard_models.dart';
import '../models/physical_assets_models.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/currency_input_field.dart';
import '../widgets/exit_dialog.dart';
import '../widgets/metric_badge.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  final FireCalculatorController controller;
  final VoidCallback onNavigateToCalculator;
  final VoidCallback onNavigateToLiabilities;
  final VoidCallback onNavigateToSwpSip;
  final VoidCallback onNavigateToDebtBucket;
  final VoidCallback onNavigateToSchedule;

  const DashboardScreen({
    super.key,
    required this.controller,
    required this.onNavigateToCalculator,
    required this.onNavigateToLiabilities,
    required this.onNavigateToSwpSip,
    required this.onNavigateToDebtBucket,
    required this.onNavigateToSchedule,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  void _showAddApartmentDialog(BuildContext context, [ApartmentProperty? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name ?? 'Apartment');
    final valCtrl = TextEditingController(
        text: existing != null ? existing.marketValue.toStringAsFixed(0) : '15000000');
    final mortBalCtrl = TextEditingController(
        text: existing != null ? existing.mortgageBalance.toStringAsFixed(0) : '5000000');
    final emiCtrl = TextEditingController(
        text: existing != null ? existing.monthlyEmi.toStringAsFixed(0) : '45000');
    final monthsCtrl = TextEditingController(
        text: existing != null ? existing.remainingEmiMonths.toString() : '120');
    final rentCtrl = TextEditingController(
        text: existing != null ? existing.monthlyRentalIncome.toStringAsFixed(0) : '0');

    bool hasMortgage = existing?.hasMortgage ?? false;
    bool isSelfOccupied = existing?.isSelfOccupied ?? false;
    bool monetizeAtRetirement = existing?.monetizeAtRetirement ?? false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(existing == null ? 'Add Apartment / Flat' : 'Edit Apartment'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Property Name / Tag'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: valCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Current Market Value (₹)',
                      prefixText: '₹ ',
                    ),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    title: const Text('Has Mortgage / Home Loan', style: TextStyle(fontSize: 13)),
                    value: hasMortgage,
                    onChanged: (v) => setDialogState(() => hasMortgage = v),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (hasMortgage) ...[
                    TextField(
                      controller: mortBalCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Outstanding Mortgage Balance (₹)',
                        prefixText: '₹ ',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: emiCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Monthly EMI (₹)',
                              prefixText: '₹ ',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: monthsCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Remaining Months',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  SwitchListTile(
                    title: const Text('Primary / Self-Occupied Residence', style: TextStyle(fontSize: 13)),
                    subtitle: const Text('Excluded from liquid FIRE drawdown', style: TextStyle(fontSize: 11)),
                    value: isSelfOccupied,
                    onChanged: (v) => setDialogState(() {
                      isSelfOccupied = v;
                      if (v) {
                        monetizeAtRetirement = false;
                        rentCtrl.text = '0';
                      }
                    }),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (!isSelfOccupied) ...[
                    TextField(
                      controller: rentCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Monthly Rental Income (₹)',
                        prefixText: '₹ ',
                      ),
                    ),
                    SwitchListTile(
                      title: const Text('Liquidate / Sell at Retirement', style: TextStyle(fontSize: 13)),
                      subtitle: const Text('Adds proceeds to FIRE corpus', style: TextStyle(fontSize: 11)),
                      value: monetizeAtRetirement,
                      onChanged: (v) => setDialogState(() => monetizeAtRetirement = v),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              if (existing != null)
                TextButton(
                  onPressed: () {
                    widget.controller.removeApartment(existing.id);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final apt = ApartmentProperty(
                    id: existing?.id ?? 'apt_${DateTime.now().millisecondsSinceEpoch}',
                    name: nameCtrl.text.trim().isEmpty ? 'Apartment' : nameCtrl.text.trim(),
                    marketValue: double.tryParse(valCtrl.text) ?? 0.0,
                    hasMortgage: hasMortgage,
                    mortgageBalance:
                        hasMortgage ? (double.tryParse(mortBalCtrl.text) ?? 0.0) : 0.0,
                    monthlyEmi: hasMortgage ? (double.tryParse(emiCtrl.text) ?? 0.0) : 0.0,
                    remainingEmiMonths:
                        hasMortgage ? (int.tryParse(monthsCtrl.text) ?? 0) : 0,
                    isSelfOccupied: isSelfOccupied,
                    monthlyRentalIncome:
                        isSelfOccupied ? 0.0 : (double.tryParse(rentCtrl.text) ?? 0.0),
                    monetizeAtRetirement: isSelfOccupied ? false : monetizeAtRetirement,
                  );

                  if (existing == null) {
                    widget.controller.addApartment(apt);
                  } else {
                    widget.controller.updateApartment(apt);
                  }
                  Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddLandDialog(BuildContext context, [LandProperty? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name ?? 'Plot / Land');
    final valCtrl = TextEditingController(
        text: existing != null ? existing.marketValue.toStringAsFixed(0) : '8000000');
    final rentCtrl = TextEditingController(
        text: existing != null ? existing.monthlyRentalIncome.toStringAsFixed(0) : '0');
    bool monetize = existing?.monetizeAtRetirement ?? false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(existing == null ? 'Add Land / Plot' : 'Edit Land'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Plot / Land Name'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: valCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Current Market Value (₹)',
                      prefixText: '₹ ',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: rentCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Monthly Lease / Rental Income (₹)',
                      prefixText: '₹ ',
                    ),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    title: const Text('Monetize / Sell at Retirement', style: TextStyle(fontSize: 13)),
                    subtitle: const Text('Adds compounded proceeds to FIRE corpus', style: TextStyle(fontSize: 11)),
                    value: monetize,
                    onChanged: (v) => setDialogState(() => monetize = v),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            actions: [
              if (existing != null)
                TextButton(
                  onPressed: () {
                    widget.controller.removeLand(existing.id);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final land = LandProperty(
                    id: existing?.id ?? 'land_${DateTime.now().millisecondsSinceEpoch}',
                    name: nameCtrl.text.trim().isEmpty ? 'Land' : nameCtrl.text.trim(),
                    marketValue: double.tryParse(valCtrl.text) ?? 0.0,
                    monthlyRentalIncome: double.tryParse(rentCtrl.text) ?? 0.0,
                    monetizeAtRetirement: monetize,
                  );

                  if (existing == null) {
                    widget.controller.addLand(land);
                  } else {
                    widget.controller.updateLand(land);
                  }
                  Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final summary = widget.controller.dashboardSummary;
        final physicalInputs = widget.controller.physicalAssetsInputs;
        final physicalResults = widget.controller.physicalAssetsResults;
        final fireInputs = widget.controller.inputs;

        return Scaffold(
          appBar: AppBar(
            title: const Row(
              children: [
                Icon(Icons.dashboard_rounded, color: AppTheme.primaryNavy, size: 22),
                SizedBox(width: 8),
                Text(
                  'FIRE & Net Worth Dashboard',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
              ],
            ),
            actions: const [
              ExitButton(),
              SizedBox(width: 6),
            ],
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double screenWidth = constraints.maxWidth;
                final bool isMobile = screenWidth < 600;
                final bool isDesktop = screenWidth >= 1024;

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 12 : 20,
                        vertical: 14,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Executive Master Hero Card (Net Worth & FIRE Readiness)
                          _buildExecutiveHeroCard(summary, isMobile),
                          const SizedBox(height: 16),

                          // 2. Horizon quick-toggle chips
                          _buildHorizonChips(fireInputs.targetYears),
                          const SizedBox(height: 16),

                          // 3. Asset Allocation Breakdown Bar & Legend
                          _buildAssetAllocationSection(summary, isMobile),
                          const SizedBox(height: 20),

                          // 4. Main Matrix: Left (Assets & Properties) + Right (FIRE Health & Liabilities)
                          if (isDesktop)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left 50%: Physical Assets, Real Estate, Gold, Cash
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      _buildRealEstateSection(physicalInputs, physicalResults, isMobile),
                                      const SizedBox(height: 16),
                                      _buildGoldSection(physicalInputs.gold, isMobile),
                                      const SizedBox(height: 16),
                                      _buildCashSection(physicalInputs.cash, isMobile),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 20),

                                // Right 50%: FIRE Health, Cashflow Offset, Liabilities
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      _buildFireReadinessMatrix(summary, isMobile),
                                      const SizedBox(height: 16),
                                      _buildLiabilitiesSummaryCard(summary, isMobile),
                                      const SizedBox(height: 16),
                                      _buildQuickJumpCards(),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildFireReadinessMatrix(summary, isMobile),
                                const SizedBox(height: 16),
                                _buildRealEstateSection(physicalInputs, physicalResults, isMobile),
                                const SizedBox(height: 16),
                                _buildGoldSection(physicalInputs.gold, isMobile),
                                const SizedBox(height: 16),
                                _buildCashSection(physicalInputs.cash, isMobile),
                                const SizedBox(height: 16),
                                _buildLiabilitiesSummaryCard(summary, isMobile),
                                const SizedBox(height: 16),
                                _buildQuickJumpCards(),
                              ],
                            ),

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

  Widget _buildExecutiveHeroCard(ComprehensiveFireSummary summary, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F766E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.all(isMobile ? 16 : 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Tag + Readiness Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'COMPREHENSIVE FIRE EXECUTIVE DASHBOARD',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: summary.isFireReady
                      ? const Color(0xFF10B981).withOpacity(0.9)
                      : const Color(0xFFF59E0B).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  summary.readinessStatus,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Two Primary Figures: Total Net Worth & Projected FIRE Corpus
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL NET WORTH TODAY',
                      style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        CurrencyFormatter.formatCrores(summary.totalNetWorth / 10000000.0),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        CurrencyFormatter.formatINR(summary.totalNetWorth),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 50, color: Colors.white24),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PROJECTED FIRE CORPUS (YR ${summary.targetYears.toInt()})',
                      style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        CurrencyFormatter.formatCrores(summary.totalProjectedFireCorpus / 10000000.0),
                        style: const TextStyle(
                          color: Color(0xFF34D399),
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        CurrencyFormatter.formatINR(summary.totalProjectedFireCorpus),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),

          // Funding Progress & Quick Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '30x Target Funded: ${summary.fundingPercentage30x.toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Surplus (30x): ${summary.surplus30x >= 0 ? "+" : ""}${CurrencyFormatter.formatCompactINR(summary.surplus30x)}',
                    style: TextStyle(
                      color: summary.surplus30x >= 0 ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: min(1.0, summary.fundingPercentage30x / 100.0),
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(
                summary.isFireReady ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizonChips(double currentYears) {
    final horizons = [1.0, 3.0, 5.0, 6.0, 7.0, 10.0, 15.0];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const Text(
            'Target Horizon: ',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textMuted),
          ),
          const SizedBox(width: 6),
          ...horizons.map((yr) {
            final isSelected = (currentYears - yr).abs() < 0.1;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                label: Text('${yr.toInt()} Yrs'),
                selected: isSelected,
                selectedColor: AppTheme.primaryNavy.withOpacity(0.15),
                checkmarkColor: AppTheme.primaryNavy,
                labelStyle: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected ? AppTheme.primaryNavy : AppTheme.textDark,
                ),
                onSelected: (_) {
                  widget.controller.updateField(targetYears: yr);
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAssetAllocationSection(ComprehensiveFireSummary summary, bool isMobile) {
    if (summary.allocationSlices.isEmpty) return const SizedBox.shrink();

    return Card(
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
                    'Asset Allocation & Portfolio Distribution',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Total: ${CurrencyFormatter.formatCrores(summary.totalGrossAssets / 10000000.0)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textMuted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 14,
                child: Row(
                  children: summary.allocationSlices.map((slice) {
                    return Expanded(
                      flex: max(1, (slice.percentage * 10).round()),
                      child: Container(
                        color: Color(slice.colorValue),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 14,
              runSpacing: 8,
              children: summary.allocationSlices.map((slice) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Color(slice.colorValue),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${slice.label}: ${slice.percentage.toStringAsFixed(1)}% (${CurrencyFormatter.formatCompactINR(slice.amount)})',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealEstateSection(
    PhysicalAssetsInputs inputs,
    PhysicalAssetsResults results,
    bool isMobile,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.home_work_rounded, color: Color(0xFF059669), size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'REAL ESTATE & PROPERTIES',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Land, apartments, mortgages & rental yields',
                        style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Add Property',
                  icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF059669)),
                  onSelected: (val) {
                    if (val == 'apt') _showAddApartmentDialog(context);
                    if (val == 'land') _showAddLandDialog(context);
                  },
                  itemBuilder: (ctx) => const [
                    PopupMenuItem(value: 'apt', child: Text('Add Apartment / Flat')),
                    PopupMenuItem(value: 'land', child: Text('Add Land / Plot')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Summary metrics bar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Value', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            CurrencyFormatter.formatCompactINR(results.totalRealEstateValue),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Mortgage Debt', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            CurrencyFormatter.formatCompactINR(results.totalMortgageBalance),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: results.totalMortgageBalance > 0 ? Colors.red : AppTheme.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Rental Income', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '₹${CurrencyFormatter.formatCompactINR(results.totalMonthlyRentalIncome)}/mo',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Itemized list of apartments & lands
            if (inputs.apartments.isEmpty && inputs.lands.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: TextButton.icon(
                    onPressed: () => _showAddApartmentDialog(context),
                    icon: const Icon(Icons.add_home_outlined),
                    label: const Text('Add your first property (Flat or Plot)'),
                  ),
                ),
              )
            else ...[
              ...inputs.apartments.map((apt) => _buildApartmentTile(apt)),
              ...inputs.lands.map((land) => _buildLandTile(land)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildApartmentTile(ApartmentProperty apt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            apt.isSelfOccupied ? Icons.night_shelter_outlined : Icons.apartment_rounded,
            color: const Color(0xFF059669),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        apt.name,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (apt.isSelfOccupied) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Primary Home', style: TextStyle(fontSize: 9, color: Colors.blue)),
                      ),
                    ],
                  ],
                ),
                Text(
                  'Value: ${CurrencyFormatter.formatCompactINR(apt.marketValue)} ${apt.hasMortgage ? "• Mortgage: -${CurrencyFormatter.formatCompactINR(apt.mortgageBalance)}" : "• Debt-Free"}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
                if (apt.monthlyRentalIncome > 0)
                  Text(
                    'Rent: ₹${CurrencyFormatter.formatCompactINR(apt.monthlyRentalIncome)}/mo',
                    style: const TextStyle(fontSize: 10, color: Color(0xFF2563EB), fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 16),
            onPressed: () => _showAddApartmentDialog(context, apt),
          ),
        ],
      ),
    );
  }

  Widget _buildLandTile(LandProperty land) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.landscape_rounded, color: Color(0xFF10B981), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(land.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                Text(
                  'Value: ${CurrencyFormatter.formatCompactINR(land.marketValue)} ${land.monetizeAtRetirement ? "• Earmarked to Sell at FIRE" : "• Retained"}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 16),
            onPressed: () => _showAddLandDialog(context, land),
          ),
        ],
      ),
    );
  }

  Widget _buildGoldSection(GoldAssets gold, bool isMobile) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.circle_rounded, color: Color(0xFFD97706), size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PRECIOUS METALS / GOLD ASSETS',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Solid Gold (Bullion/SGB) & Gold Ornaments',
                        style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    CurrencyFormatter.formatCompactINR(gold.totalGoldValue),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFFD97706)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Inputs: Solid Gold & Ornaments
            CurrencyInputField(
              label: 'Solid Gold Value (Bullion, SGB, ETF)',
              guidance: 'Liquid investment gold (₹)',
              initialValue: gold.solidGoldValue,
              type: InputType.currency,
              onChanged: (val) => widget.controller.updateGold(solidGoldValue: val),
            ),
            const SizedBox(height: 10),
            CurrencyInputField(
              label: 'Gold Ornaments (Physical Jewellery)',
              guidance: 'Family & sentimental ornaments (₹)',
              initialValue: gold.ornamentsGoldValue,
              type: InputType.currency,
              onChanged: (val) => widget.controller.updateGold(ornamentsGoldValue: val),
            ),
            const SizedBox(height: 10),

            // Toggles
            CheckboxListTile(
              title: const Text('Include Solid Gold in Liquid FIRE Corpus', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              subtitle: const Text('Earmarks solid bullion & SGB to fund retirement drawdown', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
              value: gold.includeSolidInFireCorpus,
              onChanged: (val) => widget.controller.updateGold(includeSolidInFireCorpus: val ?? true),
              contentPadding: EdgeInsets.zero,
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              title: const Text('Include Ornaments in FIRE Corpus', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              subtitle: const Text('Default is false (kept for heritage, included in Net Worth only)', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
              value: gold.includeOrnamentsInFireCorpus,
              onChanged: (val) => widget.controller.updateGold(includeOrnamentsInFireCorpus: val ?? false),
              contentPadding: EdgeInsets.zero,
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashSection(CashAssets cash, bool isMobile) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF6366F1), size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CASH & LIQUID RESERVES',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Cash in hand, bank savings & fixed deposits',
                        style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    CurrencyFormatter.formatCompactINR(cash.totalCashAndDeposits),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF6366F1)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            CurrencyInputField(
              label: 'Cash in Hand / Savings Accounts',
              guidance: 'Immediately accessible liquid cash (₹)',
              initialValue: cash.cashInHand,
              type: InputType.currency,
              onChanged: (val) => widget.controller.updateCash(cashInHand: val),
            ),
            const SizedBox(height: 10),
            CurrencyInputField(
              label: 'Fixed Deposits & Liquid Debt Funds',
              guidance: 'Bank FDs & Treasury/Liquid funds (₹)',
              initialValue: cash.fixedDeposits,
              type: InputType.currency,
              onChanged: (val) => widget.controller.updateCash(fixedDeposits: val),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFireReadinessMatrix(ComprehensiveFireSummary summary, bool isMobile) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.insights_rounded, color: AppTheme.primaryNavy, size: 20),
                SizedBox(width: 8),
                Text(
                  'FIRE Readiness & Cashflow Bridge',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Cashflow offset breakdown
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text('Future Annual Expenses:', style: TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          CurrencyFormatter.formatINR(summary.futureGrossAnnualExpenses),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  if (summary.hasRentalIncome) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Less: Property Rental Income:',
                            style: TextStyle(fontSize: 12, color: Color(0xFF059669)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '-${CurrencyFormatter.formatINR(summary.annualRentalIncome)}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Net Portfolio Drawdown Needed:',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            CurrencyFormatter.formatINR(summary.netAnnualExpenseDrawdown),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.primaryNavy),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 25x and 30x Targets vs Total Corpus
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: '25x Adjusted Target',
                    primaryValue: CurrencyFormatter.formatCrores(summary.adjustedFire25x / 10000000.0),
                    subtitle: '4.0% SWR + Debt PV',
                    trailingBadge: MetricBadge(surplus: summary.surplus25x, compact: true),
                    accentColor: AppTheme.blue25x,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatCard(
                    title: '30x Adjusted Target',
                    primaryValue: CurrencyFormatter.formatCrores(summary.adjustedFire30x / 10000000.0),
                    subtitle: '3.33% SWR + Debt PV',
                    trailingBadge: MetricBadge(surplus: summary.surplus30x, compact: true),
                    accentColor: AppTheme.purple30x,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiabilitiesSummaryCard(ComprehensiveFireSummary summary, bool isMobile) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.account_balance_outlined, color: Colors.redAccent, size: 20),
                SizedBox(width: 8),
                Text(
                  'Outstanding Debt & Overhang PV',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Total Outstanding Debt',
                    primaryValue: CurrencyFormatter.formatCompactINR(summary.totalOutstandingLiabilities),
                    subtitle: 'Mortgages + Loans',
                    accentColor: summary.totalOutstandingLiabilities > 0 ? Colors.red : AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatCard(
                    title: 'Post-Retirement Debt PV',
                    primaryValue: CurrencyFormatter.formatCompactINR(summary.postRetirementEmiPv),
                    subtitle: summary.hasDebtOverhang ? 'Extra reserve needed' : 'Zero Overhang',
                    accentColor: summary.hasDebtOverhang ? Colors.red : AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickJumpCards() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Drill Down Into Simulator Modules',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.calculate_outlined, size: 16),
                  label: const Text('Calculator Engine'),
                  onPressed: widget.onNavigateToCalculator,
                ),
                ActionChip(
                  avatar: const Icon(Icons.account_balance_rounded, size: 16),
                  label: const Text('Liabilities & Loans'),
                  onPressed: widget.onNavigateToLiabilities,
                ),
                ActionChip(
                  avatar: const Icon(Icons.swap_horiz_rounded, size: 16),
                  label: const Text('SWP vs SIP Simulator'),
                  onPressed: widget.onNavigateToSwpSip,
                ),
                ActionChip(
                  avatar: const Icon(Icons.shield_rounded, size: 16),
                  label: const Text('SIP Debt Bucket'),
                  onPressed: widget.onNavigateToDebtBucket,
                ),
                ActionChip(
                  avatar: const Icon(Icons.calendar_month_rounded, size: 16),
                  label: const Text('Schedule & Matrix'),
                  onPressed: widget.onNavigateToSchedule,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

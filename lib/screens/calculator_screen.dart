import 'package:flutter/material.dart';
import '../controllers/fire_calculator_controller.dart';
import '../models/fire_inputs.dart';
import '../models/fire_results.dart';
import '../models/liabilities_emi_models.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/currency_input_field.dart';
import '../widgets/exit_dialog.dart';
import '../widgets/metric_badge.dart';
import '../widgets/projection_chart.dart';
import '../widgets/stat_card.dart';

class CalculatorScreen extends StatefulWidget {
  final FireCalculatorController controller;
  final VoidCallback onNavigateToComparison;
  final VoidCallback? onNavigateToLiabilities;
  final AuthService? authService;

  const CalculatorScreen({
    super.key,
    required this.controller,
    required this.onNavigateToComparison,
    this.onNavigateToLiabilities,
    this.authService,
  });

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppTheme.primaryGreen),
            SizedBox(width: 8),
            Text('Log Out'),
          ],
        ),
        content: Text(
          'Log out of account "${widget.authService?.userName}" on this device?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.authService?.logout();
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final inputs = widget.controller.inputs;
        final results = widget.controller.results;
        final emiInputs = widget.controller.emiInputs;
        final emiResults = widget.controller.emiResults;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'FIRE Simulator (INR)',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            actions: [
              IconButton(
                tooltip: 'Save to Compare',
                icon: const Icon(Icons.bookmark_add_outlined),
                onPressed: () => _promptSaveCombination(context),
              ),
              PopupMenuButton<String>(
                tooltip: 'More Options',
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (val) {
                  if (val == 'blank') {
                    widget.controller.resetToBlank();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All fields reset to blank'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else if (val == 'reset') {
                    widget.controller.resetToExcelDefault();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Loaded default Excel parameters (3Y, ₹1.25L)'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else if (val == 'logout') {
                    _confirmLogout(context);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'blank',
                    child: Row(
                      children: [
                        Icon(Icons.clear_all_rounded, size: 20),
                        SizedBox(width: 10),
                        Text('Clear to Blank'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'reset',
                    child: Row(
                      children: [
                        Icon(Icons.refresh_rounded, size: 20),
                        SizedBox(width: 10),
                        Text('Load Excel Baseline'),
                      ],
                    ),
                  ),
                  if (widget.authService != null)
                    PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          const Icon(Icons.logout_rounded, size: 20),
                          const SizedBox(width: 10),
                          Text('Log Out (${widget.authService!.userName})'),
                        ],
                      ),
                    ),
                ],
              ),
              const ExitButton(),
              const SizedBox(width: 4),
            ],
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double screenWidth = constraints.maxWidth;
                final bool isMobile = screenWidth < 600;
                final bool isDesktop = screenWidth >= 1024;

                if (isDesktop) {
                  // Desktop & Web (>= 1024dp): 2-pane split view (Inputs 42% left, Results & Chart 58% right)
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildInstructionsBanner(),
                            const SizedBox(height: 12),
                            _buildPresetChips(inputs),
                            const SizedBox(height: 18),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left 42%: Section 1 Inputs & Assumptions
                                Expanded(
                                  flex: 42,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      _buildSectionHeader(
                                        title: '1. YOUR INPUTS & ASSUMPTIONS',
                                        subtitle: 'Edit any field to dynamically recalculate targets',
                                        icon: Icons.tune_rounded,
                                        color: const Color(0xFFB45309),
                                      ),
                                      const SizedBox(height: 12),
                                      _buildInputsList(inputs, isMobile: true), // 1 per row in left 42% column
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 24),

                                // Right 58%: Hero Card, Compounding Chart, & Section 2 Outputs
                                Expanded(
                                  flex: 58,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      _buildHeroCard(results, emiResults: emiResults, isMobile: false),
                                      const SizedBox(height: 16),
                                      Card(
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Compounding Trajectory vs. Targets',
                                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                              ),
                                              const SizedBox(height: 12),
                                              ProjectionChart(
                                                projections: results.yearlyProjections,
                                                currentTarget25xCr: (emiResults.hasPostRetirementEmi
                                                        ? emiResults.adjustedFire25x
                                                        : results.fireTarget25x) /
                                                    10000000.0,
                                                currentTarget30xCr: (emiResults.hasPostRetirementEmi
                                                        ? emiResults.adjustedFire30x
                                                        : results.fireTarget30x) /
                                                    10000000.0,
                                                height: 260.0,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      if (_hasActiveLiabilities(emiInputs, emiResults)) ...[
                                        _buildLiabilitiesFireImpactCard(emiInputs, emiResults, results, isMobile: false),
                                        const SizedBox(height: 18),
                                      ],
                                      _buildSectionHeader(
                                        title: '2. LIVE RETIREMENT READINESS OUTPUTS',
                                        subtitle: 'Calculated instantly from your assumptions',
                                        icon: Icons.analytics_outlined,
                                        color: AppTheme.primaryNavy,
                                      ),
                                      const SizedBox(height: 12),
                                      _buildOutputsGrid(inputs, results, emiInputs: emiInputs, emiResults: emiResults, isMobile: false),
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

                // Mobile (< 600dp) & Tablet (600-1023dp): Stacked view
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
                          // Instructions banner
                          _buildInstructionsBanner(),
                          const SizedBox(height: 12),

                          // Quick Preset Chips
                          _buildPresetChips(inputs),
                          const SizedBox(height: 16),

                          // ⭐️ TOTAL PROJECTED CORPUS Banner HIGHLIGHTED ON TOP OF SECTION 1
                          _buildHeroCard(results, emiResults: emiResults, isMobile: isMobile),
                          const SizedBox(height: 20),

                          // Section 1: Inputs & Assumptions
                          _buildSectionHeader(
                            title: '1. YOUR INPUTS & ASSUMPTIONS',
                            subtitle: 'Edit any field to dynamically recalculate targets & schedule',
                            icon: Icons.tune_rounded,
                            color: const Color(0xFFB45309),
                          ),
                          const SizedBox(height: 12),
                          _buildInputsList(inputs, isMobile: isMobile),
                          const SizedBox(height: 24),

                          // Liabilities & Debt Impact on FIRE (when filled)
                          if (_hasActiveLiabilities(emiInputs, emiResults)) ...[
                            _buildLiabilitiesFireImpactCard(emiInputs, emiResults, results, isMobile: isMobile),
                            const SizedBox(height: 20),
                          ],

                          // Section 2: Live Retirement Readiness Outputs
                          _buildSectionHeader(
                            title: '2. LIVE RETIREMENT READINESS OUTPUTS',
                            subtitle: 'Calculated instantly from your assumptions above',
                            icon: Icons.analytics_outlined,
                            color: AppTheme.primaryNavy,
                          ),
                          const SizedBox(height: 12),
                          _buildOutputsGrid(inputs, results, emiInputs: emiInputs, emiResults: emiResults, isMobile: isMobile),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _promptSaveCombination(context),
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.compare_arrows_rounded),
            label: const Text(
              'Save to Compare',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInstructionsBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.accentAmberLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentAmber.withOpacity(0.4)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFFB45309), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Enter fields in Section 1 to dynamically recalculate year Year-By-Year Corpus and FIRE targets.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChips(FireInputs currentInputs) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const Text(
            'Quick Presets: ',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textMuted),
          ),
          const SizedBox(width: 4),
          ActionChip(
            label: const Text('Clear to Blank'),
            avatar: const Icon(Icons.clear_all_rounded, size: 14),
            onPressed: () => widget.controller.resetToBlank(),
          ),
          const SizedBox(width: 6),
          ActionChip(
            label: const Text('Excel Baseline (3Y, ₹1.25L)'),
            avatar: const Icon(Icons.tune_outlined, size: 14),
            onPressed: () => widget.controller.resetToExcelDefault(),
          ),
          const SizedBox(width: 6),
          ActionChip(
            label: const Text('3-Year Upper (₹2.00L)'),
            onPressed: () => widget.controller.updateField(
              targetYears: 3,
              currentMonthlyExpenses: 200000,
            ),
          ),
          const SizedBox(width: 6),
          ActionChip(
            label: const Text('6-Year Base (₹1.25L)'),
            onPressed: () => widget.controller.updateField(
              targetYears: 6,
              currentMonthlyExpenses: 125000,
            ),
          ),
          const SizedBox(width: 6),
          ActionChip(
            label: const Text('7-Year Stress-Test (₹2.00L)'),
            avatar: const Icon(Icons.shield_outlined, size: 14),
            onPressed: () => widget.controller.updateInputs(FireInputs.sevenYearStressTest()),
          ),
        ],
      ),
    );
  }

  bool _hasActiveLiabilities(
    LiabilitiesEmiInputs emiInputs,
    LiabilitiesEmiResults emiResults,
  ) {
    return emiInputs.totalMonthlyEmi > 0 ||
        emiInputs.outstandingLoanPrincipal > 0 ||
        emiInputs.remainingEmiMonths > 0 ||
        emiResults.isSipSqueezed;
  }

  Widget _buildHeroCard(
    FireResults results, {
    required LiabilitiesEmiResults emiResults,
    bool isMobile = false,
  }) {
    final bool hasOverhang = emiResults.hasPostRetirementEmi;
    final bool hasSqueeze = emiResults.isSipSqueezed;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryGreenDark,
            AppTheme.primaryGreen,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'TOTAL PROJECTED CORPUS',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasOverhang) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE11D48).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '+${CurrencyFormatter.formatCompactINR(emiResults.postRetirementEmiPv)} Debt PV',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      CurrencyFormatter.formatCrores(
                        (hasSqueeze ? emiResults.totalCorpus : results.totalProjectedCorpus) /
                            10000000.0,
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyFormatter.formatINR(
                hasSqueeze ? emiResults.totalCorpus : results.totalProjectedCorpus,
              ),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),

          // Two Target Comparison Rows
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        hasOverhang ? '25x Adjusted Target' : '25x FIRE Rule (4.0% SWR)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        CurrencyFormatter.formatCompactINR(
                          hasOverhang ? emiResults.adjustedFire25x : results.fireTarget25x,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (hasOverhang) ...[
                      const SizedBox(height: 1),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Base ${CurrencyFormatter.formatCompactINR(results.fireTarget25x)} + Debt',
                          style: const TextStyle(color: Colors.white60, fontSize: 9),
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    MetricBadge(
                      surplus: hasOverhang || hasSqueeze
                          ? emiResults.surplus25xAdjusted
                          : results.surplus25x,
                      compact: true,
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 46, color: Colors.white24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        hasOverhang ? '30x Adjusted Target' : '30x FIRE Rule (3.33% SWR)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        CurrencyFormatter.formatCompactINR(
                          hasOverhang ? emiResults.adjustedFire30x : results.fireTarget30x,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (hasOverhang) ...[
                      const SizedBox(height: 1),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Base ${CurrencyFormatter.formatCompactINR(results.fireTarget30x)} + Debt',
                          style: const TextStyle(color: Colors.white60, fontSize: 9),
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    MetricBadge(
                      surplus: hasOverhang || hasSqueeze
                          ? emiResults.surplus30xAdjusted
                          : results.surplus30x,
                      compact: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiabilitiesFireImpactCard(
    LiabilitiesEmiInputs emiInputs,
    LiabilitiesEmiResults emiResults,
    FireResults results, {
    required bool isMobile,
  }) {
    final bool hasOverhang = emiResults.hasPostRetirementEmi;
    final Color accentColor =
        hasOverhang ? const Color(0xFFE11D48) : AppTheme.primaryGreen;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: hasOverhang
              ? const Color(0xFFE11D48).withOpacity(0.35)
              : AppTheme.primaryGreen.withOpacity(0.35),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row: Icon, Title, Overhang badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    hasOverhang
                        ? Icons.warning_amber_rounded
                        : Icons.account_balance_rounded,
                    color: accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'LIABILITIES & DEBT IMPACT ON FIRE',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        hasOverhang
                            ? 'Post-retirement debt increases your capital requirement'
                            : 'All current loan EMIs will be cleared before retirement date',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: hasOverhang
                        ? const Color(0xFFFFF1F2)
                        : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: hasOverhang
                          ? const Color(0xFFFDA4AF)
                          : const Color(0xFFA7F3D0),
                    ),
                  ),
                  child: Text(
                    hasOverhang
                        ? '${emiResults.postRetirementEmiMonths} Mo Overhang'
                        : 'Zero Overhang',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: hasOverhang
                          ? const Color(0xFFE11D48)
                          : const Color(0xFF059669),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // Key Metrics Summary Grid
            isMobile
                ? Column(
                    children: [
                      _buildImpactItem(
                        label: 'Active Monthly EMI',
                        value: CurrencyFormatter.formatINR(emiResults.totalMonthlyEmi),
                        subtitle: '${emiInputs.tenureFormatted} total tenure',
                        accentColor: AppTheme.primaryNavy,
                      ),
                      const SizedBox(height: 10),
                      _buildImpactItem(
                        label: 'Post-Retirement Debt PV',
                        value: CurrencyFormatter.formatCompactINR(emiResults.postRetirementEmiPv),
                        subtitle: hasOverhang
                            ? 'Extra reserve needed at retirement'
                            : '₹0 liability after retirement',
                        accentColor: accentColor,
                      ),
                      const SizedBox(height: 10),
                      _buildImpactItem(
                        label: '25x Adjusted FIRE Target',
                        value: CurrencyFormatter.formatCrores(emiResults.adjustedFire25x / 10000000.0),
                        subtitle: 'Lifestyle ${CurrencyFormatter.formatCompactINR(results.fireTarget25x)} + Debt ${CurrencyFormatter.formatCompactINR(emiResults.postRetirementEmiPv)}',
                        trailingBadge: MetricBadge(surplus: emiResults.surplus25xAdjusted, compact: true),
                        accentColor: AppTheme.blue25x,
                      ),
                      const SizedBox(height: 10),
                      _buildImpactItem(
                        label: '30x Adjusted FIRE Target',
                        value: CurrencyFormatter.formatCrores(emiResults.adjustedFire30x / 10000000.0),
                        subtitle: 'Lifestyle ${CurrencyFormatter.formatCompactINR(results.fireTarget30x)} + Debt ${CurrencyFormatter.formatCompactINR(emiResults.postRetirementEmiPv)}',
                        trailingBadge: MetricBadge(surplus: emiResults.surplus30xAdjusted, compact: true),
                        accentColor: AppTheme.purple30x,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _buildImpactItem(
                          label: 'Active Monthly EMI',
                          value: CurrencyFormatter.formatINR(emiResults.totalMonthlyEmi),
                          subtitle: '${emiInputs.tenureFormatted} tenure',
                          accentColor: AppTheme.primaryNavy,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildImpactItem(
                          label: 'Post-Retirement Debt PV',
                          value: CurrencyFormatter.formatCompactINR(emiResults.postRetirementEmiPv),
                          subtitle: hasOverhang
                              ? 'Extra reserve needed at retirement'
                              : '₹0 liability after retirement',
                          accentColor: accentColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildImpactItem(
                          label: '25x Adjusted Target',
                          value: CurrencyFormatter.formatCrores(emiResults.adjustedFire25x / 10000000.0),
                          subtitle: 'Lifestyle + Debt PV',
                          trailingBadge: MetricBadge(surplus: emiResults.surplus25xAdjusted, compact: true),
                          accentColor: AppTheme.blue25x,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildImpactItem(
                          label: '30x Adjusted Target',
                          value: CurrencyFormatter.formatCrores(emiResults.adjustedFire30x / 10000000.0),
                          subtitle: 'Lifestyle + Debt PV',
                          trailingBadge: MetricBadge(surplus: emiResults.surplus30xAdjusted, compact: true),
                          accentColor: AppTheme.purple30x,
                        ),
                      ),
                    ],
                  ),

            // Pre-Retirement SIP Squeeze Impact Alert (if active)
            if (emiResults.isSipSqueezed) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.trending_down_rounded, color: Color(0xFFB45309), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'SIP Squeeze Active: Corpus reduced by ₹${CurrencyFormatter.formatCompactINR(-emiResults.sipSqueezeCorpusDelta)} at retirement due to reduced monthly MF investments during the first ${emiResults.emiMonthsBeforeRetirement} active EMI months.',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF92400E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            // Edit link button to navigate to Liabilities tab
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => widget.onNavigateToLiabilities?.call(),
                icon: const Icon(Icons.tune_rounded, size: 16),
                label: const Text(
                  'Edit Loan Details in Liabilities & EMI Section →',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactItem({
    required String label,
    required String value,
    required String subtitle,
    Widget? trailingBadge,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: accentColor,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
            ),
          ),
          if (trailingBadge != null) ...[
            const SizedBox(height: 4),
            trailingBadge,
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOutputsGrid(
    FireInputs inputs,
    FireResults results, {
    required LiabilitiesEmiInputs emiInputs,
    required LiabilitiesEmiResults emiResults,
    bool isMobile = false,
  }) {
    final bool hasOverhang = emiResults.hasPostRetirementEmi;
    final bool hasSqueeze = emiResults.isSipSqueezed;
    final bool hasLiabilities = _hasActiveLiabilities(emiInputs, emiResults);

    final card1 = StatCard(
      title: 'Net Reinvested MF Principal',
      primaryValue: CurrencyFormatter.formatCompactINR(results.netReinvestedMFPrincipal),
      subtitle: CurrencyFormatter.formatINR(results.netReinvestedMFPrincipal),
      note: '= Current MF * (1 - Exit Tax)',
      icon: Icons.account_balance_wallet_outlined,
    );
    final card2 = StatCard(
      title: 'Future Monthly Expenses',
      primaryValue: CurrencyFormatter.formatINR(results.futureMonthlyExpenses),
      subtitle: 'at retirement (Yr ${inputs.targetYears.toInt()})',
      note: '= Monthly Expense * (1 + Inflation)^Years',
      icon: Icons.shopping_bag_outlined,
    );
    final card3 = StatCard(
      title: 'Future Annual Expenses',
      primaryValue: CurrencyFormatter.formatINR(results.futureAnnualExpenses),
      subtitle: '${CurrencyFormatter.formatCompactINR(results.futureAnnualExpenses)}/year',
      note: '= Future Monthly * 12',
      icon: Icons.calendar_today_outlined,
    );
    final card4 = StatCard(
      title: 'Projected MF Corpus',
      primaryValue: CurrencyFormatter.formatCompactINR(
        hasSqueeze ? emiResults.squeezedMFCorpus : results.projectedMFCorpus,
      ),
      subtitle: CurrencyFormatter.formatINR(
        hasSqueeze ? emiResults.squeezedMFCorpus : results.projectedMFCorpus,
      ),
      note: hasSqueeze
          ? 'Squeezed: -${CurrencyFormatter.formatCompactINR(-emiResults.sipSqueezeCorpusDelta)} during active EMI months'
          : 'Compounded at ${CurrencyFormatter.formatPercentage(inputs.expectedMFReturn)}/yr',
      icon: Icons.trending_up_rounded,
      accentColor: const Color(0xFF0284C7),
    );
    final card5 = StatCard(
      title: 'Projected EPF Corpus',
      primaryValue: CurrencyFormatter.formatCompactINR(results.projectedEPFCorpus),
      subtitle: CurrencyFormatter.formatINR(results.projectedEPFCorpus),
      note: 'Compounded at ${CurrencyFormatter.formatPercentage(inputs.expectedEPFReturn)}/yr',
      icon: Icons.security_outlined,
      accentColor: const Color(0xFFD97706),
    );
    final card6 = StatCard(
      title: 'Total Corpus (₹ Cr)',
      primaryValue: CurrencyFormatter.formatCrores(
        (hasSqueeze ? emiResults.totalCorpus : results.totalProjectedCorpus) / 10000000.0,
      ),
      subtitle: hasSqueeze ? 'Combined (Squeezed SIP)' : 'Combined Pre-Tax',
      note: '= MF + EPF Corpus',
      icon: Icons.savings_outlined,
      accentColor: AppTheme.primaryGreen,
      isHighlighted: true,
    );
    final card7 = StatCard(
      title: hasOverhang
          ? '25x Adjusted FIRE Target'
          : '25x FIRE Target (4.0% SWR)',
      primaryValue: CurrencyFormatter.formatCompactINR(
        hasOverhang ? emiResults.adjustedFire25x : results.fireTarget25x,
      ),
      subtitle: hasOverhang
          ? 'Lifestyle: ${CurrencyFormatter.formatCompactINR(results.fireTarget25x)} + Debt: ${CurrencyFormatter.formatCompactINR(emiResults.postRetirementEmiPv)}'
          : CurrencyFormatter.formatINR(results.fireTarget25x),
      note: hasOverhang
          ? '= Lifestyle 25x + Post-Retirement EMI PV'
          : '= Annual Expense * 25',
      icon: Icons.flag_outlined,
      accentColor: AppTheme.blue25x,
    );
    final double effSurplus25x = (hasOverhang || hasSqueeze)
        ? emiResults.surplus25xAdjusted
        : results.surplus25x;
    final card8 = StatCard(
      title: hasOverhang
          ? 'Adjusted Surplus / (Shortfall) 25x'
          : 'Surplus / (Shortfall) 25x',
      primaryValue: CurrencyFormatter.formatCompactINR(effSurplus25x),
      subtitle: effSurplus25x >= 0
          ? (hasOverhang ? 'Surplus Available (After Debt)' : 'Surplus Available')
          : (hasOverhang ? 'Gap to Bridge (With Debt)' : 'Gap to Bridge'),
      note: hasOverhang
          ? '= Available Corpus - Adjusted 25x Target'
          : '= Total Corpus - 25x Target',
      trailingBadge: MetricBadge(surplus: effSurplus25x, compact: true),
      accentColor: effSurplus25x >= 0 ? AppTheme.surplusGreen : AppTheme.shortfallRed,
    );
    final card9 = StatCard(
      title: hasOverhang
          ? '30x Adjusted FIRE Target'
          : '30x FIRE Target (3.33% SWR)',
      primaryValue: CurrencyFormatter.formatCompactINR(
        hasOverhang ? emiResults.adjustedFire30x : results.fireTarget30x,
      ),
      subtitle: hasOverhang
          ? 'Lifestyle: ${CurrencyFormatter.formatCompactINR(results.fireTarget30x)} + Debt: ${CurrencyFormatter.formatCompactINR(emiResults.postRetirementEmiPv)}'
          : CurrencyFormatter.formatINR(results.fireTarget30x),
      note: hasOverhang
          ? '= Lifestyle 30x + Post-Retirement EMI PV'
          : '= Annual Expense * 30',
      icon: Icons.shield_moon_outlined,
      accentColor: AppTheme.purple30x,
    );
    final double effSurplus30x = (hasOverhang || hasSqueeze)
        ? emiResults.surplus30xAdjusted
        : results.surplus30x;
    final card10 = StatCard(
      title: hasOverhang
          ? 'Adjusted Surplus / (Shortfall) 30x'
          : 'Surplus / (Shortfall) 30x',
      primaryValue: CurrencyFormatter.formatCompactINR(effSurplus30x),
      subtitle: effSurplus30x >= 0
          ? (hasOverhang ? 'Fully Covered (After Debt)' : 'Fully Covered')
          : (hasOverhang ? 'Deficit to Fund (With Debt)' : 'Deficit to Fund'),
      note: hasOverhang
          ? '= Available Corpus - Adjusted 30x Target'
          : '= Total Corpus - 30x Target',
      trailingBadge: MetricBadge(surplus: effSurplus30x, compact: true),
      accentColor: effSurplus30x >= 0 ? AppTheme.surplusGreen : AppTheme.shortfallRed,
    );
    final card11 = StatCard(
      title: 'Est. Post-Tax Corpus (if full MF exit)',
      primaryValue: CurrencyFormatter.formatINR(results.estPostTaxCorpus),
      subtitle: '= ${CurrencyFormatter.formatCrores(results.estPostTaxCorpusCrores)} (Tax Drag: -${CurrencyFormatter.formatCompactINR(results.ltcgTax)})',
      note: 'Assumes 12.5% LTCG on equity gains above ₹1.25L exemption (EPF is tax-exempt)',
      icon: Icons.receipt_long_outlined,
      accentColor: const Color(0xFF4338CA),
      isHighlighted: true,
    );
    final card12 = hasLiabilities
        ? StatCard(
            title: 'Post-Retirement Debt Liability (PV)',
            primaryValue: CurrencyFormatter.formatCompactINR(emiResults.postRetirementEmiPv),
            subtitle: hasOverhang
                ? '${emiResults.postRetirementEmiMonths} Mo Overhang (₹${CurrencyFormatter.formatCompactINR(emiResults.totalMonthlyEmi)}/mo)'
                : 'Zero Overhang (100% Cleared Before Retirement)',
            note: hasOverhang
                ? 'Capitalized reserve needed to fund remaining loan EMIs'
                : 'All loan EMIs finish before retirement date',
            icon: Icons.account_balance_outlined,
            accentColor: hasOverhang
                ? const Color(0xFFE11D48)
                : AppTheme.primaryGreen,
            isHighlighted: hasOverhang,
          )
        : null;

    if (isMobile) {
      // Mobile version (<600dp): 1 stat card per row
      return Column(
        children: [
          card1,
          const SizedBox(height: 12),
          card2,
          const SizedBox(height: 12),
          card3,
          const SizedBox(height: 12),
          card4,
          const SizedBox(height: 12),
          card5,
          const SizedBox(height: 12),
          card6,
          const SizedBox(height: 12),
          card7,
          const SizedBox(height: 12),
          card8,
          const SizedBox(height: 12),
          card9,
          const SizedBox(height: 12),
          card10,
          const SizedBox(height: 12),
          card11,
          if (card12 != null) ...[
            const SizedBox(height: 12),
            card12,
          ],
        ],
      );
    }

    // Tablet & Desktop version (>=600dp): 2 stat cards per row
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: card1),
            const SizedBox(width: 12),
            Expanded(child: card2),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: card3),
            const SizedBox(width: 12),
            Expanded(child: card4),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: card5),
            const SizedBox(width: 12),
            Expanded(child: card6),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: card7),
            const SizedBox(width: 12),
            Expanded(child: card8),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: card9),
            const SizedBox(width: 12),
            Expanded(child: card10),
          ],
        ),
        const SizedBox(height: 12),
        if (card12 != null)
          Row(
            children: [
              Expanded(child: card11),
              const SizedBox(width: 12),
              Expanded(child: card12),
            ],
          )
        else
          card11,
      ],
    );
  }

  Widget _buildInputsList(FireInputs inputs, {bool isMobile = false}) {
    final fields = [
      // 1. Target Years
      CurrencyInputField(
        label: 'Target Years to Retire',
        guidance: 'Years (e.g. 3, 5, 6, 7)',
        initialValue: inputs.targetYears,
        type: InputType.years,
        min: 1,
        max: 30,
        step: 1,
        quickChips: const [3, 5, 6, 7, 10],
        onChanged: (val) => widget.controller.updateField(targetYears: val),
      ),

      // 2. Current Monthly Expenses
      CurrencyInputField(
        label: 'Current Monthly Expense',
        guidance: 'Today (e.g. 1.25L, 2L)',
        initialValue: inputs.currentMonthlyExpenses,
        type: InputType.currency,
        min: 10000,
        max: 10000000,
        step: 5000,
        quickChips: const [100000, 125000, 150000, 200000, 250000],
        onChanged: (val) => widget.controller.updateField(currentMonthlyExpenses: val),
      ),

      // 3. Expected Inflation Rate
      CurrencyInputField(
        label: 'Inflation Rate (% p.a.)',
        guidance: 'Default: 6.00%',
        initialValue: inputs.expectedInflationRate,
        type: InputType.percentage,
        min: 0.01,
        max: 0.20,
        step: 0.005,
        quickChips: const [0.05, 0.06, 0.07, 0.08],
        onChanged: (val) => widget.controller.updateField(expectedInflationRate: val),
      ),

      // 4. Current Mutual Fund Value
      CurrencyInputField(
        label: 'Current MF Value (₹)',
        guidance: 'e.g. ₹3.50 Cr (or 3.40 Cr)',
        initialValue: inputs.currentMFValue,
        type: InputType.currency,
        min: 0,
        max: 1000000000,
        step: 1000000,
        quickChips: const [20000000, 30000000, 34000000, 35000000, 40000000],
        onChanged: (val) => widget.controller.updateField(currentMFValue: val),
      ),

      // 5. Current MF Cost Basis
      CurrencyInputField(
        label: 'Current MF Cost Basis (₹)',
        guidance: 'For LTCG tax estimate',
        initialValue: inputs.currentMFCostBasis,
        type: InputType.currency,
        min: 0,
        max: 1000000000,
        step: 1000000,
        quickChips: const [15000000, 20000000, 21000000, 25000000],
        onChanged: (val) => widget.controller.updateField(currentMFCostBasis: val),
      ),

      // 6. Monthly Mutual Fund SIP
      CurrencyInputField(
        label: 'Monthly MF SIP (₹)',
        guidance: 'Ongoing monthly SIP',
        initialValue: inputs.monthlyMFSIP,
        type: InputType.currency,
        min: 0,
        max: 5000000,
        step: 5000,
        quickChips: const [50000, 75000, 90000, 100000, 150000],
        onChanged: (val) => widget.controller.updateField(monthlyMFSIP: val),
      ),

      // 7. Expected MF Return
      CurrencyInputField(
        label: 'Expected MF Return (% p.a.)',
        guidance: 'Cons: 12% | Init: 14%',
        initialValue: inputs.expectedMFReturn,
        type: InputType.percentage,
        min: 0.01,
        max: 0.30,
        step: 0.005,
        quickChips: const [0.10, 0.12, 0.13, 0.14, 0.15],
        onChanged: (val) => widget.controller.updateField(expectedMFReturn: val),
      ),

      // 8. Current EPF Balance
      CurrencyInputField(
        label: 'Current EPF Balance (₹)',
        guidance: 'Current EPF: ₹50 Lakhs',
        initialValue: inputs.currentEPFBalance,
        type: InputType.currency,
        min: 0,
        max: 100000000,
        step: 500000,
        quickChips: const [2500000, 4000000, 5000000, 6000000, 7500000],
        onChanged: (val) => widget.controller.updateField(currentEPFBalance: val),
      ),

      // 9. Monthly EPF Contribution
      CurrencyInputField(
        label: 'Monthly EPF Contrib (₹)',
        guidance: 'Employee + Employer',
        initialValue: inputs.monthlyEPFContribution,
        type: InputType.currency,
        min: 0,
        max: 1000000,
        step: 5000,
        quickChips: const [30000, 40000, 50000, 60000, 75000],
        onChanged: (val) => widget.controller.updateField(monthlyEPFContribution: val),
      ),

      // 10. Expected EPF Return
      CurrencyInputField(
        label: 'Expected EPF Return (% p.a.)',
        guidance: 'Current rate: 8.25%',
        initialValue: inputs.expectedEPFReturn,
        type: InputType.percentage,
        min: 0.01,
        max: 0.15,
        step: 0.0025,
        quickChips: const [0.08, 0.0815, 0.0825, 0.085],
        onChanged: (val) => widget.controller.updateField(expectedEPFReturn: val),
      ),

      // 11. Upfront MF Cash-Out
      CurrencyInputField(
        label: 'Upfront MF Cash-Out (%)',
        guidance: 'e.g. 0% or 6% exit',
        initialValue: inputs.upfrontMFCashOutRate,
        type: InputType.percentage,
        min: 0.0,
        max: 1.0,
        step: 0.01,
        quickChips: const [0.0, 0.05, 0.06, 0.10],
        onChanged: (val) => widget.controller.updateField(upfrontMFCashOutRate: val),
      ),

      // 12. LTCG Tax Rate
      CurrencyInputField(
        label: 'LTCG Tax Rate (%)',
        guidance: '12.5% on gains > ₹1.25L',
        initialValue: inputs.ltcgTaxRate,
        type: InputType.percentage,
        min: 0.0,
        max: 0.50,
        step: 0.005,
        quickChips: const [0.10, 0.125, 0.15, 0.20],
        onChanged: (val) => widget.controller.updateField(ltcgTaxRate: val),
      ),
    ];

    if (isMobile) {
      // Mobile version (<600dp): One field per row
      return Column(
        children: fields
            .map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: f,
                ))
            .toList(),
      );
    }

    // Tablet & Desktop version (>=600dp): Two fields per row
    final List<Widget> rows = [];
    for (int i = 0; i < fields.length; i += 2) {
      final first = fields[i];
      final second = (i + 1 < fields.length) ? fields[i + 1] : null;

      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: first),
                const SizedBox(width: 12),
                if (second != null)
                  Expanded(child: second)
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

  void _promptSaveCombination(BuildContext context) {
    final TextEditingController nameController = TextEditingController(
      text: '${widget.controller.inputs.targetYears.toInt()}Y • ${CurrencyFormatter.formatCompactINR(widget.controller.inputs.currentMonthlyExpenses)}/mo',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save to Comparison'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This combination will be recorded into your last 5 attempted combinations dashboard.',
                style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Scenario Title / Note',
                  hintText: 'e.g. 5Y Horizon Aggressive SIP',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final title = nameController.text.trim();
              widget.controller.saveCurrentToHistory(
                customName: title.isNotEmpty ? title : null,
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Saved "${title.isNotEmpty ? title : 'Combination'}" to Comparison tab!'),
                  action: SnackBarAction(
                    label: 'View',
                    onPressed: widget.onNavigateToComparison,
                  ),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

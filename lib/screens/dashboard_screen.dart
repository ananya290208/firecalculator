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
  void _showAddDebtHoldingDialog(BuildContext context, [DebtHolding? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name ?? 'Fixed Deposit');
    final valCtrl = TextEditingController(
        text: existing != null && existing.value > 0 ? existing.value.toStringAsFixed(0) : '');
    final returnCtrl = TextEditingController(
        text: existing != null ? (existing.returnRate * 100.0).toStringAsFixed(2) : '7.10');

    String selectedCategory = existing?.category ?? 'Fixed Deposit';
    final categories = [
      'Fixed Deposit',
      'Fixed Debt Funds',
      'Liquid Funds',
      'Recurring Deposit',
      'Treasury Bills / Govt Bonds',
      'Corporate Bonds',
      'Other Debt Holding',
    ];
    if (!categories.contains(selectedCategory)) {
      categories.insert(0, selectedCategory);
    }

    DateTime? startDate = existing?.startDate ?? DateTime.now();
    DateTime? endDate = existing?.endDate ?? DateTime.now().add(const Duration(days: 1095));

    String formatDate(DateTime? d) {
      if (d == null) return 'Select Date';
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final diffDays = (startDate != null && endDate != null) ? endDate!.difference(startDate!).inDays : 0;
          final tenureYears = diffDays > 0 ? (diffDays / 365.25).toStringAsFixed(1) : '0';

          return AlertDialog(
            title: Text(existing == null ? 'Add FD / Debt Holding' : 'Edit Holding'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: categories.map((cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat, style: const TextStyle(fontSize: 13)));
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setDialogState(() => selectedCategory = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Holding Name / Bank',
                      hintText: 'e.g. HDFC 3Y FD, ICICI Liquid Fund',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: valCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Invested Value / Principal (₹)',
                      prefixText: '₹ ',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: returnCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Annual Return / Interest (%)',
                      suffixText: '% p.a.',
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Dates Row
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today_rounded, size: 14),
                          label: Text(
                            'Start: ${formatDate(startDate)}',
                            style: const TextStyle(fontSize: 10),
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: startDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2060),
                            );
                            if (picked != null) {
                              setDialogState(() => startDate = picked);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.event_available_rounded, size: 14),
                          label: Text(
                            'End: ${formatDate(endDate)}',
                            style: const TextStyle(fontSize: 10),
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: endDate ?? (startDate?.add(const Duration(days: 365)) ?? DateTime.now()),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2060),
                            );
                            if (picked != null) {
                              setDialogState(() => endDate = picked);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  if (diffDays > 0) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Calculated Duration: $tenureYears years ($diffDays days)',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              if (existing != null)
                TextButton(
                  onPressed: () {
                    widget.controller.removeDebtHolding(existing.id);
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
                  final double val = double.tryParse(valCtrl.text.replaceAll(',', '')) ?? 0.0;
                  final double ret = (double.tryParse(returnCtrl.text) ?? 6.5) / 100.0;
                  final holding = DebtHolding(
                    id: existing?.id ?? 'debt_${DateTime.now().millisecondsSinceEpoch}',
                    name: nameCtrl.text.trim().isEmpty ? selectedCategory : nameCtrl.text.trim(),
                    category: selectedCategory,
                    value: val,
                    startDate: startDate,
                    endDate: endDate,
                    returnRate: ret,
                  );

                  if (existing == null) {
                    widget.controller.addDebtHolding(holding);
                  } else {
                    widget.controller.updateDebtHolding(holding);
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
                          // Main Matrix: Left (Assets & Properties) + Right (FIRE Health & Liabilities)
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

  Widget _buildDebtHoldingTile(DebtHolding holding) {
    String formatDate(DateTime? d) {
      if (d == null) return 'N/A';
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF6366F1), size: 18),
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
                        holding.name,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        holding.category,
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF6366F1)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${formatDate(holding.startDate)} → ${formatDate(holding.endDate)} (${holding.tenureYears.toStringAsFixed(1)} Yrs) • ${(holding.returnRate * 100).toStringAsFixed(2)}% p.a.',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.formatINR(holding.value),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF6366F1)),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => _showAddDebtHoldingDialog(context, holding),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.edit_outlined, size: 16, color: Colors.blueGrey),
                    ),
                  ),
                  InkWell(
                    onTap: () => widget.controller.removeDebtHolding(holding.id),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCashSection(CashAssets cash, bool isMobile) {
    final holdingsCount = cash.holdings.length;

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
                        'Cash in hand, bank savings, fixed deposits & debt funds',
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
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Add FD / Debt Holding',
                  icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF6366F1)),
                  onPressed: () => _showAddDebtHoldingDialog(context),
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
              label: 'Direct Fixed Deposits & Liquid Funds',
              guidance: 'Quick entry for total FDs & liquid funds (₹)',
              initialValue: cash.fixedDeposits,
              type: InputType.currency,
              onChanged: (val) => widget.controller.updateCash(fixedDeposits: val),
            ),
            const SizedBox(height: 14),

            // Itemized Holdings Header & List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'ITEMIZED FD & DEBT HOLDINGS',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                    ),
                    if (holdingsCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$holdingsCount',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF6366F1)),
                        ),
                      ),
                    ],
                  ],
                ),
                TextButton.icon(
                  onPressed: () => _showAddDebtHoldingDialog(context),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add FD / Debt', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 6),

            if (cash.holdings.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
                ),
                child: Center(
                  child: TextButton.icon(
                    onPressed: () => _showAddDebtHoldingDialog(context),
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                    label: const Text(
                      'Add individual FD, debt fund, RD or bond with dates & return %',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ),
              )
            else
              ...cash.holdings.map((h) => _buildDebtHoldingTile(h)),
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

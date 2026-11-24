import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../controllers/fire_calculator_controller.dart';
import '../models/dashboard_models.dart';
import '../models/milestone_expense_models.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../widgets/exit_dialog.dart';

class MilestoneExpensesScreen extends StatefulWidget {
  final FireCalculatorController controller;
  final VoidCallback? onNavigateToCalculator;

  const MilestoneExpensesScreen({
    super.key,
    required this.controller,
    this.onNavigateToCalculator,
  });

  @override
  State<MilestoneExpensesScreen> createState() => _MilestoneExpensesScreenState();
}

class _MilestoneExpensesScreenState extends State<MilestoneExpensesScreen> {
  Color _getCategoryColor(MilestoneCategory category) {
    switch (category) {
      case MilestoneCategory.education:
        return const Color(0xFF2563EB); // Royal Blue
      case MilestoneCategory.marriage:
        return const Color(0xFFDB2777); // Pink/Rose
      case MilestoneCategory.housing:
        return const Color(0xFFD97706); // Warm Amber
      case MilestoneCategory.vehicle:
        return const Color(0xFF0D9488); // Deep Teal
      case MilestoneCategory.travel:
        return const Color(0xFF7C3AED); // Purple
      case MilestoneCategory.health:
        return const Color(0xFF059669); // Emerald Green
      case MilestoneCategory.other:
        return const Color(0xFF475569); // Slate
    }
  }

  IconData _getCategoryIcon(MilestoneCategory category) {
    switch (category) {
      case MilestoneCategory.education:
        return Icons.school_rounded;
      case MilestoneCategory.marriage:
        return Icons.favorite_rounded;
      case MilestoneCategory.housing:
        return Icons.home_work_rounded;
      case MilestoneCategory.vehicle:
        return Icons.directions_car_rounded;
      case MilestoneCategory.travel:
        return Icons.flight_takeoff_rounded;
      case MilestoneCategory.health:
        return Icons.health_and_safety_rounded;
      case MilestoneCategory.other:
        return Icons.stars_rounded;
    }
  }

  void _showAddEditGoalDialog(BuildContext context, [MilestoneExpenseGoal? existing]) {
    final nameController = TextEditingController(
      text: existing?.name ?? "Child's Higher Education",
    );
    final amountController = TextEditingController(
      text: existing != null
          ? existing.targetAmount.toStringAsFixed(0)
          : '3000000',
    );
    final notesController = TextEditingController(
      text: existing?.notes ?? '',
    );

    MilestoneCategory selectedCategory = existing?.category ?? MilestoneCategory.education;
    DateTime selectedEndDate = existing?.endDate ??
        DateTime.now().add(const Duration(days: 365 * 5));

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final now = DateTime.now();
            final monthsRemaining = max(
                0,
                (selectedEndDate.year - now.year) * 12 +
                    (selectedEndDate.month - now.month));
            final yearsRemaining = max(
                0.0, selectedEndDate.difference(now).inDays / 365.25);

            // Compute estimated monthly SIP required at return rate
            final returnRate = widget.controller.inputs.expectedMFReturn > 0
                ? widget.controller.inputs.expectedMFReturn
                : 0.12;
            final currentAmount = double.tryParse(amountController.text
                    .replaceAll(RegExp(r'[^0-9.]'), '')) ??
                0.0;
            double estimatedSip = 0.0;
            if (monthsRemaining > 0 && currentAmount > 0) {
              final r = returnRate / 12.0;
              final factor = ((pow(1.0 + r, monthsRemaining) - 1.0) / r) * (1.0 + r);
              estimatedSip = factor > 0 ? (currentAmount / factor) : (currentAmount / monthsRemaining);
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(selectedCategory).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(selectedCategory),
                      color: _getCategoryColor(selectedCategory),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      existing == null
                          ? 'Add Milestone Expense Goal'
                          : 'Edit Milestone Expense Goal',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 500,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Large lump-sum expenses (child education, marriage, property, etc.) to fund alongside retirement.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 14),

                      // Quick Preset Category Chips
                      const Text(
                        'Category Presets:',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildPresetChip(
                              label: '🎓 Education',
                              category: MilestoneCategory.education,
                              selected: selectedCategory == MilestoneCategory.education,
                              onTap: () {
                                setDialogState(() {
                                  selectedCategory = MilestoneCategory.education;
                                  if (existing == null) {
                                    nameController.text = selectedCategory.defaultTitle;
                                    amountController.text =
                                        selectedCategory.defaultAmount.toStringAsFixed(0);
                                    selectedEndDate =
                                        DateTime.now().add(const Duration(days: 365 * 5));
                                  }
                                });
                              },
                            ),
                            _buildPresetChip(
                              label: '💍 Marriage',
                              category: MilestoneCategory.marriage,
                              selected: selectedCategory == MilestoneCategory.marriage,
                              onTap: () {
                                setDialogState(() {
                                  selectedCategory = MilestoneCategory.marriage;
                                  if (existing == null) {
                                    nameController.text = selectedCategory.defaultTitle;
                                    amountController.text =
                                        selectedCategory.defaultAmount.toStringAsFixed(0);
                                    selectedEndDate =
                                        DateTime.now().add(const Duration(days: 365 * 10));
                                  }
                                });
                              },
                            ),
                            _buildPresetChip(
                              label: '🏡 Housing',
                              category: MilestoneCategory.housing,
                              selected: selectedCategory == MilestoneCategory.housing,
                              onTap: () {
                                setDialogState(() {
                                  selectedCategory = MilestoneCategory.housing;
                                  if (existing == null) {
                                    nameController.text = selectedCategory.defaultTitle;
                                    amountController.text =
                                        selectedCategory.defaultAmount.toStringAsFixed(0);
                                    selectedEndDate =
                                        DateTime.now().add(const Duration(days: 365 * 3));
                                  }
                                });
                              },
                            ),
                            _buildPresetChip(
                              label: '🚗 Vehicle',
                              category: MilestoneCategory.vehicle,
                              selected: selectedCategory == MilestoneCategory.vehicle,
                              onTap: () {
                                setDialogState(() {
                                  selectedCategory = MilestoneCategory.vehicle;
                                  if (existing == null) {
                                    nameController.text = selectedCategory.defaultTitle;
                                    amountController.text =
                                        selectedCategory.defaultAmount.toStringAsFixed(0);
                                    selectedEndDate =
                                        DateTime.now().add(const Duration(days: 365 * 4));
                                  }
                                });
                              },
                            ),
                            _buildPresetChip(
                              label: '✈️ Travel',
                              category: MilestoneCategory.travel,
                              selected: selectedCategory == MilestoneCategory.travel,
                              onTap: () {
                                setDialogState(() {
                                  selectedCategory = MilestoneCategory.travel;
                                  if (existing == null) {
                                    nameController.text = selectedCategory.defaultTitle;
                                    amountController.text =
                                        selectedCategory.defaultAmount.toStringAsFixed(0);
                                    selectedEndDate =
                                        DateTime.now().add(const Duration(days: 365 * 2));
                                  }
                                });
                              },
                            ),
                            _buildPresetChip(
                              label: '🏥 Health',
                              category: MilestoneCategory.health,
                              selected: selectedCategory == MilestoneCategory.health,
                              onTap: () {
                                setDialogState(() {
                                  selectedCategory = MilestoneCategory.health;
                                  if (existing == null) {
                                    nameController.text = selectedCategory.defaultTitle;
                                    amountController.text =
                                        selectedCategory.defaultAmount.toStringAsFixed(0);
                                    selectedEndDate =
                                        DateTime.now().add(const Duration(days: 365 * 4));
                                  }
                                });
                              },
                            ),
                            _buildPresetChip(
                              label: '🎯 Custom',
                              category: MilestoneCategory.other,
                              selected: selectedCategory == MilestoneCategory.other,
                              onTap: () {
                                setDialogState(() {
                                  selectedCategory = MilestoneCategory.other;
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Goal Name Input
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Goal Title / Description',
                          hintText: "e.g. Daughter's Medical College, Son's Wedding",
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Target Amount Input
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Target Amount (₹)',
                          hintText: 'e.g. 3000000 for ₹30 Lakhs',
                          border: OutlineInputBorder(),
                          isDense: true,
                          prefixText: '₹ ',
                        ),
                        onChanged: (_) => setDialogState(() {}),
                      ),

                      const SizedBox(height: 8),

                      // Quick Amount Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            1000000.0,
                            1500000.0,
                            2000000.0,
                            2500000.0,
                            3000000.0,
                            3500000.0,
                            5000000.0,
                            10000000.0
                          ].map((amt) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: ActionChip(
                                label: Text(
                                  amt >= 10000000
                                      ? '₹${(amt / 10000000).toStringAsFixed(1)} Cr'
                                      : '₹${(amt / 100000).toStringAsFixed(0)} L',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                                ),
                                visualDensity: VisualDensity.compact,
                                onPressed: () {
                                  setDialogState(() {
                                    amountController.text = amt.toStringAsFixed(0);
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Target End Date Picker
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                alignment: Alignment.centerLeft,
                              ),
                              icon: const Icon(Icons.calendar_month_rounded, size: 18),
                              label: Text(
                                'End Date: ${_formatDate(selectedEndDate)}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedEndDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365 * 40)),
                                );
                                if (picked != null) {
                                  setDialogState(() {
                                    selectedEndDate = picked;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              monthsRemaining > 0
                                  ? '${yearsRemaining.toStringAsFixed(1)} Yrs ($monthsRemaining Mo)'
                                  : 'Due Now',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Quick Horizon Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [1, 2, 3, 5, 7, 10, 15, 20].map((yrs) {
                            final target = DateTime(now.year + yrs, now.month, now.day);
                            final isSel = (selectedEndDate.year - now.year) == yrs &&
                                selectedEndDate.month == now.month;
                            return Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: ChoiceChip(
                                label: Text(
                                  '$yrs Yrs',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                                ),
                                selected: isSel,
                                visualDensity: VisualDensity.compact,
                                onSelected: (_) {
                                  setDialogState(() {
                                    selectedEndDate = target;
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Notes Input (Optional)
                      TextField(
                        controller: notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes / Assumptions (Optional)',
                          hintText: 'e.g. Sinking fund in equity index + debt funds',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Estimated Monthly SIP Calculation Box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6).withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.calculate_rounded,
                                  color: Color(0xFF1D4ED8), size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Required Sinking Fund Monthly SIP (@ ${(returnRate * 100).toStringAsFixed(1)}% p.a.):',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E40AF),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    estimatedSip > 0
                                        ? '₹${CurrencyFormatter.formatINR(estimatedSip)} / month'
                                        : 'Enter amount and date to compute',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1E3A8A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.check, size: 16),
                  label: Text(existing == null ? 'Add Goal' : 'Save Goal'),
                  onPressed: () {
                    final targetAmt = double.tryParse(amountController.text
                            .replaceAll(RegExp(r'[^0-9.]'), '')) ??
                        0.0;
                    if (targetAmt <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid target amount')),
                      );
                      return;
                    }

                    final goal = MilestoneExpenseGoal(
                      id: existing?.id ?? 'goal_${DateTime.now().millisecondsSinceEpoch}',
                      name: nameController.text.trim().isEmpty
                          ? selectedCategory.defaultTitle
                          : nameController.text.trim(),
                      category: selectedCategory,
                      targetAmount: targetAmt,
                      endDate: selectedEndDate,
                      notes: notesController.text.trim().isEmpty
                          ? null
                          : notesController.text.trim(),
                    );

                    if (existing == null) {
                      widget.controller.addMilestoneGoal(goal);
                    } else {
                      widget.controller.updateMilestoneGoal(goal);
                    }

                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          existing == null
                              ? 'Added milestone goal: ${goal.name}'
                              : 'Updated milestone goal: ${goal.name}',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPresetChip({
    required String label,
    required MilestoneCategory category,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        selected: selected,
        onSelected: (_) => onTap(),
        visualDensity: VisualDensity.compact,
        selectedColor: _getCategoryColor(category).withOpacity(0.18),
        checkmarkColor: _getCategoryColor(category),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final summary = widget.controller.dashboardSummary;
        final goals = widget.controller.milestoneGoals;
        final totalMilestones = summary.totalMilestoneExpenses;
        final monthlySipNeeded = summary.milestoneMonthlySipNeeded;
        final targetRetirementYears = summary.targetYears;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Major Milestones & Life Events',
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
                        horizontal: isMobile ? 12 : 24,
                        vertical: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Info Banner
                          _buildInfoBanner(isMobile),
                          const SizedBox(height: 16),

                          // 2. Metrics Strip Cards
                          _buildMetricsGrid(summary, isMobile),
                          const SizedBox(height: 20),

                          if (isDesktop)
                            // Desktop 2-Pane Layout
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left 40%: Quick Actions, Presets & SIP Guidance
                                Expanded(
                                  flex: 40,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      _buildAddGoalCard(),
                                      const SizedBox(height: 16),
                                      _buildPresetsCard(),
                                      const SizedBox(height: 16),
                                      _buildSinkingFundGuidanceCard(),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 20),

                                // Right 60%: Active Goals List & Visual Category Distribution
                                Expanded(
                                  flex: 60,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      _buildGoalsListCard(goals, summary, targetRetirementYears, isMobile: false),
                                      if (goals.isNotEmpty) ...[
                                        const SizedBox(height: 16),
                                        _buildCategoryDistributionCard(goals, totalMilestones),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            )
                          else
                            // Mobile / Tablet Stacked Layout
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildAddGoalCard(),
                                const SizedBox(height: 16),
                                _buildGoalsListCard(goals, summary, targetRetirementYears, isMobile: true),
                                const SizedBox(height: 16),
                                _buildPresetsCard(),
                                const SizedBox(height: 16),
                                if (goals.isNotEmpty) ...[
                                  _buildCategoryDistributionCard(goals, totalMilestones),
                                  const SizedBox(height: 16),
                                ],
                                _buildSinkingFundGuidanceCard(),
                              ],
                            ),

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

  Widget _buildInfoBanner(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF2F8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFBCFE8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFDB2777).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.celebration_rounded, color: Color(0xFFDB2777), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LIFE EVENTS & MAJOR CAPITAL OUTLAYS',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF9D174D),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Large lump-sum events (child education, marriage, home renovation, or property purchase) should not be funded by cannibalizing your core retirement corpus. Configure your goals here to automatically calculate required sinking-fund monthly SIPs and see your adjusted 30x FIRE readiness target.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: const Color(0xFF831843).withOpacity(0.9),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(ComprehensiveFireSummary summary, bool isMobile) {
    final double totalMilestones = summary.totalMilestoneExpenses;
    final int count = summary.milestoneGoalsCount;
    final double monthlySip = summary.milestoneMonthlySipNeeded;
    final double preRet = summary.preRetirementMilestones;
    final double postRet = summary.postRetirementMilestones;

    final items = [
      _buildMetricCard(
        title: 'Total Capital Outlay',
        primary: CurrencyFormatter.formatCrores(totalMilestones / 10000000.0),
        subtitle: CurrencyFormatter.formatINR(totalMilestones),
        note: 'Across all $count goals',
        accentColor: const Color(0xFFDB2777),
        icon: Icons.account_balance_wallet_rounded,
      ),
      _buildMetricCard(
        title: 'Active Life Goals',
        primary: '$count Goals',
        subtitle: count > 0 ? '${CurrencyFormatter.formatCompactINR(preRet)} Pre-Ret' : 'None active',
        note: count > 0 ? '${CurrencyFormatter.formatCompactINR(postRet)} Post-Ret' : 'Add goals below',
        accentColor: AppTheme.primaryNavy,
        icon: Icons.flag_rounded,
      ),
      _buildMetricCard(
        title: 'Monthly Sinking Fund SIP',
        primary: CurrencyFormatter.formatCompactINR(monthlySip),
        subtitle: monthlySip > 0 ? '₹${CurrencyFormatter.formatINR(monthlySip)} / mo' : '₹0 / mo',
        note: 'Compounded until target end date',
        accentColor: const Color(0xFF059669),
        icon: Icons.trending_up_rounded,
      ),
      _buildMetricCard(
        title: 'Impact on 30x FIRE Target',
        primary: '+${CurrencyFormatter.formatCompactINR(totalMilestones)}',
        subtitle: 'Target: ${CurrencyFormatter.formatCrores(summary.adjustedFire30x / 10000000.0)}',
        note: 'Corpus fully covers lifestyle + goals',
        accentColor: const Color(0xFF7C3AED),
        icon: Icons.shield_rounded,
      ),
    ];

    if (isMobile) {
      return Column(
        children: items.map((card) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: card,
        )).toList(),
      );
    }

    return Row(
      children: items.map((card) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: card,
        ),
      )).toList(),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String primary,
    required String subtitle,
    required String note,
    required Color accentColor,
    required IconData icon,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: accentColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                primary,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: accentColor,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
            ),
            Text(
              note,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 9.5, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddGoalCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDB2777).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add_task_rounded, color: Color(0xFFDB2777), size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NEW MILESTONE GOAL',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                          color: AppTheme.primaryNavy,
                        ),
                      ),
                      Text(
                        'Define a new capital commitment',
                        style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDB2777),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'Add Custom Milestone Goal',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
              onPressed: () => _showAddEditGoalDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetsCard() {
    final presets = [
      {
        'title': '🎓 Child Higher Education',
        'category': MilestoneCategory.education,
        'amount': 3000000.0,
        'years': 5,
        'desc': '4-Year Undergraduate Degree',
      },
      {
        'title': "💍 Child's Marriage",
        'category': MilestoneCategory.marriage,
        'amount': 3500000.0,
        'years': 10,
        'desc': 'Wedding ceremony & family gold',
      },
      {
        'title': '🏡 Home Renovation',
        'category': MilestoneCategory.housing,
        'amount': 1500000.0,
        'years': 3,
        'desc': 'Interiors, modular kitchen & repair',
      },
      {
        'title': '🚗 New Car / EV Upgrade',
        'category': MilestoneCategory.vehicle,
        'amount': 1500000.0,
        'years': 4,
        'desc': 'Family SUV / Electric Vehicle',
      },
      {
        'title': '✈️ Dream Vacation Tour',
        'category': MilestoneCategory.travel,
        'amount': 800000.0,
        'years': 2,
        'desc': 'International family travel',
      },
      {
        'title': '🏥 Family Health Reserve',
        'category': MilestoneCategory.health,
        'amount': 1000000.0,
        'years': 3,
        'desc': 'Critical illness / emergency buffer',
      },
    ];

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bolt_rounded, color: Color(0xFFD97706), size: 18),
                SizedBox(width: 8),
                Text(
                  '1-CLICK PRESET GOALS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: AppTheme.primaryNavy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Instantly add realistic benchmark milestones with standard amounts and timelines:',
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 12),
            ...presets.map((preset) {
              final cat = preset['category'] as MilestoneCategory;
              final amt = preset['amount'] as double;
              final yrs = preset['years'] as int;
              final title = preset['title'] as String;
              final desc = preset['desc'] as String;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${CurrencyFormatter.formatCompactINR(amt)} • in $yrs Yrs • $desc',
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFFDB2777), size: 20),
                      tooltip: 'Add this preset',
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        widget.controller.addMilestoneGoal(
                          MilestoneExpenseGoal(
                            id: 'preset_${DateTime.now().millisecondsSinceEpoch}',
                            name: title.replaceAll(RegExp(r'[^\w\s\-]'), '').trim(),
                            category: cat,
                            targetAmount: amt,
                            endDate: DateTime.now().add(Duration(days: 365 * yrs)),
                            notes: desc,
                          ),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added preset goal: $title'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSinkingFundGuidanceCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, size: 18, color: Color(0xFF2563EB)),
              SizedBox(width: 8),
              Text(
                'How Sinking Fund SIP Works',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E40AF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Rather than scrambling for capital or liquidating long-term retirement assets when milestones arrive, a Sinking Fund accumulates the exact amount through periodic monthly contributions growing at your expected equity/debt return.',
            style: TextStyle(fontSize: 11, color: Color(0xFF1E3A8A), height: 1.35),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF93C5FD)),
            ),
            child: const Text(
              'Formula: SIP = [Target × r] / [(1+r)ⁿ - 1] × 1/(1+r)',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E3A8A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsListCard(
    List<MilestoneExpenseGoal> goals,
    ComprehensiveFireSummary summary,
    double targetRetirementYears, {
    required bool isMobile,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDB2777).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.format_list_bulleted_rounded,
                            color: Color(0xFFDB2777), size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'YOUR ACTIVE MILESTONE GOALS',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                                color: AppTheme.primaryNavy,
                              ),
                            ),
                            Text(
                              goals.isNotEmpty
                                  ? '${goals.length} configured milestone obligations'
                                  : 'No goals added yet',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (goals.isNotEmpty)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.clear_all_rounded, size: 16),
                    label: const Text('Clear All', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Clear All Milestone Goals?'),
                          content: const Text('This will remove all configured life milestone goals.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                            FilledButton(
                              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                              onPressed: () {
                                Navigator.pop(ctx);
                                widget.controller.resetMilestoneGoals();
                              },
                              child: const Text('Clear All'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 14),

            if (goals.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF5FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE9D5FF)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.stars_rounded, size: 40, color: Color(0xFF9333EA)),
                    const SizedBox(height: 10),
                    const Text(
                      'No Milestone Goals Added',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF6B21A8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Click "+ Add Custom Milestone Goal" or use the 1-Click Presets on the left to start modeling large future life expenses.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF7E22CE)),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.school_rounded, size: 14, color: Color(0xFF2563EB)),
                          label: const Text('🎓 Child Education (₹30L)', style: TextStyle(fontSize: 11)),
                          onPressed: () {
                            widget.controller.addMilestoneGoal(
                              MilestoneExpenseGoal(
                                id: 'goal_edu_${DateTime.now().millisecondsSinceEpoch}',
                                name: "Child's Higher Education",
                                category: MilestoneCategory.education,
                                targetAmount: 3000000.0,
                                endDate: DateTime.now().add(const Duration(days: 365 * 5)),
                              ),
                            );
                          },
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.favorite_rounded, size: 14, color: Color(0xFFDB2777)),
                          label: const Text("💍 Child's Marriage (₹35L)", style: TextStyle(fontSize: 11)),
                          onPressed: () {
                            widget.controller.addMilestoneGoal(
                              MilestoneExpenseGoal(
                                id: 'goal_mar_${DateTime.now().millisecondsSinceEpoch}',
                                name: "Child's Marriage",
                                category: MilestoneCategory.marriage,
                                targetAmount: 3500000.0,
                                endDate: DateTime.now().add(const Duration(days: 365 * 10)),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              Column(
                children: goals.map((goal) {
                  final catColor = _getCategoryColor(goal.category);
                  final catIcon = _getCategoryIcon(goal.category);
                  final isPreRetirement = goal.yearsRemaining <= targetRetirementYears;
                  final monthlySip = goal.requiredMonthlySip(
                    widget.controller.inputs.expectedMFReturn > 0
                        ? widget.controller.inputs.expectedMFReturn
                        : 0.12,
                  );

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Icon
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: catColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(catIcon, color: catColor, size: 22),
                        ),
                        const SizedBox(width: 12),

                        // Title, Timing & Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      goal.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.primaryNavy,
                                      ),
                                    ),
                                  ),
                                  // Timing Badge (Pre vs Post Retirement)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isPreRetirement
                                          ? const Color(0xFFECFDF5)
                                          : const Color(0xFFFFFBEB),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isPreRetirement
                                            ? const Color(0xFFA7F3D0)
                                            : const Color(0xFFFDE68A),
                                      ),
                                    ),
                                    child: Text(
                                      isPreRetirement ? 'Pre-Retirement' : 'Post-Retirement',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: isPreRetirement
                                            ? const Color(0xFF065F46)
                                            : const Color(0xFF92400E),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    CurrencyFormatter.formatINR(goal.targetAmount),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: const BoxDecoration(
                                      color: Colors.grey,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Target: ${goal.formattedEndDate} (${goal.durationFormatted})',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFECFDF5),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFA7F3D0)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.savings_outlined, size: 12, color: Color(0xFF047857)),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Recommended SIP: ₹${CurrencyFormatter.formatINR(monthlySip)}/mo',
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF047857),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (goal.notes != null && goal.notes!.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        '• ${goal.notes!}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Action Buttons: Edit & Delete
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              tooltip: 'Edit Goal',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => _showAddEditGoalDialog(context, goal),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  size: 18, color: Colors.redAccent),
                              tooltip: 'Delete Goal',
                              visualDensity: VisualDensity.compact,
                              onPressed: () {
                                widget.controller.removeMilestoneGoal(goal.id);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDistributionCard(
    List<MilestoneExpenseGoal> goals,
    double totalMilestones,
  ) {
    if (totalMilestones <= 0) return const SizedBox.shrink();

    // Group amounts by category
    final Map<MilestoneCategory, double> categorySums = {};
    for (final g in goals) {
      categorySums[g.category] = (categorySums[g.category] ?? 0.0) + g.targetAmount;
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.pie_chart_outline_rounded, color: AppTheme.primaryNavy, size: 18),
                SizedBox(width: 8),
                Text(
                  'CAPITAL ALLOCATION BY CATEGORY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: AppTheme.primaryNavy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...categorySums.entries.map((entry) {
              final cat = entry.key;
              final amt = entry.value;
              final pct = (amt / totalMilestones) * 100.0;
              final color = _getCategoryColor(cat);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              cat.displayName,
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        Text(
                          '${CurrencyFormatter.formatCompactINR(amt)} (${pct.toStringAsFixed(1)}%)',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (pct / 100.0).clamp(0.0, 1.0),
                        backgroundColor: color.withOpacity(0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

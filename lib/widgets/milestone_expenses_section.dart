import 'dart:math';
import 'package:flutter/material.dart';
import '../controllers/fire_calculator_controller.dart';
import '../models/dashboard_models.dart';
import '../models/milestone_expense_models.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';

class MilestoneExpensesSection extends StatelessWidget {
  final FireCalculatorController controller;
  final ComprehensiveFireSummary summary;
  final bool isMobile;
  final VoidCallback? onManageInTab;

  const MilestoneExpensesSection({
    super.key,
    required this.controller,
    required this.summary,
    this.isMobile = false,
    this.onManageInTab,
  });

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

            // Compute estimated monthly SIP required at 12% return
            final currentAmount = double.tryParse(amountController.text
                    .replaceAll(RegExp(r'[^0-9.]'), '')) ??
                0.0;
            double estimatedSip = 0.0;
            if (monthsRemaining > 0 && currentAmount > 0) {
              const r = 0.12 / 12.0;
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
                  width: 480,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Large lump-sum expenses (education, marriage, property, etc.) to fund alongside retirement.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 12),

                      // Quick Preset Category Chips
                      const Text(
                        'Category Quick Presets:',
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
                        decoration: InputDecoration(
                          labelText: 'Goal Name / Description',
                          hintText: 'e.g. Ananya’s College Education',
                          border: const OutlineInputBorder(),
                          isDense: true,
                          prefixIcon: Icon(
                            _getCategoryIcon(selectedCategory),
                            color: _getCategoryColor(selectedCategory),
                            size: 20,
                          ),
                        ),
                        onChanged: (_) => setDialogState(() {}),
                      ),

                      const SizedBox(height: 12),

                      // Target Amount Input
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Target Amount (₹)',
                          hintText: 'e.g. 3000000 for 30 Lakhs',
                          border: const OutlineInputBorder(),
                          isDense: true,
                          prefixText: '₹ ',
                          suffixText: currentAmount > 0
                              ? CurrencyFormatter.formatCompactINR(currentAmount)
                              : null,
                        ),
                        onChanged: (_) => setDialogState(() {}),
                      ),
                      const SizedBox(height: 6),

                      // Quick Amount Chips
                      Wrap(
                        spacing: 6,
                        children: [1000000, 2000000, 3000000, 4000000, 5000000, 10000000]
                            .map((amt) {
                          return ActionChip(
                            visualDensity: VisualDensity.compact,
                            label: Text(
                              CurrencyFormatter.formatCompactINR(amt.toDouble()),
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                            onPressed: () {
                              setDialogState(() {
                                amountController.text = amt.toString();
                              });
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 14),

                      // Target End Date Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Target End Date of Goal:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryNavy.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${yearsRemaining.toStringAsFixed(1)} Yrs ($monthsRemaining Mo)',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryNavy,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // End Date Picker Button
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedEndDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 35)),
                            helpText: 'Select Target End Date of Goal',
                          );
                          if (picked != null) {
                            setDialogState(() {
                              selectedEndDate = picked;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded,
                                      size: 18, color: AppTheme.primaryNavy),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatDate(selectedEndDate),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primaryNavy,
                                    ),
                                  ),
                                ],
                              ),
                              const Text(
                                'Change Date',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.primaryNavy,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

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
                                  const Text(
                                    'Estimated Monthly SIP Needed:',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E40AF),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    estimatedSip > 0
                                        ? '₹${CurrencyFormatter.formatINR(estimatedSip)} / month (@ 12% p.a.)'
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
                      controller.addMilestoneGoal(goal);
                    } else {
                      controller.updateMilestoneGoal(goal);
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
    final goals = controller.milestoneGoals;
    final totalMilestones = summary.totalMilestoneExpenses;
    final monthlySipNeeded = summary.milestoneMonthlySipNeeded;
    final targetRetirementYears = summary.targetYears;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Title + Add Goal Button
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
                        child: const Icon(Icons.celebration_rounded,
                            color: Color(0xFFDB2777), size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'MAJOR MILESTONE EXPENSES & LIFE GOALS',
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
                              'Child education, marriage & lump-sum capital outflows',
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
                const SizedBox(width: 8),
                if (onManageInTab != null) ...[
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: const Color(0xFFDB2777),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    icon: const Icon(Icons.open_in_new_rounded, size: 14),
                    label: const Text(
                      'Open Tab',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                    onPressed: onManageInTab,
                  ),
                  const SizedBox(width: 4),
                ],
                TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: const Color(0xFFFDF2F8),
                    foregroundColor: const Color(0xFFDB2777),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text(
                    'Add Goal',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () => _showAddEditGoalDialog(context),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Metrics Summary Strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildMetricCol(
                      label: 'Total Milestone Goals',
                      value: CurrencyFormatter.formatCrores(totalMilestones / 10000000.0),
                      subValue: CurrencyFormatter.formatINR(totalMilestones),
                      valueColor: const Color(0xFFBE185D),
                    ),
                  ),
                  Container(width: 1, height: 32, color: Colors.grey.shade300),
                  Expanded(
                    child: _buildMetricCol(
                      label: 'Active Goals',
                      value: '${goals.length} Goals',
                      subValue: goals.isNotEmpty
                          ? '${goals.where((g) => g.yearsRemaining <= targetRetirementYears).length} Pre-Ret • ${goals.where((g) => g.yearsRemaining > targetRetirementYears).length} Post-Ret'
                          : 'None added',
                      valueColor: AppTheme.primaryNavy,
                    ),
                  ),
                  Container(width: 1, height: 32, color: Colors.grey.shade300),
                  Expanded(
                    child: _buildMetricCol(
                      label: 'Monthly SIP Needed',
                      value: CurrencyFormatter.formatCompactINR(monthlySipNeeded),
                      subValue: monthlySipNeeded > 0 ? 'Across all active goals' : '₹0 / mo',
                      valueColor: const Color(0xFF047857),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // When no goals are configured yet: Friendly Empty State with 1-Click Quick Add
            if (goals.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF5FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE9D5FF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 16, color: Color(0xFF7C3AED)),
                        SizedBox(width: 6),
                        Text(
                          'Planning for major life milestones?',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6B21A8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Adding goals here automatically increases your comprehensive 30x FIRE target so your retirement corpus fully covers both day-to-day living and large future capital obligations.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF7E22CE), height: 1.3),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Quick Add Presets:',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF6B21A8)),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.school_rounded, size: 14, color: Color(0xFF2563EB)),
                          label: const Text('🎓 Child Education (₹30L)', style: TextStyle(fontSize: 11)),
                          onPressed: () {
                            controller.addMilestoneGoal(
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
                            controller.addMilestoneGoal(
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
                        ActionChip(
                          avatar: const Icon(Icons.home_work_rounded, size: 14, color: Color(0xFFD97706)),
                          label: const Text('🏡 Home Renovation (₹15L)', style: TextStyle(fontSize: 11)),
                          onPressed: () {
                            controller.addMilestoneGoal(
                              MilestoneExpenseGoal(
                                id: 'goal_house_${DateTime.now().millisecondsSinceEpoch}',
                                name: 'Home Renovation / Upgrades',
                                category: MilestoneCategory.housing,
                                targetAmount: 1500000.0,
                                endDate: DateTime.now().add(const Duration(days: 365 * 3)),
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
              // List of configured milestone goals
              Column(
                children: goals.map((goal) {
                  final catColor = _getCategoryColor(goal.category);
                  final catIcon = _getCategoryIcon(goal.category);
                  final isPreRetirement = goal.yearsRemaining <= targetRetirementYears;
                  final monthlySip = goal.requiredMonthlySip(
                    controller.inputs.expectedMFReturn > 0
                        ? controller.inputs.expectedMFReturn
                        : 0.12,
                  );

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
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
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: catColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(catIcon, color: catColor, size: 20),
                        ),
                        const SizedBox(width: 10),

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
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.primaryNavy,
                                      ),
                                    ),
                                  ),
                                  // Timing Badge (Pre vs Post Retirement)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isPreRetirement
                                          ? const Color(0xFFECFDF5)
                                          : const Color(0xFFFFFBEB),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: isPreRetirement
                                            ? const Color(0xFFA7F3D0)
                                            : const Color(0xFFFDE68A),
                                      ),
                                    ),
                                    child: Text(
                                      isPreRetirement ? 'Pre-Retirement' : 'Post-Retirement',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: isPreRetirement
                                            ? const Color(0xFF065F46)
                                            : const Color(0xFF92400E),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    CurrencyFormatter.formatINR(goal.targetAmount),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 3,
                                    height: 3,
                                    decoration: const BoxDecoration(
                                      color: Colors.grey,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'End Date: ${goal.formattedEndDate} (${goal.durationFormatted})',
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
                              const SizedBox(height: 4),
                              Text(
                                'Recommended SIP: ₹${CurrencyFormatter.formatCompactINR(monthlySip)}/mo',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF047857),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Action Buttons: Edit & Delete
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              tooltip: 'Edit Goal',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => _showAddEditGoalDialog(context, goal),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  size: 16, color: Colors.redAccent),
                              tooltip: 'Delete Goal',
                              visualDensity: VisualDensity.compact,
                              onPressed: () {
                                controller.removeMilestoneGoal(goal.id);
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

  Widget _buildMetricCol({
    required String label,
    required String value,
    required String subValue,
    required Color valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
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
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: valueColor,
            ),
          ),
        ),
        Text(
          subValue,
          style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

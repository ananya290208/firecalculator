import 'dart:math';

/// Category of major milestone capital expenses
enum MilestoneCategory {
  education,
  marriage,
  housing,
  vehicle,
  travel,
  health,
  other,
}

extension MilestoneCategoryExt on MilestoneCategory {
  String get displayName {
    switch (this) {
      case MilestoneCategory.education:
        return 'Child Education';
      case MilestoneCategory.marriage:
        return 'Child Marriage';
      case MilestoneCategory.housing:
        return 'Home Renovation / Purchase';
      case MilestoneCategory.vehicle:
        return 'Vehicle Upgrade';
      case MilestoneCategory.travel:
        return 'Vacation / Travel';
      case MilestoneCategory.health:
        return 'Medical / Family Reserve';
      case MilestoneCategory.other:
        return 'Other Major Expense';
    }
  }

  String get defaultTitle {
    switch (this) {
      case MilestoneCategory.education:
        return "Child's Higher Education";
      case MilestoneCategory.marriage:
        return "Child's Marriage";
      case MilestoneCategory.housing:
        return 'Home Renovation / Downpayment';
      case MilestoneCategory.vehicle:
        return 'New Vehicle Purchase';
      case MilestoneCategory.travel:
        return 'Dream Vacation / World Tour';
      case MilestoneCategory.health:
        return 'Family Healthcare Reserve';
      case MilestoneCategory.other:
        return 'Major Capital Expense';
    }
  }

  double get defaultAmount {
    switch (this) {
      case MilestoneCategory.education:
        return 3000000.0; // 30 Lakhs
      case MilestoneCategory.marriage:
        return 3500000.0; // 35 Lakhs
      case MilestoneCategory.housing:
        return 1500000.0; // 15 Lakhs
      case MilestoneCategory.vehicle:
        return 1500000.0; // 15 Lakhs
      case MilestoneCategory.travel:
        return 800000.0; // 8 Lakhs
      case MilestoneCategory.health:
        return 1000000.0; // 10 Lakhs
      case MilestoneCategory.other:
        return 2000000.0; // 20 Lakhs
    }
  }
}

/// Represents a large milestone capital expense goal
/// (e.g. child's education, child's marriage, home upgrade, etc.)
class MilestoneExpenseGoal {
  final String id;
  final String name;
  final MilestoneCategory category;
  final double targetAmount;
  final DateTime endDate;
  final String? notes;

  const MilestoneExpenseGoal({
    required this.id,
    required this.name,
    this.category = MilestoneCategory.other,
    required this.targetAmount,
    required this.endDate,
    this.notes,
  });

  /// Years remaining until the goal's target date
  double get yearsRemaining {
    final now = DateTime.now();
    final diffDays = endDate.difference(now).inDays;
    return max(0.0, diffDays / 365.25);
  }

  /// Months remaining until the goal's target date
  int get monthsRemaining {
    final now = DateTime.now();
    final months = (endDate.year - now.year) * 12 + (endDate.month - now.month);
    return max(0, months);
  }

  /// Formatted duration: e.g. "4 Yrs 6 Mo" or "8 Months"
  String get durationFormatted {
    final months = monthsRemaining;
    if (months == 0) return 'Due Now';
    final yrs = months ~/ 12;
    final rem = months % 12;
    if (yrs == 0) return '$rem ${rem == 1 ? "Month" : "Months"}';
    if (rem == 0) return '$yrs ${yrs == 1 ? "Year" : "Years"}';
    return '$yrs Yr $rem Mo';
  }

  /// Formatted date: e.g. "May 2031"
  String get formattedEndDate {
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
    return '${months[endDate.month - 1]} ${endDate.year}';
  }

  /// Monthly SIP needed to reach targetAmount by endDate assuming annual expected return
  double requiredMonthlySip(double annualReturn) {
    final months = monthsRemaining;
    if (months <= 0) return targetAmount;
    final r = annualReturn / 12.0;
    if (r <= 0) return targetAmount / months;
    // Annuity formula for SIP with end-of-month or beginning-of-month compounding
    final factor = ((pow(1.0 + r, months) - 1.0) / r) * (1.0 + r);
    if (factor <= 0) return targetAmount / months;
    return targetAmount / factor;
  }

  MilestoneExpenseGoal copyWith({
    String? id,
    String? name,
    MilestoneCategory? category,
    double? targetAmount,
    DateTime? endDate,
    String? notes,
  }) {
    return MilestoneExpenseGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      targetAmount: targetAmount ?? this.targetAmount,
      endDate: endDate ?? this.endDate,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'category': category.name,
        'targetAmount': targetAmount,
        'endDate': endDate.toIso8601String(),
        'notes': notes,
      };

  factory MilestoneExpenseGoal.fromMap(Map<String, dynamic> map) {
    return MilestoneExpenseGoal(
      id: map['id'] as String? ?? 'goal_${DateTime.now().millisecondsSinceEpoch}',
      name: map['name'] as String? ?? 'Major Expense',
      category: MilestoneCategory.values.firstWhere(
        (c) => c.name == (map['category'] as String?),
        orElse: () => MilestoneCategory.other,
      ),
      targetAmount: (map['targetAmount'] as num?)?.toDouble() ?? 0.0,
      endDate: map['endDate'] != null
          ? DateTime.tryParse(map['endDate'] as String) ??
              DateTime.now().add(const Duration(days: 365 * 5))
          : DateTime.now().add(const Duration(days: 365 * 5)),
      notes: map['notes'] as String?,
    );
  }
}

/// Aggregated summary of all milestone expense goals
class MilestoneExpensesSummary {
  final List<MilestoneExpenseGoal> goals;
  final double totalTargetAmount;
  final double preRetirementAmount;
  final double postRetirementAmount;
  final double totalMonthlySipNeeded;
  final int count;

  const MilestoneExpensesSummary({
    this.goals = const [],
    this.totalTargetAmount = 0.0,
    this.preRetirementAmount = 0.0,
    this.postRetirementAmount = 0.0,
    this.totalMonthlySipNeeded = 0.0,
    this.count = 0,
  });

  factory MilestoneExpensesSummary.calculate({
    required List<MilestoneExpenseGoal> goals,
    required double retirementYears,
    double expectedReturnRate = 0.12,
  }) {
    double total = 0.0;
    double preRet = 0.0;
    double postRet = 0.0;
    double totalSip = 0.0;

    for (final g in goals) {
      total += g.targetAmount;
      if (g.yearsRemaining <= retirementYears) {
        preRet += g.targetAmount;
      } else {
        postRet += g.targetAmount;
      }
      totalSip += g.requiredMonthlySip(expectedReturnRate);
    }

    return MilestoneExpensesSummary(
      goals: goals,
      totalTargetAmount: total,
      preRetirementAmount: preRet,
      postRetirementAmount: postRet,
      totalMonthlySipNeeded: totalSip,
      count: goals.length,
    );
  }
}

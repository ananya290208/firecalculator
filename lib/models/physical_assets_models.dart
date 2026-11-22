import 'dart:math';

/// Represents a residential apartment / flat owned
class ApartmentProperty {
  final String id;
  final String name;
  final double marketValue;
  final bool hasMortgage;
  final double mortgageBalance;
  final double monthlyEmi;
  final int remainingEmiMonths;
  final double loanInterestRate; // e.g. 0.085 for 8.5%
  final double monthlyRentalIncome;
  final bool isSelfOccupied; // true = primary home (not sold for FIRE); false = investment
  final bool monetizeAtRetirement; // true = liquidate at retirement; false = hold for rental cashflow
  final double expectedAppreciationRate; // e.g. 0.05 for 5% p.a.

  const ApartmentProperty({
    required this.id,
    this.name = 'Apartment',
    this.marketValue = 0.0,
    this.hasMortgage = false,
    this.mortgageBalance = 0.0,
    this.monthlyEmi = 0.0,
    this.remainingEmiMonths = 0,
    this.loanInterestRate = 0.085,
    this.monthlyRentalIncome = 0.0,
    this.isSelfOccupied = false,
    this.monetizeAtRetirement = false,
    this.expectedAppreciationRate = 0.05,
  });

  /// Net equity = market value - outstanding mortgage balance
  double get netEquity => max(0.0, marketValue - (hasMortgage ? mortgageBalance : 0.0));

  /// Future value at retirement horizon (years)
  double projectedValueAt(double years) {
    if (marketValue <= 0) return 0.0;
    return marketValue * pow(1.0 + expectedAppreciationRate, years);
  }

  ApartmentProperty copyWith({
    String? id,
    String? name,
    double? marketValue,
    bool? hasMortgage,
    double? mortgageBalance,
    double? monthlyEmi,
    int? remainingEmiMonths,
    double? loanInterestRate,
    double? monthlyRentalIncome,
    bool? isSelfOccupied,
    bool? monetizeAtRetirement,
    double? expectedAppreciationRate,
  }) {
    return ApartmentProperty(
      id: id ?? this.id,
      name: name ?? this.name,
      marketValue: marketValue ?? this.marketValue,
      hasMortgage: hasMortgage ?? this.hasMortgage,
      mortgageBalance: mortgageBalance ?? this.mortgageBalance,
      monthlyEmi: monthlyEmi ?? this.monthlyEmi,
      remainingEmiMonths: remainingEmiMonths ?? this.remainingEmiMonths,
      loanInterestRate: loanInterestRate ?? this.loanInterestRate,
      monthlyRentalIncome: monthlyRentalIncome ?? this.monthlyRentalIncome,
      isSelfOccupied: isSelfOccupied ?? this.isSelfOccupied,
      monetizeAtRetirement: monetizeAtRetirement ?? this.monetizeAtRetirement,
      expectedAppreciationRate: expectedAppreciationRate ?? this.expectedAppreciationRate,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'marketValue': marketValue,
        'hasMortgage': hasMortgage,
        'mortgageBalance': mortgageBalance,
        'monthlyEmi': monthlyEmi,
        'remainingEmiMonths': remainingEmiMonths,
        'loanInterestRate': loanInterestRate,
        'monthlyRentalIncome': monthlyRentalIncome,
        'isSelfOccupied': isSelfOccupied,
        'monetizeAtRetirement': monetizeAtRetirement,
        'expectedAppreciationRate': expectedAppreciationRate,
      };

  factory ApartmentProperty.fromMap(Map<String, dynamic> map) {
    return ApartmentProperty(
      id: map['id'] as String? ?? 'apt_1',
      name: map['name'] as String? ?? 'Apartment',
      marketValue: (map['marketValue'] as num?)?.toDouble() ?? 0.0,
      hasMortgage: map['hasMortgage'] as bool? ?? false,
      mortgageBalance: (map['mortgageBalance'] as num?)?.toDouble() ?? 0.0,
      monthlyEmi: (map['monthlyEmi'] as num?)?.toDouble() ?? 0.0,
      remainingEmiMonths: (map['remainingEmiMonths'] as num?)?.toInt() ?? 0,
      loanInterestRate: (map['loanInterestRate'] as num?)?.toDouble() ?? 0.085,
      monthlyRentalIncome: (map['monthlyRentalIncome'] as num?)?.toDouble() ?? 0.0,
      isSelfOccupied: map['isSelfOccupied'] as bool? ?? false,
      monetizeAtRetirement: map['monetizeAtRetirement'] as bool? ?? false,
      expectedAppreciationRate: (map['expectedAppreciationRate'] as num?)?.toDouble() ?? 0.05,
    );
  }
}

/// Represents land / plot owned
class LandProperty {
  final String id;
  final String name;
  final double marketValue;
  final double monthlyRentalIncome;
  final double expectedAppreciationRate; // e.g. 0.06 for 6% p.a.
  final bool monetizeAtRetirement; // true = sell at retirement to fund FIRE

  const LandProperty({
    required this.id,
    this.name = 'Land Property',
    this.marketValue = 0.0,
    this.monthlyRentalIncome = 0.0,
    this.expectedAppreciationRate = 0.06,
    this.monetizeAtRetirement = false,
  });

  double projectedValueAt(double years) {
    if (marketValue <= 0) return 0.0;
    return marketValue * pow(1.0 + expectedAppreciationRate, years);
  }

  LandProperty copyWith({
    String? id,
    String? name,
    double? marketValue,
    double? monthlyRentalIncome,
    double? expectedAppreciationRate,
    bool? monetizeAtRetirement,
  }) {
    return LandProperty(
      id: id ?? this.id,
      name: name ?? this.name,
      marketValue: marketValue ?? this.marketValue,
      monthlyRentalIncome: monthlyRentalIncome ?? this.monthlyRentalIncome,
      expectedAppreciationRate: expectedAppreciationRate ?? this.expectedAppreciationRate,
      monetizeAtRetirement: monetizeAtRetirement ?? this.monetizeAtRetirement,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'marketValue': marketValue,
        'monthlyRentalIncome': monthlyRentalIncome,
        'expectedAppreciationRate': expectedAppreciationRate,
        'monetizeAtRetirement': monetizeAtRetirement,
      };

  factory LandProperty.fromMap(Map<String, dynamic> map) {
    return LandProperty(
      id: map['id'] as String? ?? 'land_1',
      name: map['name'] as String? ?? 'Land Property',
      marketValue: (map['marketValue'] as num?)?.toDouble() ?? 0.0,
      monthlyRentalIncome: (map['monthlyRentalIncome'] as num?)?.toDouble() ?? 0.0,
      expectedAppreciationRate: (map['expectedAppreciationRate'] as num?)?.toDouble() ?? 0.06,
      monetizeAtRetirement: map['monetizeAtRetirement'] as bool? ?? false,
    );
  }
}

/// Represents Gold holdings (Solid Bullion/SGB vs Ornaments)
class GoldAssets {
  final double solidGoldValue; // Bullion, SGB, Gold ETF, 24K coins (liquid investment)
  final double ornamentsGoldValue; // Physical jewellery (family/sentimental)
  final double expectedReturn; // e.g. 0.08 for 8% p.a.
  final bool includeSolidInFireCorpus; // default true (solid gold is an investable asset)
  final bool includeOrnamentsInFireCorpus; // default false (heritage/family jewellery kept)

  const GoldAssets({
    this.solidGoldValue = 0.0,
    this.ornamentsGoldValue = 0.0,
    this.expectedReturn = 0.08,
    this.includeSolidInFireCorpus = true,
    this.includeOrnamentsInFireCorpus = false,
  });

  double get totalGoldValue => solidGoldValue + ornamentsGoldValue;

  double projectedSolidGoldAt(double years) {
    if (solidGoldValue <= 0) return 0.0;
    return solidGoldValue * pow(1.0 + expectedReturn, years);
  }

  double projectedOrnamentsGoldAt(double years) {
    if (ornamentsGoldValue <= 0) return 0.0;
    return ornamentsGoldValue * pow(1.0 + expectedReturn, years);
  }

  GoldAssets copyWith({
    double? solidGoldValue,
    double? ornamentsGoldValue,
    double? expectedReturn,
    bool? includeSolidInFireCorpus,
    bool? includeOrnamentsInFireCorpus,
  }) {
    return GoldAssets(
      solidGoldValue: solidGoldValue ?? this.solidGoldValue,
      ornamentsGoldValue: ornamentsGoldValue ?? this.ornamentsGoldValue,
      expectedReturn: expectedReturn ?? this.expectedReturn,
      includeSolidInFireCorpus: includeSolidInFireCorpus ?? this.includeSolidInFireCorpus,
      includeOrnamentsInFireCorpus:
          includeOrnamentsInFireCorpus ?? this.includeOrnamentsInFireCorpus,
    );
  }

  Map<String, dynamic> toMap() => {
        'solidGoldValue': solidGoldValue,
        'ornamentsGoldValue': ornamentsGoldValue,
        'expectedReturn': expectedReturn,
        'includeSolidInFireCorpus': includeSolidInFireCorpus,
        'includeOrnamentsInFireCorpus': includeOrnamentsInFireCorpus,
      };

  factory GoldAssets.fromMap(Map<String, dynamic> map) {
    return GoldAssets(
      solidGoldValue: (map['solidGoldValue'] as num?)?.toDouble() ?? 0.0,
      ornamentsGoldValue: (map['ornamentsGoldValue'] as num?)?.toDouble() ?? 0.0,
      expectedReturn: (map['expectedReturn'] as num?)?.toDouble() ?? 0.08,
      includeSolidInFireCorpus: map['includeSolidInFireCorpus'] as bool? ?? true,
      includeOrnamentsInFireCorpus: map['includeOrnamentsInFireCorpus'] as bool? ?? false,
    );
  }
}

/// Represents Cash, Savings, FDs, and Liquid emergency funds
class CashAssets {
  final double cashInHand; // Physical cash + Savings accounts
  final double fixedDeposits; // Bank FDs, Liquid Mutual Funds, T-Bills
  final double expectedReturn; // e.g. 0.065 for 6.5% p.a.
  final double emergencyFundMonths; // Number of months expenses locked as pure emergency buffer (e.g. 6)

  const CashAssets({
    this.cashInHand = 0.0,
    this.fixedDeposits = 0.0,
    this.expectedReturn = 0.065,
    this.emergencyFundMonths = 6.0,
  });

  double get totalCashAndDeposits => cashInHand + fixedDeposits;

  double projectedCashAt(double years) {
    if (totalCashAndDeposits <= 0) return 0.0;
    return totalCashAndDeposits * pow(1.0 + expectedReturn, years);
  }

  CashAssets copyWith({
    double? cashInHand,
    double? fixedDeposits,
    double? expectedReturn,
    double? emergencyFundMonths,
  }) {
    return CashAssets(
      cashInHand: cashInHand ?? this.cashInHand,
      fixedDeposits: fixedDeposits ?? this.fixedDeposits,
      expectedReturn: expectedReturn ?? this.expectedReturn,
      emergencyFundMonths: emergencyFundMonths ?? this.emergencyFundMonths,
    );
  }

  Map<String, dynamic> toMap() => {
        'cashInHand': cashInHand,
        'fixedDeposits': fixedDeposits,
        'expectedReturn': expectedReturn,
        'emergencyFundMonths': emergencyFundMonths,
      };

  factory CashAssets.fromMap(Map<String, dynamic> map) {
    return CashAssets(
      cashInHand: (map['cashInHand'] as num?)?.toDouble() ?? 0.0,
      fixedDeposits: (map['fixedDeposits'] as num?)?.toDouble() ?? 0.0,
      expectedReturn: (map['expectedReturn'] as num?)?.toDouble() ?? 0.065,
      emergencyFundMonths: (map['emergencyFundMonths'] as num?)?.toDouble() ?? 6.0,
    );
  }
}

/// All Physical & Non-Equity Property Asset Inputs
class PhysicalAssetsInputs {
  final List<ApartmentProperty> apartments;
  final List<LandProperty> lands;
  final GoldAssets gold;
  final CashAssets cash;

  const PhysicalAssetsInputs({
    this.apartments = const [],
    this.lands = const [],
    this.gold = const GoldAssets(),
    this.cash = const CashAssets(),
  });

  PhysicalAssetsInputs copyWith({
    List<ApartmentProperty>? apartments,
    List<LandProperty>? lands,
    GoldAssets? gold,
    CashAssets? cash,
  }) {
    return PhysicalAssetsInputs(
      apartments: apartments ?? this.apartments,
      lands: lands ?? this.lands,
      gold: gold ?? this.gold,
      cash: cash ?? this.cash,
    );
  }

  Map<String, dynamic> toMap() => {
        'apartments': apartments.map((a) => a.toMap()).toList(),
        'lands': lands.map((l) => l.toMap()).toList(),
        'gold': gold.toMap(),
        'cash': cash.toMap(),
      };

  factory PhysicalAssetsInputs.fromMap(Map<String, dynamic> map) {
    return PhysicalAssetsInputs(
      apartments: (map['apartments'] as List<dynamic>?)
              ?.map((e) => ApartmentProperty.fromMap(e as Map<String, dynamic>))
              .toList() ??
          const [],
      lands: (map['lands'] as List<dynamic>?)
              ?.map((e) => LandProperty.fromMap(e as Map<String, dynamic>))
              .toList() ??
          const [],
      gold: map['gold'] != null
          ? GoldAssets.fromMap(map['gold'] as Map<String, dynamic>)
          : const GoldAssets(),
      cash: map['cash'] != null
          ? CashAssets.fromMap(map['cash'] as Map<String, dynamic>)
          : const CashAssets(),
    );
  }
}

/// Result of evaluating physical assets & properties
class PhysicalAssetsResults {
  final double totalLandValue;
  final double totalApartmentValue;
  final double totalRealEstateValue;
  final double totalMortgageBalance;
  final double totalApartmentMonthlyEmi;
  final double totalMonthlyRentalIncome;
  final double totalAnnualRentalIncome;

  final double solidGoldValue;
  final double ornamentsGoldValue;
  final double totalGoldValue;

  final double cashInHand;
  final double fixedDeposits;
  final double totalCashAndDeposits;

  final double totalPhysicalAssets;
  final double totalPhysicalLiabilities;
  final double netPhysicalEquity;

  // Values projected at target retirement horizon
  final double projectedRealEstateValueAtRetirement;
  final double projectedSolidGoldAtRetirement;
  final double projectedCashAtRetirement;

  // Liquid additions that contribute to FIRE corpus at retirement
  final double liquidRealEstateAtRetirement; // from monetized properties
  final double liquidGoldAtRetirement; // from solid gold (and ornaments if enabled)
  final double liquidCashAtRetirement; // from cash/FDs
  final double totalLiquidPhysicalAdditionsAtRetirement;

  const PhysicalAssetsResults({
    required this.totalLandValue,
    required this.totalApartmentValue,
    required this.totalRealEstateValue,
    required this.totalMortgageBalance,
    required this.totalApartmentMonthlyEmi,
    required this.totalMonthlyRentalIncome,
    required this.totalAnnualRentalIncome,
    required this.solidGoldValue,
    required this.ornamentsGoldValue,
    required this.totalGoldValue,
    required this.cashInHand,
    required this.fixedDeposits,
    required this.totalCashAndDeposits,
    required this.totalPhysicalAssets,
    required this.totalPhysicalLiabilities,
    required this.netPhysicalEquity,
    required this.projectedRealEstateValueAtRetirement,
    required this.projectedSolidGoldAtRetirement,
    required this.projectedCashAtRetirement,
    required this.liquidRealEstateAtRetirement,
    required this.liquidGoldAtRetirement,
    required this.liquidCashAtRetirement,
    required this.totalLiquidPhysicalAdditionsAtRetirement,
  });

  bool get hasAssets => totalPhysicalAssets > 0;
  bool get hasMortgages => totalMortgageBalance > 0 || totalApartmentMonthlyEmi > 0;
  bool get hasRentalIncome => totalMonthlyRentalIncome > 0;
}

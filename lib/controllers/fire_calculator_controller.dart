import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/dashboard_models.dart';
import '../models/fire_inputs.dart';
import '../models/fire_results.dart';
import '../models/liabilities_emi_models.dart';
import '../models/physical_assets_models.dart';
import '../models/scenario_item.dart';
import '../services/dashboard_service.dart';
import '../services/fire_calculator_service.dart';
import '../services/history_service.dart';
import '../services/liabilities_emi_service.dart';
import '../services/physical_assets_service.dart';

class FireCalculatorController extends ChangeNotifier {
  final HistoryService historyService;

  FireInputs _inputs = const FireInputs();
  late FireResults _results;
  late List<ScenarioItem> _preBuiltScenarios;

  LiabilitiesEmiInputs _emiInputs = const LiabilitiesEmiInputs();
  late LiabilitiesEmiResults _emiResults;

  PhysicalAssetsInputs _physicalAssetsInputs = const PhysicalAssetsInputs();
  late PhysicalAssetsResults _physicalAssetsResults;
  late ComprehensiveFireSummary _dashboardSummary;

  Timer? _debounceTimer;

  FireCalculatorController({
    required this.historyService,
    bool autoRecordInitial = false,
  }) {
    _recalculate();
    if (autoRecordInitial && _inputs.currentMFValue > 0) {
      historyService.recordCombination(_inputs, _results, customTitle: 'Excel Initial Baseline');
    }
  }

  FireInputs get inputs => _inputs;
  FireResults get results => _results;
  List<ScenarioItem> get preBuiltScenarios => _preBuiltScenarios;

  LiabilitiesEmiInputs get emiInputs => _emiInputs;
  LiabilitiesEmiResults get emiResults => _emiResults;

  PhysicalAssetsInputs get physicalAssetsInputs => _physicalAssetsInputs;
  PhysicalAssetsResults get physicalAssetsResults => _physicalAssetsResults;
  ComprehensiveFireSummary get dashboardSummary => _dashboardSummary;

  void updateInputs(FireInputs newInputs, {bool autoSave = true}) {
    if (_inputs == newInputs) return;
    _inputs = newInputs;
    _recalculate();
    notifyListeners();

    if (autoSave) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 1500), () {
        historyService.recordCombination(_inputs, _results);
      });
    }
  }

  void updateEmiInputs(LiabilitiesEmiInputs newEmiInputs) {
    _emiInputs = newEmiInputs;
    _recalculate();
    notifyListeners();
  }

  void updateEmiField({
    double? homeLoanEmi,
    double? carLoanEmi,
    double? personalLoanEmi,
    double? otherLoanEmi,
    double? customTotalMonthlyEmi,
    bool clearCustomTotal = false,
    int? remainingEmiMonths,
    double? loanInterestRate,
    double? outstandingLoanPrincipal,
    bool? enableSipSqueeze,
    double? reducedMonthlyMfSipDuringEmi,
    bool? discountPostRetirementEmiAtInflation,
  }) {
    final updated = _emiInputs.copyWith(
      homeLoanEmi: homeLoanEmi,
      carLoanEmi: carLoanEmi,
      personalLoanEmi: personalLoanEmi,
      otherLoanEmi: otherLoanEmi,
      customTotalMonthlyEmi: customTotalMonthlyEmi,
      clearCustomTotal: clearCustomTotal,
      remainingEmiMonths: remainingEmiMonths,
      loanInterestRate: loanInterestRate,
      outstandingLoanPrincipal: outstandingLoanPrincipal,
      enableSipSqueeze: enableSipSqueeze,
      reducedMonthlyMfSipDuringEmi: reducedMonthlyMfSipDuringEmi,
      discountPostRetirementEmiAtInflation:
          discountPostRetirementEmiAtInflation,
    );
    updateEmiInputs(updated);
  }

  // Physical Assets Methods
  void updatePhysicalAssets(PhysicalAssetsInputs newInputs) {
    _physicalAssetsInputs = newInputs;
    _recalculate();
    notifyListeners();
  }

  void updateGold({
    double? solidGoldValue,
    double? ornamentsGoldValue,
    double? expectedReturn,
    bool? includeSolidInFireCorpus,
    bool? includeOrnamentsInFireCorpus,
  }) {
    final updatedGold = _physicalAssetsInputs.gold.copyWith(
      solidGoldValue: solidGoldValue,
      ornamentsGoldValue: ornamentsGoldValue,
      expectedReturn: expectedReturn,
      includeSolidInFireCorpus: includeSolidInFireCorpus,
      includeOrnamentsInFireCorpus: includeOrnamentsInFireCorpus,
    );
    updatePhysicalAssets(_physicalAssetsInputs.copyWith(gold: updatedGold));
  }

  void updateCash({
    double? cashInHand,
    double? fixedDeposits,
    List<DebtHolding>? holdings,
    double? expectedReturn,
    double? emergencyFundMonths,
  }) {
    final updatedCash = _physicalAssetsInputs.cash.copyWith(
      cashInHand: cashInHand,
      fixedDeposits: fixedDeposits,
      holdings: holdings,
      expectedReturn: expectedReturn,
      emergencyFundMonths: emergencyFundMonths,
    );
    updatePhysicalAssets(_physicalAssetsInputs.copyWith(cash: updatedCash));
  }

  void addDebtHolding(DebtHolding holding) {
    final list = List<DebtHolding>.from(_physicalAssetsInputs.cash.holdings)..add(holding);
    final updatedCash = _physicalAssetsInputs.cash.copyWith(holdings: list);
    updatePhysicalAssets(_physicalAssetsInputs.copyWith(cash: updatedCash));
  }

  void updateDebtHolding(DebtHolding updated) {
    final list = _physicalAssetsInputs.cash.holdings.map((h) => h.id == updated.id ? updated : h).toList();
    final updatedCash = _physicalAssetsInputs.cash.copyWith(holdings: list);
    updatePhysicalAssets(_physicalAssetsInputs.copyWith(cash: updatedCash));
  }

  void removeDebtHolding(String id) {
    final list = _physicalAssetsInputs.cash.holdings.where((h) => h.id != id).toList();
    final updatedCash = _physicalAssetsInputs.cash.copyWith(holdings: list);
    updatePhysicalAssets(_physicalAssetsInputs.copyWith(cash: updatedCash));
  }

  void addApartment(ApartmentProperty apartment) {
    final list = List<ApartmentProperty>.from(_physicalAssetsInputs.apartments)..add(apartment);
    updatePhysicalAssets(_physicalAssetsInputs.copyWith(apartments: list));
  }

  void updateApartment(ApartmentProperty updated) {
    final list = _physicalAssetsInputs.apartments.map((a) => a.id == updated.id ? updated : a).toList();
    updatePhysicalAssets(_physicalAssetsInputs.copyWith(apartments: list));
  }

  void removeApartment(String id) {
    final list = _physicalAssetsInputs.apartments.where((a) => a.id != id).toList();
    updatePhysicalAssets(_physicalAssetsInputs.copyWith(apartments: list));
  }

  void setHomeAssetWithLoan({
    String? id,
    required String name,
    required double marketValue,
    required double loanBalance,
    required double monthlyEmi,
    required int remainingMonths,
    double loanInterestRate = 0.085,
  }) {
    // 1. Find existing self-occupied/primary home apartment or create one
    final apartments = List<ApartmentProperty>.from(_physicalAssetsInputs.apartments);
    final idx = apartments.indexWhere((a) => (id != null && a.id == id) || a.isSelfOccupied || a.id == 'primary_home');
    final home = ApartmentProperty(
      id: idx >= 0 ? apartments[idx].id : (id ?? 'primary_home'),
      name: name.trim().isEmpty ? 'Primary Residence' : name.trim(),
      marketValue: marketValue,
      hasMortgage: loanBalance > 0 || monthlyEmi > 0,
      mortgageBalance: loanBalance,
      monthlyEmi: monthlyEmi,
      remainingEmiMonths: remainingMonths,
      loanInterestRate: loanInterestRate > 0 ? loanInterestRate : 0.085,
      isSelfOccupied: true,
      monetizeAtRetirement: false,
    );

    if (idx >= 0) {
      apartments[idx] = home;
    } else {
      apartments.insert(0, home);
    }
    updatePhysicalAssets(_physicalAssetsInputs.copyWith(apartments: apartments));

    // 2. Auto-populate into the EMI inputs
    final currentTotal = _emiInputs.customTotalMonthlyEmi ?? _emiInputs.totalMonthlyEmi;
    final newTotal = max(currentTotal, monthlyEmi);
    updateEmiField(
      homeLoanEmi: monthlyEmi,
      loanInterestRate: loanInterestRate > 0 ? loanInterestRate : _emiInputs.loanInterestRate,
      outstandingLoanPrincipal: loanBalance > 0 ? loanBalance : _emiInputs.outstandingLoanPrincipal,
      remainingEmiMonths: remainingMonths > 0 ? remainingMonths : _emiInputs.remainingEmiMonths,
      customTotalMonthlyEmi: newTotal > 0 ? newTotal : null,
      clearCustomTotal: newTotal == 0,
    );
  }

  void removeHomeAssetLoan(String id) {
    final apartments = _physicalAssetsInputs.apartments.where((a) => a.id != id).toList();
    updatePhysicalAssets(_physicalAssetsInputs.copyWith(apartments: apartments));
    updateEmiField(
      homeLoanEmi: 0.0,
      clearCustomTotal: true,
    );
  }

  void addLand(LandProperty land) {
    final list = List<LandProperty>.from(_physicalAssetsInputs.lands)..add(land);
    updatePhysicalAssets(_physicalAssetsInputs.copyWith(lands: list));
  }

  void updateLand(LandProperty updated) {
    final list = _physicalAssetsInputs.lands.map((l) => l.id == updated.id ? updated : l).toList();
    updatePhysicalAssets(_physicalAssetsInputs.copyWith(lands: list));
  }

  void removeLand(String id) {
    final list = _physicalAssetsInputs.lands.where((l) => l.id != id).toList();
    updatePhysicalAssets(_physicalAssetsInputs.copyWith(lands: list));
  }

  void updateField({
    double? targetYears,
    double? currentMonthlyExpenses,
    double? expectedInflationRate,
    double? currentMFValue,
    double? currentMFCostBasis,
    double? monthlyMFSIP,
    double? expectedMFReturn,
    double? currentEPFBalance,
    double? monthlyEPFContribution,
    double? expectedEPFReturn,
    double? upfrontMFCashOutRate,
    double? ltcgTaxRate,
    bool autoSave = true,
  }) {
    final updated = _inputs.copyWith(
      targetYears: targetYears,
      currentMonthlyExpenses: currentMonthlyExpenses,
      expectedInflationRate: expectedInflationRate,
      currentMFValue: currentMFValue,
      currentMFCostBasis: currentMFCostBasis,
      monthlyMFSIP: monthlyMFSIP,
      expectedMFReturn: expectedMFReturn,
      currentEPFBalance: currentEPFBalance,
      monthlyEPFContribution: monthlyEPFContribution,
      expectedEPFReturn: expectedEPFReturn,
      upfrontMFCashOutRate: upfrontMFCashOutRate,
      ltcgTaxRate: ltcgTaxRate,
    );
    updateInputs(updated, autoSave: autoSave);
  }

  void resetToBlank() {
    _physicalAssetsInputs = const PhysicalAssetsInputs();
    _emiInputs = const LiabilitiesEmiInputs();
    updateInputs(const FireInputs(), autoSave: false);
  }

  void resetToExcelDefault() {
    updateInputs(FireInputs.excelDefaults(), autoSave: false);
    historyService.recordCombination(_inputs, _results, customTitle: 'Excel Default (3Y, ₹1.25L)');
  }

  void applyScenario(ScenarioItem scenario) {
    final updated = scenario.toFireInputs(_inputs);
    updateInputs(updated, autoSave: false);
    historyService.recordCombination(_inputs, _results, customTitle: scenario.name);
  }

  void loadCombination(FireInputs savedInputs, String title) {
    updateInputs(savedInputs, autoSave: false);
    historyService.recordCombination(_inputs, _results, customTitle: title);
  }

  void saveCurrentToHistory({String? customName}) {
    historyService.recordCombination(
      _inputs,
      _results,
      customTitle: customName,
    );
  }

  void _recalculate() {
    _results = FireCalculatorService.calculate(_inputs);
    _preBuiltScenarios = FireCalculatorService.calculatePreBuiltScenarios(_inputs);
    _emiResults = LiabilitiesEmiService.calculate(
      fireInputs: _inputs,
      fireResults: _results,
      emiInputs: _emiInputs,
    );
    _physicalAssetsResults = PhysicalAssetsService.calculate(
      inputs: _physicalAssetsInputs,
      targetYears: _inputs.targetYears,
    );
    _dashboardSummary = DashboardService.calculate(
      fireInputs: _inputs,
      fireResults: _results,
      emiInputs: _emiInputs,
      emiResults: _emiResults,
      physicalInputs: _physicalAssetsInputs,
      physicalResults: _physicalAssetsResults,
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

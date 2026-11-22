import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fire_calculator/controllers/fire_calculator_controller.dart';
import 'package:fire_calculator/main.dart';
import 'package:fire_calculator/models/physical_assets_models.dart';
import 'package:fire_calculator/services/history_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('FIRE Simulator App loads and displays core elements', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final historyService = HistoryService();
    await historyService.loadHistory();
    final controller = FireCalculatorController(historyService: historyService);

    await tester.pumpWidget(FireCalculatorApp(controller: controller));
    await tester.pumpAndSettle();

    // Verify Executive Dashboard elements
    expect(find.text('FIRE & Net Worth Dashboard'), findsOneWidget);
    expect(find.text('TOTAL NET WORTH TODAY'), findsOneWidget);
    expect(find.textContaining('PROJECTED FIRE CORPUS'), findsOneWidget);

    // Navigate to Calculator tab and verify its elements
    await tester.tap(find.text('Calculator'), warnIfMissed: false);
    await tester.pumpAndSettle();

    // Verify Calculator Screen elements
    expect(find.text('FIRE Simulator (INR)'), findsOneWidget);
    expect(find.text('2. LIVE RETIREMENT READINESS OUTPUTS'), findsOneWidget);
    expect(find.text('1. YOUR INPUTS & ASSUMPTIONS'), findsOneWidget);
  });

  testWidgets('When liabilities section is filled, Calculator screen displays FIRE impact', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final historyService = HistoryService();
    await historyService.loadHistory();
    final controller = FireCalculatorController(historyService: historyService);

    // Enter a loan with post-retirement overhang: 50k EMI for 84 months (retirement at 36 months)
    controller.updateField(targetYears: 3, autoSave: false);
    controller.updateEmiField(
      homeLoanEmi: 50000.0,
      remainingEmiMonths: 84,
    );

    await tester.pumpWidget(FireCalculatorApp(controller: controller));
    await tester.pumpAndSettle();

    // Navigate to Calculator tab to inspect calculator screen impact
    await tester.tap(find.text('Calculator'), warnIfMissed: false);
    await tester.pumpAndSettle();

    // Verify Liabilities Impact Card appears on Calculator screen
    expect(find.text('LIABILITIES & DEBT IMPACT ON FIRE'), findsOneWidget);
    expect(find.text('Post-Retirement Debt PV'), findsAtLeastNWidgets(1));
    expect(find.text('48 Mo Overhang'), findsOneWidget);
    expect(find.textContaining('Adjusted'), findsAtLeastNWidgets(1));
  });

  testWidgets('Dashboard reflects physical assets (Properties, Gold, Cash)', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final historyService = HistoryService();
    await historyService.loadHistory();
    final controller = FireCalculatorController(historyService: historyService);

    controller.updatePhysicalAssets(PhysicalAssetsInputs(
      lands: [
        const LandProperty(
          id: 'land_test',
          name: 'Greenfield Land Plot',
          marketValue: 5000000.0,
        ),
      ],
      apartments: [
        const ApartmentProperty(
          id: 'apt_test',
          name: 'Marina Luxury Flat',
          marketValue: 12000000.0,
          hasMortgage: true,
          mortgageBalance: 4000000.0,
        ),
      ],
      gold: const GoldAssets(
        solidGoldValue: 1000000.0,
        ornamentsGoldValue: 800000.0,
      ),
      cash: const CashAssets(
        cashInHand: 300000.0,
        fixedDeposits: 1200000.0,
      ),
    ));

    await tester.pumpWidget(FireCalculatorApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('Greenfield Land Plot'), findsOneWidget);
    expect(find.text('Marina Luxury Flat'), findsOneWidget);
    expect(find.text('REAL ESTATE & PROPERTIES'), findsOneWidget);
    expect(find.text('PRECIOUS METALS / GOLD ASSETS'), findsOneWidget);
    expect(find.text('CASH & LIQUID RESERVES'), findsOneWidget);
  });
}

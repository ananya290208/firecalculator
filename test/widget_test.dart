import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fire_calculator/controllers/fire_calculator_controller.dart';
import 'package:fire_calculator/main.dart';
import 'package:fire_calculator/models/physical_assets_models.dart';
import 'package:fire_calculator/services/auth_service.dart';
import 'package:fire_calculator/services/history_service.dart';
import 'package:fire_calculator/widgets/exit_dialog.dart';

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

  testWidgets('Major Milestone Expenses section allows adding and displays goals', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferences.setMockInitialValues({});
    final historyService = HistoryService();
    await historyService.loadHistory();
    final controller = FireCalculatorController(historyService: historyService);

    await tester.pumpWidget(FireCalculatorApp(controller: controller));
    await tester.pumpAndSettle();

    // Verify milestone section header is displayed
    expect(find.text('MAJOR MILESTONE EXPENSES & LIFE GOALS'), findsOneWidget);

    // Click on quick add preset: Child Education
    final eduChip = find.text('🎓 Child Education (₹30L)');
    expect(eduChip, findsOneWidget);
    await tester.tap(eduChip);
    await tester.pumpAndSettle();

    // Verify goal has been added to controller and UI displays it
    expect(controller.milestoneGoals.length, 1);
    expect(controller.milestoneGoals.first.name, "Child's Higher Education");
    expect(find.text("Child's Higher Education"), findsAtLeastNWidgets(1));
    expect(find.text('Total Milestone Goals'), findsOneWidget);
  });

  testWidgets('Navigating to Milestones & Life Events tab displays dedicated screen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferences.setMockInitialValues({});
    final historyService = HistoryService();
    await historyService.loadHistory();
    final controller = FireCalculatorController(historyService: historyService);

    await tester.pumpWidget(FireCalculatorApp(controller: controller));
    await tester.pumpAndSettle();

    // Tap on Milestones & Life Events tab in left navigation rail
    await tester.tap(find.text('Milestones & Life Events').first, warnIfMissed: false);
    await tester.pumpAndSettle();

    // Verify dedicated screen elements
    expect(find.text('Major Milestones & Life Events'), findsOneWidget);
    expect(find.text('NEW MILESTONE GOAL'), findsOneWidget);
    expect(find.text('1-CLICK PRESET GOALS'), findsOneWidget);
    expect(find.text('How Sinking Fund SIP Works'), findsOneWidget);
    expect(find.text('Total Capital Outlay'), findsOneWidget);
  });

  testWidgets('ExitButton renders on desktop/mobile and launches confirmation dialog', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ExitButton(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final exitButtonFinder = find.byType(ExitButton);
    expect(exitButtonFinder, findsOneWidget);
    expect(find.byIcon(Icons.power_settings_new_rounded), findsOneWidget);

    // Tap exit button
    await tester.tap(exitButtonFinder);
    await tester.pumpAndSettle();

    // Verify confirmation dialog appears
    expect(find.text('Exit Application'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Exit'), findsOneWidget);
  });

  testWidgets('AuthScreen displays Demo - FIRE Calculator button and clicking it enters demo mode with locked tabs', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferences.setMockInitialValues({});
    final historyService = HistoryService();
    await historyService.loadHistory();
    final authService = AuthService();
    await authService.init();
    final controller = FireCalculatorController(historyService: historyService);

    await tester.pumpWidget(FireCalculatorApp(
      controller: controller,
      authService: authService,
    ));
    await tester.pumpAndSettle();

    // Verify AuthScreen is showing the Demo - FIRE Calculator button
    final demoBtn = find.byKey(const ValueKey('demo_calculator_button'));
    expect(demoBtn, findsOneWidget);
    expect(find.text('FREE PREVIEW'), findsOneWidget);

    // Scroll into view if needed and tap
    await tester.ensureVisible(demoBtn);
    await tester.tap(demoBtn);
    await tester.pumpAndSettle();

    // Verify Demo mode is activated and loaded directly into Calculator view
    expect(authService.isDemoMode, true);
    expect(find.text('FIRE Simulator (INR)'), findsOneWidget);
    expect(find.text('1. YOUR INPUTS & ASSUMPTIONS'), findsOneWidget);
    expect(find.text('2. LIVE RETIREMENT READINESS OUTPUTS'), findsOneWidget);
    expect(find.text('TOTAL NET WORTH TODAY'), findsOneWidget);

    // Verify non-calculator tabs are marked with lock icon/text
    expect(find.text('Executive Dashboard 🔒'), findsOneWidget);
    expect(find.text('Liabilities & EMI 🔒'), findsOneWidget);
    expect(find.text('Milestones & Life Events 🔒'), findsOneWidget);

    // Tap a locked tab (Liabilities & EMI 🔒)
    await tester.tap(find.text('Liabilities & EMI 🔒'));
    await tester.pumpAndSettle();

    // Verify locked dialog appears
    expect(find.text('Liabilities & EMI Locked in Demo'), findsOneWidget);
    expect(find.text('Stay in Demo'), findsOneWidget);
    expect(find.text('Sign In / Register'), findsAtLeastNWidgets(1));

    // Tap Stay in Demo
    await tester.tap(find.text('Stay in Demo'));
    await tester.pumpAndSettle();

    // Still in demo mode on Calculator
    expect(authService.isDemoMode, true);
    expect(find.text('FIRE Simulator (INR)'), findsOneWidget);
  });
}

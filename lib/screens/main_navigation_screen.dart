import 'package:flutter/material.dart';
import '../controllers/fire_calculator_controller.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'calculator_screen.dart';
import 'comparison_screen.dart';
import 'dashboard_screen.dart';
import 'debt_bucket_screen.dart';
import 'liabilities_emi_screen.dart';
import 'schedule_matrix_screen.dart';
import 'swp_sip_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final FireCalculatorController controller;
  final AuthService? authService;

  const MainNavigationScreen({
    super.key,
    required this.controller,
    this.authService,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _navigateToIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller.historyService,
      builder: (context, _) {
        final historyCount = widget.controller.historyService.combinations.length;

        final screens = [
          DashboardScreen(
            controller: widget.controller,
            onNavigateToCalculator: () => _navigateToIndex(1),
            onNavigateToLiabilities: () => _navigateToIndex(2),
            onNavigateToSwpSip: () => _navigateToIndex(3),
            onNavigateToDebtBucket: () => _navigateToIndex(4),
            onNavigateToSchedule: () => _navigateToIndex(5),
          ),
          CalculatorScreen(
            controller: widget.controller,
            onNavigateToComparison: () => _navigateToIndex(6),
            onNavigateToLiabilities: () => _navigateToIndex(2),
            authService: widget.authService,
          ),
          LiabilitiesEmiScreen(
            controller: widget.controller,
          ),
          SwpSipScreen(
            controller: widget.controller,
          ),
          DebtBucketScreen(
            controller: widget.controller,
          ),
          ScheduleMatrixScreen(
            controller: widget.controller,
            onNavigateToCalculator: () => _navigateToIndex(1),
          ),
          ComparisonScreen(
            controller: widget.controller,
            onNavigateToCalculator: () => _navigateToIndex(1),
          ),
        ];

        return LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;
            final bool isMobile = width < 600;
            final bool isDesktop = width >= 1100;

            if (isMobile) {
              // Mobile (< 600dp): Bottom NavigationBar
              return Scaffold(
                body: IndexedStack(
                  index: _currentIndex,
                  children: screens,
                ),
                bottomNavigationBar: NavigationBar(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: _navigateToIndex,
                  labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
                  destinations: [
                    const NavigationDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard_rounded),
                      label: 'Dashboard',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.calculate_outlined),
                      selectedIcon: Icon(Icons.calculate),
                      label: 'Calculator',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.account_balance_outlined),
                      selectedIcon: Icon(Icons.account_balance_rounded),
                      label: 'Liabilities',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.swap_horiz_outlined),
                      selectedIcon: Icon(Icons.swap_horiz_rounded),
                      label: 'SWP/SIP',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.shield_outlined),
                      selectedIcon: Icon(Icons.shield_rounded),
                      label: 'Debt Bucket',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.calendar_month_outlined),
                      selectedIcon: Icon(Icons.calendar_month_rounded),
                      label: 'Schedule',
                    ),
                    NavigationDestination(
                      icon: Badge(
                        isLabelVisible: historyCount > 0,
                        label: Text('$historyCount'),
                        child: const Icon(Icons.compare_arrows_outlined),
                      ),
                      selectedIcon: Badge(
                        isLabelVisible: historyCount > 0,
                        label: Text('$historyCount'),
                        child: const Icon(Icons.compare_arrows_rounded),
                      ),
                      label: 'Compare',
                    ),
                  ],
                ),
              );
            }

            // Tablet (600-1023dp) & Desktop (>= 1024dp): Left NavigationRail
            return Scaffold(
              body: Row(
                children: [
                  NavigationRail(
                    extended: isDesktop,
                    selectedIndex: _currentIndex,
                    onDestinationSelected: _navigateToIndex,
                    backgroundColor: Colors.white,
                    leading: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryNavy,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.savings_rounded, color: Colors.white, size: 22),
                          ),
                          if (isDesktop) ...[
                            const SizedBox(width: 10),
                            const Text(
                              'FIRE Simulator',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: AppTheme.primaryNavy,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    destinations: [
                      const NavigationRailDestination(
                        icon: Icon(Icons.dashboard_outlined),
                        selectedIcon: Icon(Icons.dashboard_rounded),
                        label: Text('Executive Dashboard'),
                      ),
                      const NavigationRailDestination(
                        icon: Icon(Icons.calculate_outlined),
                        selectedIcon: Icon(Icons.calculate),
                        label: Text('Calculator'),
                      ),
                      const NavigationRailDestination(
                        icon: Icon(Icons.account_balance_outlined),
                        selectedIcon: Icon(Icons.account_balance_rounded),
                        label: Text('Liabilities & EMI'),
                      ),
                      const NavigationRailDestination(
                        icon: Icon(Icons.swap_horiz_outlined),
                        selectedIcon: Icon(Icons.swap_horiz_rounded),
                        label: Text('SWP vs SIP'),
                      ),
                      const NavigationRailDestination(
                        icon: Icon(Icons.shield_outlined),
                        selectedIcon: Icon(Icons.shield_rounded),
                        label: Text('SIP Debt Bucket'),
                      ),
                      const NavigationRailDestination(
                        icon: Icon(Icons.calendar_month_outlined),
                        selectedIcon: Icon(Icons.calendar_month_rounded),
                        label: Text('Schedule & Matrix'),
                      ),
                      NavigationRailDestination(
                        icon: Badge(
                          isLabelVisible: historyCount > 0,
                          label: Text('$historyCount'),
                          child: const Icon(Icons.compare_arrows_outlined),
                        ),
                        selectedIcon: Badge(
                          isLabelVisible: historyCount > 0,
                          label: Text('$historyCount'),
                          child: const Icon(Icons.compare_arrows_rounded),
                        ),
                        label: Text('Saved Combinations ($historyCount)'),
                      ),
                    ],
                  ),
                  const VerticalDivider(thickness: 1, width: 1, color: AppTheme.borderLight),
                  Expanded(
                    child: IndexedStack(
                      index: _currentIndex,
                      children: screens,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../controllers/fire_calculator_controller.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/exit_dialog.dart';
import '../widgets/pinned_dashboard_header.dart';
import 'calculator_screen.dart';
import 'comparison_screen.dart';
import 'dashboard_screen.dart';
import 'debt_bucket_screen.dart';
import 'liabilities_emi_screen.dart';
import 'milestone_expenses_screen.dart';
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

  bool get isDemo => widget.authService?.isDemoMode == true;

  @override
  void initState() {
    super.initState();
    if (widget.authService?.isDemoMode == true) {
      _currentIndex = 1; // Default to Calculator in Demo mode
    }
  }

  @override
  void didUpdateWidget(covariant MainNavigationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.authService?.isDemoMode == true && _currentIndex != 1) {
      _currentIndex = 1;
    }
  }

  void _navigateToIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onDestinationSelected(int index) {
    if (isDemo && index != 1) {
      _showDemoLockedDialog(context, _getDestinationName(index));
      return;
    }
    _navigateToIndex(index);
  }

  String _getDestinationName(int index) {
    switch (index) {
      case 0:
        return 'Executive Dashboard';
      case 1:
        return 'Calculator';
      case 2:
        return 'Liabilities & EMI';
      case 3:
        return 'Milestones & Life Events';
      case 4:
        return 'SWP vs SIP';
      case 5:
        return 'SIP Debt Bucket';
      case 6:
        return 'Schedule & Matrix';
      case 7:
        return 'Saved Combinations';
      default:
        return 'Module';
    }
  }

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
          'Log out of account "${widget.authService?.userName ?? 'User'}" on this browser?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryNavy),
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

  void _showDemoLockedDialog(BuildContext context, String featureName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.lock_rounded, color: Color(0xFFD97706), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$featureName Locked in Demo',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are exploring the Demo FIRE Calculator. The complete application includes full institutional financial engines:',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
            ),
            const SizedBox(height: 12),
            _buildLockedFeatureBullet('Executive Net Worth & Physical Asset Tracking'),
            _buildLockedFeatureBullet('Home Loans, EMI Amortization & PV Overhang Modeling'),
            _buildLockedFeatureBullet('Major Milestone Outlays with Sinking-Fund SIP Guidance'),
            _buildLockedFeatureBullet('SWP-to-SIP Simulation & 3-Year Debt Transition Bucket'),
            _buildLockedFeatureBullet('10-Year Multi-Horizon Trajectory Matrix'),
            _buildLockedFeatureBullet('Scenario Comparison Engine (Save up to 5 Models)'),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.bgLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.primaryNavy),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sign in or register an account to unlock all modules with persistent local saving.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryNavy),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Stay in Demo'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.login_rounded, size: 16),
            label: const Text('Sign In / Register', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.pop(ctx);
              widget.authService?.exitDemoMode();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLockedFeatureBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded, color: AppTheme.primaryGreen, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textDark),
            ),
          ),
        ],
      ),
    );
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
            onNavigateToCalculator: () => _onDestinationSelected(1),
            onNavigateToLiabilities: () => _onDestinationSelected(2),
            onNavigateToMilestones: () => _onDestinationSelected(3),
            onNavigateToSwpSip: () => _onDestinationSelected(4),
            onNavigateToDebtBucket: () => _onDestinationSelected(5),
            onNavigateToSchedule: () => _onDestinationSelected(6),
          ),
          CalculatorScreen(
            controller: widget.controller,
            onNavigateToComparison: () => _onDestinationSelected(7),
            onNavigateToLiabilities: () => _onDestinationSelected(2),
            onNavigateToMilestones: () => _onDestinationSelected(3),
            authService: widget.authService,
          ),
          LiabilitiesEmiScreen(
            controller: widget.controller,
          ),
          MilestoneExpensesScreen(
            controller: widget.controller,
            onNavigateToCalculator: () => _onDestinationSelected(1),
          ),
          SwpSipScreen(
            controller: widget.controller,
          ),
          DebtBucketScreen(
            controller: widget.controller,
          ),
          ScheduleMatrixScreen(
            controller: widget.controller,
            onNavigateToCalculator: () => _onDestinationSelected(1),
          ),
          ComparisonScreen(
            controller: widget.controller,
            onNavigateToCalculator: () => _onDestinationSelected(1),
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
                body: SafeArea(
                  child: Column(
                    children: [
                      PinnedDashboardHeader(controller: widget.controller),
                      Expanded(
                        child: IndexedStack(
                          index: _currentIndex,
                          children: screens,
                        ),
                      ),
                    ],
                  ),
                ),
                bottomNavigationBar: NavigationBar(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: _onDestinationSelected,
                  labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
                  destinations: [
                    NavigationDestination(
                      icon: isDemo
                          ? const Icon(Icons.lock_outline_rounded, color: Colors.grey)
                          : const Icon(Icons.dashboard_outlined),
                      selectedIcon: isDemo
                          ? const Icon(Icons.lock_rounded, color: Colors.grey)
                          : const Icon(Icons.dashboard_rounded),
                      label: isDemo ? 'Dashboard 🔒' : 'Dashboard',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.calculate_outlined),
                      selectedIcon: Icon(Icons.calculate),
                      label: 'Calculator',
                    ),
                    NavigationDestination(
                      icon: isDemo
                          ? const Icon(Icons.lock_outline_rounded, color: Colors.grey)
                          : const Icon(Icons.account_balance_outlined),
                      selectedIcon: isDemo
                          ? const Icon(Icons.lock_rounded, color: Colors.grey)
                          : const Icon(Icons.account_balance_rounded),
                      label: isDemo ? 'Liabilities 🔒' : 'Liabilities',
                    ),
                    NavigationDestination(
                      icon: isDemo
                          ? const Icon(Icons.lock_outline_rounded, color: Colors.grey)
                          : const Icon(Icons.celebration_outlined),
                      selectedIcon: isDemo
                          ? const Icon(Icons.lock_rounded, color: Colors.grey)
                          : const Icon(Icons.celebration_rounded),
                      label: isDemo ? 'Milestones 🔒' : 'Milestones',
                    ),
                    NavigationDestination(
                      icon: isDemo
                          ? const Icon(Icons.lock_outline_rounded, color: Colors.grey)
                          : const Icon(Icons.swap_horiz_outlined),
                      selectedIcon: isDemo
                          ? const Icon(Icons.lock_rounded, color: Colors.grey)
                          : const Icon(Icons.swap_horiz_rounded),
                      label: isDemo ? 'SWP/SIP 🔒' : 'SWP/SIP',
                    ),
                    NavigationDestination(
                      icon: isDemo
                          ? const Icon(Icons.lock_outline_rounded, color: Colors.grey)
                          : const Icon(Icons.shield_outlined),
                      selectedIcon: isDemo
                          ? const Icon(Icons.lock_rounded, color: Colors.grey)
                          : const Icon(Icons.shield_rounded),
                      label: isDemo ? 'Debt Bucket 🔒' : 'Debt Bucket',
                    ),
                    NavigationDestination(
                      icon: isDemo
                          ? const Icon(Icons.lock_outline_rounded, color: Colors.grey)
                          : const Icon(Icons.calendar_month_outlined),
                      selectedIcon: isDemo
                          ? const Icon(Icons.lock_rounded, color: Colors.grey)
                          : const Icon(Icons.calendar_month_rounded),
                      label: isDemo ? 'Schedule 🔒' : 'Schedule',
                    ),
                    NavigationDestination(
                      icon: isDemo
                          ? const Icon(Icons.lock_outline_rounded, color: Colors.grey)
                          : Badge(
                              isLabelVisible: historyCount > 0,
                              label: Text('$historyCount'),
                              child: const Icon(Icons.compare_arrows_outlined),
                            ),
                      selectedIcon: isDemo
                          ? const Icon(Icons.lock_rounded, color: Colors.grey)
                          : Badge(
                              isLabelVisible: historyCount > 0,
                              label: Text('$historyCount'),
                              child: const Icon(Icons.compare_arrows_rounded),
                            ),
                      label: isDemo ? 'Compare 🔒' : 'Compare',
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
                    onDestinationSelected: _onDestinationSelected,
                    backgroundColor: Colors.white,
                    leading: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
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
                          if (isDemo) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: const Color(0xFFF59E0B)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.bolt_rounded, size: 11, color: Color(0xFFB45309)),
                                  const SizedBox(width: 3),
                                  Text(
                                    isDesktop ? 'DEMO MODE (CALCULATOR)' : 'DEMO',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFB45309),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    destinations: [
                      NavigationRailDestination(
                        icon: isDemo
                            ? const Icon(Icons.lock_outline_rounded, color: Colors.grey)
                            : const Icon(Icons.dashboard_outlined),
                        selectedIcon: isDemo
                            ? const Icon(Icons.lock_rounded, color: Colors.grey)
                            : const Icon(Icons.dashboard_rounded),
                        label: Text(
                          isDemo ? 'Executive Dashboard 🔒' : 'Executive Dashboard',
                          style: isDemo ? const TextStyle(color: Colors.grey) : null,
                        ),
                      ),
                      const NavigationRailDestination(
                        icon: Icon(Icons.calculate_outlined),
                        selectedIcon: Icon(Icons.calculate),
                        label: Text('Calculator'),
                      ),
                      NavigationRailDestination(
                        icon: isDemo
                            ? const Icon(Icons.lock_outline_rounded, color: Colors.grey)
                            : const Icon(Icons.account_balance_outlined),
                        selectedIcon: isDemo
                            ? const Icon(Icons.lock_rounded, color: Colors.grey)
                            : const Icon(Icons.account_balance_rounded),
                        label: Text(
                          isDemo ? 'Liabilities & EMI 🔒' : 'Liabilities & EMI',
                          style: isDemo ? const TextStyle(color: Colors.grey) : null,
                        ),
                      ),
                      NavigationRailDestination(
                        icon: isDemo
                            ? const Icon(Icons.lock_outline_rounded, color: Colors.grey)
                            : const Icon(Icons.celebration_outlined),
                        selectedIcon: isDemo
                            ? const Icon(Icons.lock_rounded, color: Colors.grey)
                            : const Icon(Icons.celebration_rounded),
                        label: Text(
                          isDemo ? 'Milestones & Life Events 🔒' : 'Milestones & Life Events',
                          style: isDemo ? const TextStyle(color: Colors.grey) : null,
                        ),
                      ),
                      NavigationRailDestination(
                        icon: isDemo
                            ? const Icon(Icons.lock_outline_rounded, color: Colors.grey)
                            : const Icon(Icons.swap_horiz_outlined),
                        selectedIcon: isDemo
                            ? const Icon(Icons.lock_rounded, color: Colors.grey)
                            : const Icon(Icons.swap_horiz_rounded),
                        label: Text(
                          isDemo ? 'SWP vs SIP 🔒' : 'SWP vs SIP',
                          style: isDemo ? const TextStyle(color: Colors.grey) : null,
                        ),
                      ),
                      NavigationRailDestination(
                        icon: isDemo
                            ? const Icon(Icons.lock_outline_rounded, color: Colors.grey)
                            : const Icon(Icons.shield_outlined),
                        selectedIcon: isDemo
                            ? const Icon(Icons.lock_rounded, color: Colors.grey)
                            : const Icon(Icons.shield_rounded),
                        label: Text(
                          isDemo ? 'SIP Debt Bucket 🔒' : 'SIP Debt Bucket',
                          style: isDemo ? const TextStyle(color: Colors.grey) : null,
                        ),
                      ),
                      NavigationRailDestination(
                        icon: isDemo
                            ? const Icon(Icons.lock_outline_rounded, color: Colors.grey)
                            : const Icon(Icons.calendar_month_outlined),
                        selectedIcon: isDemo
                            ? const Icon(Icons.lock_rounded, color: Colors.grey)
                            : const Icon(Icons.calendar_month_rounded),
                        label: Text(
                          isDemo ? 'Schedule & Matrix 🔒' : 'Schedule & Matrix',
                          style: isDemo ? const TextStyle(color: Colors.grey) : null,
                        ),
                      ),
                      NavigationRailDestination(
                        icon: isDemo
                            ? const Icon(Icons.lock_outline_rounded, color: Colors.grey)
                            : Badge(
                                isLabelVisible: historyCount > 0,
                                label: Text('$historyCount'),
                                child: const Icon(Icons.compare_arrows_outlined),
                              ),
                        selectedIcon: isDemo
                            ? const Icon(Icons.lock_rounded, color: Colors.grey)
                            : Badge(
                                isLabelVisible: historyCount > 0,
                                label: Text('$historyCount'),
                                child: const Icon(Icons.compare_arrows_rounded),
                              ),
                        label: Text(
                          isDemo ? 'Saved Combinations 🔒' : 'Saved Combinations ($historyCount)',
                          style: isDemo ? const TextStyle(color: Colors.grey) : null,
                        ),
                      ),
                    ],
                    trailing: isDemo
                        ? Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: isDesktop
                                    ? FilledButton.icon(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: AppTheme.primaryNavy,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        icon: const Icon(Icons.login_rounded, size: 16),
                                        label: const Text(
                                          'Sign In / Register',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                        ),
                                        onPressed: () => widget.authService?.exitDemoMode(),
                                      )
                                    : IconButton(
                                        tooltip: 'Sign In / Register (Exit Demo)',
                                        icon: const Icon(Icons.login_rounded, color: AppTheme.primaryNavy),
                                        onPressed: () => widget.authService?.exitDemoMode(),
                                      ),
                              ),
                            ),
                          )
                        : (kIsWeb
                            ? (widget.authService != null
                                ? Expanded(
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Padding(
                                        padding: const EdgeInsets.only(bottom: 16),
                                        child: isDesktop
                                            ? TextButton.icon(
                                                style: TextButton.styleFrom(
                                                  foregroundColor: AppTheme.textMuted,
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 14, vertical: 8),
                                                ),
                                                icon: const Icon(Icons.logout_rounded, size: 16),
                                                label: const Text('Log Out',
                                                    style: TextStyle(
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 13)),
                                                onPressed: () => _confirmLogout(context),
                                              )
                                            : IconButton(
                                                icon: const Icon(Icons.logout_rounded,
                                                    color: AppTheme.textMuted),
                                                tooltip: 'Log Out',
                                                onPressed: () => _confirmLogout(context),
                                              ),
                                      ),
                                    ),
                                  )
                                : null)
                            : Expanded(
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: isDesktop
                                        ? TextButton.icon(
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.redAccent,
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 16, vertical: 8),
                                            ),
                                            icon: const Icon(
                                                Icons.power_settings_new_rounded,
                                                size: 18),
                                            label: const Text('Exit App',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 13)),
                                            onPressed: () => showExitDialog(context),
                                          )
                                        : IconButton(
                                            icon: const Icon(
                                                Icons.power_settings_new_rounded,
                                                color: Colors.redAccent),
                                            tooltip: 'Exit App',
                                            onPressed: () => showExitDialog(context),
                                          ),
                                  ),
                                ),
                              )),
                  ),
                  const VerticalDivider(thickness: 1, width: 1, color: AppTheme.borderLight),
                  Expanded(
                    child: Column(
                      children: [
                        PinnedDashboardHeader(controller: widget.controller),
                        Expanded(
                          child: IndexedStack(
                            index: _currentIndex,
                            children: screens,
                          ),
                        ),
                      ],
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

import 'package:flutter/material.dart';
import 'controllers/fire_calculator_controller.dart';
import 'screens/website_shell.dart';
import 'services/auth_service.dart';
import 'services/history_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final historyService = HistoryService();
  await historyService.loadHistory();

  final authService = AuthService();
  await authService.init();

  final controller = FireCalculatorController(
    historyService: historyService,
    autoRecordInitial: historyService.combinations.isEmpty,
  );

  runApp(FireCalculatorApp(
    controller: controller,
    authService: authService,
  ));
}

class FireCalculatorApp extends StatelessWidget {
  final FireCalculatorController controller;
  final AuthService? authService;

  const FireCalculatorApp({
    super.key,
    required this.controller,
    this.authService,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveAuth = authService;

    return MaterialApp(
      title: 'FIRE Calculator (INR)',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.textScalerOf(context).clamp(
              minScaleFactor: 0.85,
              maxScaleFactor: 1.2,
            ),
          ),
          child: child!,
        );
      },
      home: WebsiteShell(
        controller: controller,
        authService: effectiveAuth,
      ),
    );
  }
}

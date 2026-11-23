import 'dart:io' as io;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shuts down the application across all platforms (Windows desktop, macOS, Linux, Android, iOS, Web).
Future<void> executeAppExit([BuildContext? context]) async {
  if (!kIsWeb) {
    // 1. Tell Windows / desktop native host to close the window (posts WM_CLOSE to HWND)
    try {
      await SystemChannels.platform.invokeMethod<void>('SystemNavigator.pop');
    } catch (_) {}

    // 2. Request clean desktop exit lifecycle via Flutter ServicesBinding
    try {
      await ServicesBinding.instance.exitApplication(ui.AppExitType.required);
    } catch (_) {}

    // 3. Fallback standard framework navigator pop
    try {
      await SystemNavigator.pop();
    } catch (_) {}

    // 4. Guaranteed termination on Windows / desktop OS
    try {
      if (io.Platform.isWindows || io.Platform.isLinux || io.Platform.isMacOS) {
        // Small delay to allow the native window close event to process, then force exit
        await Future.delayed(const Duration(milliseconds: 100));
        io.exit(0);
      }
    } catch (_) {
      try {
        io.exit(0);
      } catch (_) {}
    }
  } else {
    // On Web (running in Chrome/Edge on Windows or hosted on GitHub Pages):
    try {
      await SystemNavigator.pop();
    } catch (_) {}

    // Show dedicated session-ended screen since browsers restrict scripts from closing tabs
    if (context != null && context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AppExitedScreen()),
        (route) => false,
      );
    }
  }
}

void showExitDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.power_settings_new_rounded, color: Colors.redAccent),
          SizedBox(width: 10),
          Text(
            'Exit Application',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
      content: Text(
        kIsWeb
            ? 'Are you sure you want to close your FIRE Simulator session? On web browsers, you can safely close this browser tab.'
            : 'Are you sure you want to exit and close the FIRE Simulator application?',
        style: const TextStyle(fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          icon: const Icon(Icons.power_settings_new_rounded, size: 16),
          label: const Text(
            'Exit',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          onPressed: () async {
            Navigator.pop(ctx);
            await executeAppExit(context);
          },
        ),
      ],
    ),
  );
}

class ExitButton extends StatelessWidget {
  final Color? color;
  final double? size;

  const ExitButton({super.key, this.color, this.size});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Exit App',
      visualDensity: VisualDensity.compact,
      icon: Icon(
        Icons.power_settings_new_rounded,
        color: color ?? Colors.redAccent,
        size: size ?? 20,
      ),
      onPressed: () => showExitDialog(context),
    );
  }
}

/// Standalone visual confirmation screen displayed when running on Web
class AppExitedScreen extends StatelessWidget {
  const AppExitedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF334155)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.power_settings_new_rounded,
                  color: Colors.redAccent,
                  size: 44,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Application Closed',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'You have exited the FIRE Simulator.\nYou can now safely close this browser window or tab.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF14B8A6),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text(
                  'Relaunch Application',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

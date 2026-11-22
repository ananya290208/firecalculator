import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void showExitDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
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
      content: const Text(
        'Are you sure you want to exit and close the FIRE Simulator?',
        style: TextStyle(fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(ctx);
            if (!kIsWeb) {
              try {
                if (io.Platform.isWindows ||
                    io.Platform.isLinux ||
                    io.Platform.isMacOS) {
                  io.exit(0);
                } else {
                  SystemNavigator.pop();
                }
              } catch (_) {
                SystemNavigator.pop();
              }
            } else {
              SystemNavigator.pop();
            }
          },
          child: const Text(
            'Exit',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}

class ExitButton extends StatelessWidget {
  const ExitButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Exit App',
      icon: const Icon(
        Icons.power_settings_new_rounded,
        color: Colors.redAccent,
      ),
      onPressed: () => showExitDialog(context),
    );
  }
}

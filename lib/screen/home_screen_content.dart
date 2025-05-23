// lib/screen/home_screen_content.dart
import 'package:flutter/material.dart';

class HomeScreenContent extends StatelessWidget {
  final VoidCallback onStartPressed;
  final VoidCallback onNotifyPressed;

  const HomeScreenContent({
    super.key,
    required this.onStartPressed,
    required this.onNotifyPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8FDFA), Color(0xFFE2F6FB)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: onStartPressed,
              child: const Text('作業を開始する'),
            ),
            ElevatedButton(
              onPressed: onNotifyPressed,
              child: const Text('通知を出す'),
            ),
          ],
        ),
      ),
    );
  }
}

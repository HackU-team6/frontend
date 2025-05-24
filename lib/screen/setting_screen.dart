import 'package:flutter/material.dart';

class SettingScreen extends StatefulWidget {
  final VoidCallback onStartPressed;
  final VoidCallback onNotifyPressed;
  const SettingScreen({
    super.key,
    required this.onStartPressed,
    required this.onNotifyPressed,
  });

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
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
          children: [
            const Text('設定'),
            ElevatedButton(
              onPressed: widget.onStartPressed,
              child: const Text('作業を開始する'),
            ),
            ElevatedButton(
              onPressed: widget.onNotifyPressed,
              child: const Text('通知を出す'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'debug_screen.dart';

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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('設定', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: widget.onStartPressed,
              child: const Text('作業を開始する'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: widget.onNotifyPressed,
              child: const Text('通知を出す'),
            ),
            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 10),
            const Text('開発者向け', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DebugScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
              ),
              child: const Text('デバッグ画面を開く', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

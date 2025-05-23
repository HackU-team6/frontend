// lib/screen/home_screen_content.dart
import 'package:flutter/material.dart';
import 'package:nekoze_notify/screen/personalize_screen.dart';

class HomeScreenContent extends StatelessWidget {
  final VoidCallback onStartPressed;
  final VoidCallback onNotifyPressed;

  const HomeScreenContent({
    Key? key,
    required this.onStartPressed,
    required this.onNotifyPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: onStartPressed,
            child: const Text('作業を開始する'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PersonalizeScreen()),
              );
            },
            child: const Text('パーソナライズ画面に移動(デバッグ時のみ)'),
          ),
          ElevatedButton(
            onPressed: onNotifyPressed,
            child: const Text('通知を出す'),
          ),
        ],
      ),
    );
  }
}

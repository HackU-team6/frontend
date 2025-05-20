import 'package:flutter/material.dart';
import 'package:nekoze_notify/screen/personalize_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});

  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // TODO: ユーザーが座り始めたことを通知したので、ジャイロ値を1分おきに取ってくる関数を実装する
              },
              child: const Text('作業を開始する'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PersonalizeScreen(),
                  ),
                );
              },
              child: const Text(
                'パーソナライズ画面に移動(デバッグ時のみ)',
              ), // TODO: 後々、アプリを最初に起動した時にのみ開くように実装
            ),
          ],
        ),
      ),
    );
  }
}

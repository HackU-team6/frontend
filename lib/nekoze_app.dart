import 'package:flutter/material.dart';
import 'package:nekoze_notify/screen/home_screen.dart';

class NekozeApp extends StatelessWidget {
  const NekozeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '猫背検知アプリ',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: '猫背検知アプリ'),
    );
  }
}

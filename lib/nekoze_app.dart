import 'package:flutter/material.dart';
import 'package:nekoze_notify/screen/home_screen.dart';

class NekozeApp extends StatelessWidget {
  const NekozeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Posture Guard',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const HomeScreen(title: 'Posture Guard'),
      debugShowCheckedModeBanner: false,
    );
  }
}

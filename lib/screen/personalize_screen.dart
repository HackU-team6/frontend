import 'package:flutter/material.dart';
import 'package:flutter_airpods/flutter_airpods.dart';
import 'dart:async';

class PersonalizeScreen extends StatefulWidget {
  const PersonalizeScreen({super.key});

  @override
  State<PersonalizeScreen> createState() => _PersonalizeScreenState();
}

class _PersonalizeScreenState extends State<PersonalizeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('姿勢をパーソナライズ')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'リラックスした“正しい姿勢”で座り、\n「計測開始」を押して 5 秒間キープしてください。',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 160),
            ElevatedButton(
              onPressed: () {
                // TODO: 計測を開始する関数
              },
              child: Text("計測開始"),
            ),
          ],
        ),
      ),
    );
  }
}

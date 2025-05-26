// lib/screen/home_screen_content.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

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
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Text(
                "PostureGuard",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0AB3A1),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'AirPods Proで姿勢を見守る',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: Color(0xFF6D6D6D),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Expanded(flex: 4, child: _PostureBadComponent()),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: ListTile(
                    leading: const Icon(
                      Icons.headset,
                      color: Color(0xFF12B981),
                    ),
                    title: const Text(
                      'AirPods Pro',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('接続済み'),
                    trailing: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFF12B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(left: 52, right: 52, bottom: 50),
                child: SizedBox(
                  height: 40,
                  width: 110,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: 作業を開始する関数との繋ぎこみ
                    },
                    child: const Text(
                      '作業を開始する',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0AB3A1),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostureBadComponent extends StatefulWidget {
  const _PostureBadComponent({super.key});

  @override
  State<_PostureBadComponent> createState() => _PostureBadComponentState();
}

class _PostureBadComponentState extends State<_PostureBadComponent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 250,
                height: 250,
                child: CircularProgressIndicator(
                  value: 1,
                  strokeWidth: 12,
                  backgroundColor: Color(0xFFDDF0EF),
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFECA631)),
                ),
              ),
              AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationController.value * 2 * math.pi,
                    child: child,
                  );
                },
                child: SizedBox(
                  width: 250,
                  height: 250,
                  child: CircularProgressIndicator(
                    value: 0.75,
                    strokeWidth: 12,
                    backgroundColor: const Color(0xFFDDF0EF),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFECA631),
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0xFFF48B21), Color(0xFFF1603B)],
                      ),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '姿勢に注意',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '背筋を伸ばしましょう',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6D6D6D)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _PostureGoodComponent extends StatefulWidget {
  const _PostureGoodComponent({super.key});

  @override
  State<_PostureGoodComponent> createState() => _PostureGoodComponentState();
}

class _PostureGoodComponentState extends State<_PostureGoodComponent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 250,
                height: 250,
                child: CircularProgressIndicator(
                  value: 1,
                  strokeWidth: 12,
                  backgroundColor: Color(0xFFDDF0EF),
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF40CA95)),
                ),
              ),
              AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationController.value * 2 * math.pi,
                    child: child,
                  );
                },
                child: SizedBox(
                  width: 250,
                  height: 250,
                  child: CircularProgressIndicator(
                    value: 0.25,
                    strokeWidth: 12,
                    backgroundColor: const Color(0xFFDDF0EF),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF40CA95),
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0xFF13BD85), Color(0xFF2FCE95)],
                      ),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '良い姿勢です！',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'キープしましょう！',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6D6D6D)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

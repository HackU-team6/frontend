import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nekoze_notify/main.dart';
import 'package:nekoze_notify/screen/analysis_screen.dart';
import 'package:nekoze_notify/screen/home_screen_content.dart';
import 'package:nekoze_notify/screen/report_screen.dart';
import 'package:nekoze_notify/screen/setting_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});

  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  void initState() {
    super.initState();
    _pages = <Widget>[
      HomeScreenContent(),
      AnalysisScreen(),
      ReportScreen(),
      SettingScreen(
        onStartPressed: () {
          // TODO: ユーザーが座り始めたことを通知したので、ジャイロ値を1分おきに取ってくる関数を実装する
        },
        onNotifyPressed: _showPostureNotification,
      ),
    ];
  }

  void _onNavigationItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _showPostureNotification() async {
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(iOS: iosDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Posture Guard',
      '姿勢が崩れています！背筋を伸ばしましょう！',
      details,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFB3E9D6),
        title: Text(widget.title),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF12B981),
        unselectedItemColor: const Color(0xFF8E9CAD),
        onTap: _onNavigationItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ホーム'),
          BottomNavigationBarItem(
            icon: Icon(Icons.signal_cellular_alt),
            label: '統計',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.description), label: 'レポート'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '設定'),
        ],
      ),
    );
  }
}

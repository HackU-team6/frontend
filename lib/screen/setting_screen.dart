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
  bool _realtimeMonitoring = true;
  bool _vibrationAlert = true;
  bool _voiceGuidance = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8FDFA), Color(0xFFE2F6FB)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const Text(
                  '姿勢キャリブレーション',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                const Text('あなたの正しい姿勢を記録して基準を設定します'),
                const SizedBox(height: 32),
                const _CalibrationCard(),
                const SizedBox(height: 32),
                _AlertSettingsSection(
                  realtimeMonitoring: _realtimeMonitoring,
                  vibrationAlert: _vibrationAlert,
                  voiceGuidance: _voiceGuidance,
                  onRealtimeChanged:
                      (v) => setState(() => _realtimeMonitoring = v),
                  onVibrationChanged:
                      (v) => setState(() => _vibrationAlert = v),
                  onVoiceChanged: (v) => setState(() => _voiceGuidance = v),
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 10),
                const Text(
                  '開発者向け',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DebugScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                  ),
                  child: const Text(
                    'デバッグ画面を開く',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: widget.onStartPressed,
                  child: const Text('作業を開始する'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: widget.onNotifyPressed,
                  child: const Text('通知を出す'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CalibrationCard extends StatelessWidget {
  const _CalibrationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFB5E5D8), width: 1),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF00B68F), Color(0xFF1DB0E9)],
              ),
            ),
            child: const Center(
              child: Icon(Icons.person_outline, size: 48, color: Colors.white),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '姿勢を測定',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              '正しい姿勢で座り、測定ボタンを押してください',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 32),
          _GradientButton(
            text: '測定開始',
            icon: Icons.radio_button_unchecked,
            onPressed: () {
              // TODO: Implement measurement start logic
            },
          ),
        ],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;
  const _GradientButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onPressed,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF00B68F), Color(0xFF1DB0E9)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertSettingsSection extends StatelessWidget {
  final bool realtimeMonitoring;
  final bool vibrationAlert;
  final bool voiceGuidance;
  final ValueChanged<bool> onRealtimeChanged;
  final ValueChanged<bool> onVibrationChanged;
  final ValueChanged<bool> onVoiceChanged;

  const _AlertSettingsSection({
    super.key,
    required this.realtimeMonitoring,
    required this.vibrationAlert,
    required this.voiceGuidance,
    required this.onRealtimeChanged,
    required this.onVibrationChanged,
    required this.onVoiceChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            children: [
              Icon(
                Icons.notifications_none_rounded,
                color: const Color(0xFF00B68F),
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'アラート設定',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _AlertOptionCard(
          title: '通知の設定',
          subtitle: '猫背を検知した際に通知を表示するか',
          value: realtimeMonitoring,
          onChanged: onRealtimeChanged,
        ),
        const SizedBox(height: 24),
        _AlertOptionCard(
          title: '通知までの秒数',
          subtitle: '猫背を検知してから通知を送るまでの待機時間',
          value: vibrationAlert,
          onChanged: onVibrationChanged,
        ),
        const SizedBox(height: 24),
        _AlertOptionCard(
          title: '通知間隔',
          subtitle: '通知と次の通知の間に空ける時間',
          value: voiceGuidance,
          onChanged: onVoiceChanged,
        ),
      ],
    );
  }
}

class _AlertOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _AlertOptionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFB5E5D8), width: 1),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF00B68F),
          ),
        ],
      ),
    );
  }
}

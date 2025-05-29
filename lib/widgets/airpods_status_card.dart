import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nekoze_notify/provider/airpods_connection_provider.dart';

class AirPodsStatusCard extends ConsumerWidget {
  const AirPodsStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connection = ref.watch(airPodsConnectionProvider);

    return Column(
      children: [
        const SizedBox(height: 16.0),
        _buildCard(
          connection.isChecking
              ? '接続状態を確認中...'
              : connection.isConnected
                  ? '接続済み'
                  : '未接続',
          connection.isConnected ? Colors.green : Colors.red,
        ),
      ],
    );
  }

  Widget _buildCard(String subtitle, Color dotColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: ListTile(
          leading: const Icon(Icons.headset, color: Color(0xFF12B981)),
          title: const Text(
            'AirPods Pro',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(subtitle),
          trailing: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}

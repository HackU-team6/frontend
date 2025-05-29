import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nekoze_notify/constants/app_constants.dart';
import 'package:nekoze_notify/services/airpods_motion_service.dart';

class AirPodsConnectionState {
  final bool isConnected;
  final bool isChecking;

  const AirPodsConnectionState({
    required this.isConnected,
    required this.isChecking,
  });

  AirPodsConnectionState copyWith({
    bool? isConnected,
    bool? isChecking,
  }) {
    return AirPodsConnectionState(
      isConnected: isConnected ?? this.isConnected,
      isChecking: isChecking ?? this.isChecking,
    );
  }
}

class AirPodsConnectionNotifier extends StateNotifier<AirPodsConnectionState> {
  Timer? _checkTimer;

  AirPodsConnectionNotifier()
      : super(const AirPodsConnectionState(
    isConnected: false,
    isChecking: false,
  )) {
    // 初期化時に接続チェック
    _checkConnection();
    // 定期的に接続状態をチェック（airPodsConnectionCheckIntervalごと）
    _checkTimer = Timer.periodic(
      AppConstants.airPodsConnectionCheckInterval,
          (_) {
        _checkConnection();
      },
    );
  }

  Future<void> _checkConnection() async {
    if (state.isChecking) return;

    state = state.copyWith(isChecking: true);

    try {
      final isConnected = await AirPodsMotionService.isConnected();
      state = state.copyWith(
        isConnected: isConnected,
        isChecking: false,
      );
    } catch (e) {
      state = state.copyWith(
        isConnected: false,
        isChecking: false,
      );
    }
  }

  // 手動で接続状態を更新
  Future<void> refreshConnection() async {
    await _checkConnection();
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }
}

final airPodsConnectionProvider =
StateNotifierProvider<AirPodsConnectionNotifier, AirPodsConnectionState>(
      (ref) => AirPodsConnectionNotifier(),
);

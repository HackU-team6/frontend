import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_airpods/flutter_airpods.dart';
import 'package:flutter_airpods/models/device_motion_data.dart';
import 'package:flutter_airpods/models/attitude.dart';
import 'package:flutter_airpods/models/rotation_rate.dart';
import 'package:rxdart/rxdart.dart';

/// AirPodsのモーションデータを扱うサービス
class AirPodsMotionService {
  const AirPodsMotionService._();

  // シングルトンストリーム（複数リスナー対応）
  static final BehaviorSubject<DeviceMotionData?> _motionSubject =
  BehaviorSubject<DeviceMotionData?>();

  static StreamSubscription<DeviceMotionData>? _subscription;
  static bool _isInitialized = false;
  static DateTime? _lastDataTime;  // 最後にデータを受信した時刻

  /// サービスを初期化
  static void initialize() {
    if (_isInitialized) return;

    _subscription = FlutterAirpods.getAirPodsDeviceMotionUpdates
        .handleError((error) {
      // エラーをログに記録するが、ストリームは継続
      debugPrint('AirPodsMotionService Error: $error');
    })
        .listen(
          (data) {
        _lastDataTime = DateTime.now();  // データ受信時刻を記録
        _motionSubject.add(data);
      },
      onError: (error) => _motionSubject.addError(error),
    );

    _isInitialized = true;
  }

  /// サービスを破棄
  static void dispose() {
    _subscription?.cancel();
    _motionSubject.close();
    _isInitialized = false;
    _lastDataTime = null;
  }

  /// AirPodsの接続状態を確認（改善版）
  static Future<bool> isConnected() async {
    if (!_isInitialized) initialize();

    // 最後にデータを受信してから3秒以上経過していたら未接続と判断
    if (_lastDataTime == null) {
      // まだ一度もデータを受信していない場合は、短時間待って確認
      try {
        await motion$()
            .where((data) => data != null)
            .timeout(const Duration(seconds: 1))
            .first;
        return _lastDataTime != null;
      } catch (e) {
        return false;
      }
    }

    final timeSinceLastData = DateTime.now().difference(_lastDataTime!);
    return timeSinceLastData.inSeconds < 3;
  }

  /// デバイスモーションデータのストリーム
  static Stream<DeviceMotionData?> motion$() {
    if (!_isInitialized) initialize();
    return _motionSubject.stream;
  }

  /// 姿勢（ピッチ/ロール/ヨー, クォータニオン）のストリーム
  static Stream<Attitude> attitude$() {
    return motion$()
        .where((data) => data != null)
        .map((data) => data!.attitude);
  }

  /// ジャイロデータのストリーム
  static Stream<RotationRate> gyro$() {
    return motion$()
        .where((data) => data != null)
        .map((data) => data!.rotationRate);
  }

  /// 現在の姿勢データを取得（ワンショット）
  static Future<Attitude?> getCurrentAttitude() async {
    try {
      return await attitude$()
          .timeout(const Duration(seconds: 1))
          .first;
    } catch (e) {
      return null;
    }
  }
}
// lib/services/airpods_motion_service.dart
//
// AirPods のモーションデータを扱うユーティリティ。
// ──────────────────────────────────────────
import 'package:flutter_airpods/flutter_airpods.dart';
import 'package:flutter_airpods/models/device_motion_data.dart';
import 'package:flutter_airpods/models/attitude.dart';
import 'package:flutter_airpods/models/rotation_rate.dart';

class AirPodsMotionService {
  const AirPodsMotionService._(); // インスタンス化禁止

  // asBroadcastStream で複数リスナーを安全に共有
  static final Stream<DeviceMotionData> _motion$ =
      FlutterAirpods.getAirPodsDeviceMotionUpdates.asBroadcastStream();

  /// 姿勢（ピッチ/ロール/ヨー, クォータニオン）ストリーム
  static Stream<Attitude> attitude$() => _motion$.map((e) => e.attitude);

  /// ジャイロストリーム
  static Stream<RotationRate> gyro$() => _motion$.map((e) => e.rotationRate);
}

import 'package:flutter_airpods/flutter_airpods.dart';
import 'package:flutter_airpods/models/attitude.dart';
import 'package:flutter_airpods/models/rotation_rate.dart';
import 'package:flutter_airpods/models/device_motion_data.dart';

/// AirPodsのモーションセンサー情報にアクセスするためのユーティリティクラス。
class AirPodsMotionService {
  // インスタンス化を禁止（staticメソッド専用）
  const AirPodsMotionService._();

  // デバイスモーションのストリーム（内部保持用）
  static final Stream<DeviceMotionData> _motionStream =
      FlutterAirpods.getAirPodsDeviceMotionUpdates.asBroadcastStream();

  /// 現在のジャイロ値と姿勢（クォータニオン）を同時に取得する。
  ///
  /// このメソッドはAirPodsから最新のデバイスモーションデータを取得し、
  /// ジャイロ値と姿勢を返します。
  ///
  /// 戻り値:
  ///   [Map]<[String], [dynamic]> - 'gyro'キーにジャイロ値、'attitude'キーに姿勢（クォータニオン）を持つマップ。
  static Future<Map<String, dynamic>> getCurrentMotion() async {
    final DeviceMotionData data = await _motionStream.first;
    return {'gyro': data.rotationRate, 'attitude': data.attitude};
  }

  /// ジャイロ値のストリームを返す。
  ///
  /// 戻り値:
  ///   [Stream]<[RotationRate]> - x, y, z の角速度を持つストリーム。
  static Stream<RotationRate> gyroStream() =>
      _motionStream.map((event) => event.rotationRate);

  /// 姿勢（クォータニオン）のストリームを返す。
  ///
  /// 戻り値:
  ///   [Stream]<[Attitude]> - x, y, z, wのクォータニオンと、ピッチ、ロール、ヨー角度を持つストリーム。
  static Stream<Attitude> attitudeStream() =>
      _motionStream.map((event) => event.attitude);
}

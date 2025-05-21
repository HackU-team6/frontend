import 'package:flutter_airpods/flutter_airpods.dart';
import 'package:flutter_airpods/models/rotation_rate.dart';
import 'package:flutter_airpods/models/device_motion_data.dart';

/// AirPodsのモーションセンサー情報にアクセスするためのユーティリティクラス。
class AirPodsMotionService {
  // インスタンス化を禁止（staticメソッド専用）
  const AirPodsMotionService._();

  /// 最新のジャイロ（角速度）値を取得（単位: rad/s）。
  ///
  /// このメソッドはAirPodsから最新のジャイロセンサー（角速度）値を非同期で取得。
  /// AirPodsが接続されていない場合やデータが取得できない場合は例外が発生。
  ///
  /// 戻り値:
  ///   [RotationRate] - x, y, zのそれぞれの角速度値を持つオブジェクト。
  static Future<RotationRate> getGyro() async {
    final DeviceMotionData data =
        await FlutterAirpods.getAirPodsDeviceMotionUpdates.first;
    return data.rotationRate;
  }

  /// ジャイロセンサー値のストリームを返します。
  ///
  /// このメソッドはAirPodsからジャイロセンサー（角速度）値のストリームを取得します。
  /// AirPodsが接続されていない場合やデータが取得できない場合は例外が発生します。
  ///
  /// 戻り値:
  ///   [Stream]<[RotationRate]> - x, y, zのそれぞれの角速度値を持つオブジェクトのストリーム。
  static Stream<RotationRate> gyroStream() =>
      FlutterAirpods.getAirPodsDeviceMotionUpdates
          .map((event) => event.rotationRate);
}

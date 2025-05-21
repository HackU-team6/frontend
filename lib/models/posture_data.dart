import 'package:flutter_airpods/models/rotation_rate.dart';

/// 姿勢データを表すモデルクラス
/// 
/// ユーザーの正しい姿勢の基準となるジャイロセンサーの値を保持します。
class PostureData {
  /// 正しい姿勢の基準となるジャイロセンサーの値
  final RotationRate referencePosture;
  
  /// 最後にキャリブレーションを行った日時
  final DateTime calibrationTime;
  
  /// コンストラクタ
  PostureData({
    required this.referencePosture,
    required this.calibrationTime,
  });
  
  /// JSONからPostureDataオブジェクトを生成するファクトリメソッド
  factory PostureData.fromJson(Map<String, dynamic> json) {
    return PostureData(
      referencePosture: RotationRate(
        json['referenceX'] as double,
        json['referenceY'] as double,
        json['referenceZ'] as double,
      ),
      calibrationTime: DateTime.parse(json['calibrationTime'] as String),
    );
  }
  
  /// PostureDataオブジェクトをJSON形式に変換するメソッド
  Map<String, dynamic> toJson() {
    return {
      'referenceX': referencePosture.x,
      'referenceY': referencePosture.y,
      'referenceZ': referencePosture.z,
      'calibrationTime': calibrationTime.toIso8601String(),
    };
  }
}
import 'dart:convert';
import 'package:flutter_airpods/models/rotation_rate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nekoze_notify/models/posture_data.dart';

/// 姿勢データの保存と取得を行うサービスクラス
class PostureService {
  /// SharedPreferencesのキー
  static const String _postureDataKey = 'posture_data';
  
  /// 新しいキャリブレーションデータを保存する
  /// 
  /// [referencePosture] 正しい姿勢の基準となるジャイロセンサーの値
  /// 
  /// 戻り値: 保存が成功したかどうかを示すFuture<bool>
  Future<bool> saveNewCalibration(RotationRate referencePosture) async {
    try {
      // 現在の日時を取得
      final now = DateTime.now();
      
      // PostureDataオブジェクトを作成
      final postureData = PostureData(
        referencePosture: referencePosture,
        calibrationTime: now,
      );
      
      // SharedPreferencesのインスタンスを取得
      final prefs = await SharedPreferences.getInstance();
      
      // PostureDataをJSON文字列に変換して保存
      final jsonString = jsonEncode(postureData.toJson());
      return await prefs.setString(_postureDataKey, jsonString);
    } catch (e) {
      print('キャリブレーションデータの保存に失敗しました: $e');
      return false;
    }
  }
  
  /// 保存されているキャリブレーションデータを取得する
  /// 
  /// 戻り値: 保存されているPostureDataオブジェクト。データがない場合はnull
  Future<PostureData?> getCalibrationData() async {
    try {
      // SharedPreferencesのインスタンスを取得
      final prefs = await SharedPreferences.getInstance();
      
      // 保存されているJSON文字列を取得
      final jsonString = prefs.getString(_postureDataKey);
      
      // データがない場合はnullを返す
      if (jsonString == null) {
        return null;
      }
      
      // JSON文字列をMapに変換
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // MapからPostureDataオブジェクトを生成
      return PostureData.fromJson(json);
    } catch (e) {
      print('キャリブレーションデータの取得に失敗しました: $e');
      return null;
    }
  }
  
  /// キャリブレーションデータが存在するかどうかを確認する
  /// 
  /// 戻り値: データが存在する場合はtrue、存在しない場合はfalse
  Future<bool> hasCalibrationData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_postureDataKey);
  }
  
  /// キャリブレーションデータを削除する
  /// 
  /// 戻り値: 削除が成功したかどうかを示すFuture<bool>
  Future<bool> clearCalibrationData() async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.remove(_postureDataKey);
  }
}
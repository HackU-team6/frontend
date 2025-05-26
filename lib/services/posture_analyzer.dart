// lib/services/posture_analyzer.dart
//
// AirPods ピッチ値を用いた姿勢解析クラス。
// ──────────────────────────────────────────
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/calibration_storage.dart';
import 'airpods_motion_service.dart';
import 'package:flutter_airpods/models/attitude.dart';

/// 姿勢状態
enum PostureState { good, poor }

/// 通知
final _notifications = FlutterLocalNotificationsPlugin();

class PostureAnalyzer {
  PostureAnalyzer({
    this.thresholdDeg = 8, // 姿勢悪化の閾値（度）
    this.avgWindow = const Duration(milliseconds: 500), // 移動平均のウィンドウ時間
    this.confirmDuration = const Duration(seconds: 1), // 姿勢悪化を確定するまでの時間
    this.notificationInterval = const Duration(seconds: 10), // 通知のクールダウン時間
    this.isNotificationEnabled = true, // 通知を有効にするか
  }) {
    maxBufferSize =
        (avgWindow.inMilliseconds * 60 / 1000).ceil(); // AirPodsの更新頻度は約60Hz
  }

  final double thresholdDeg;
  final Duration avgWindow;
  final Duration confirmDuration;
  final Duration notificationInterval;
  final bool isNotificationEnabled;
  late final int maxBufferSize;

  // キャリブレーション値を取得するゲッター
  double? get baselinePitch => _baselinePitch;

  // 内部ストリーム
  final _stateCtl = StreamController<PostureState>.broadcast();
  Stream<PostureState> get state$ => _stateCtl.stream;

  final _storage = CalibrationStorage();
  double? _baselinePitch; // キャリブレーション値
  StreamSubscription<Attitude>? _sub;
  final _buffer = <double>[]; // 移動平均バッファ
  DateTime? _poorSince;
  DateTime? _isNotificationSince; // （前回の）通知を行った時刻

  // ───────── 通知初期化 ─────────
  Future<void> _initNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestAlertPermission: true,
    );
    await _notifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  // ───────── 姿勢悪化通知を送る ─────────
  Future<void> _notifyPoorPosture() async {
    const androidDetails = AndroidNotificationDetails(
      'posture_channel', // channelId
      '姿勢アラート', // channelName
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const detail = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      0, // 通知ID（同じなら上書き）
      '姿勢が崩れています',
      '背筋を伸ばしましょう！',
      detail,
    );
  }

  /// キャリブレーションを実行（現在値を基準に）
  Future<void> calibrate() async {
    debugPrint('PostureAnalyzer: calibrate() called');
    _baselinePitch = null; // 初期化
    final current = await AirPodsMotionService.attitude$().first;
    _baselinePitch = current.pitch as double?; // rad
    await _storage.savePitch(_baselinePitch!);
  }

  /// 保存済みキャリブレーションを読み込み。なければ false。
  Future<bool> loadCalibration() async {
    _baselinePitch = await _storage.loadPitch();
    return _baselinePitch != null;
  }

  /// 解析開始
  Future<void> start() async {
    debugPrint('PostureAnalyzer: start() called');
    if (_baselinePitch == null) {
      final ok = await loadCalibration();
      if (!ok) throw StateError('キャリブレーション未実施');
    }

    await _initNotifications(); // 通知初期化
    _sub ??= AirPodsMotionService.attitude$().listen(_onData);
  }

  /// 解析停止
  Future<void> dispose() async {
    await _sub?.cancel();
    await _stateCtl.close();
  }

  /// 内部状態をリセットするが、ストリームコントローラーはクローズしない
  Future<void> reset() async {
    await _sub?.cancel();
    _sub = null;
    _buffer.clear();
    _poorSince = null;
    _isNotificationSince = null;
  }

  // ──────────────────────────────────────────
  // センサ値ハンドラ
  void _onData(Attitude att) {
    // 移動平均用バッファ更新
    final now = DateTime.now();
    _buffer.add(att.pitch.toDouble());
    if (_buffer.length > maxBufferSize) {
      _buffer.removeRange(
        0,
        _buffer.length - maxBufferSize,
      ); // avgWindow時間分だけ保持
    }

    if (_buffer.isEmpty) {
      return; // バッファが空の場合は何もしない
    }
    final avgPitch = _buffer.reduce((a, b) => a + b) / _buffer.length;

    final diff = (_baselinePitch! - avgPitch); // 正姿勢より負方向に倒れれば diff > 0
    final overThreshold = diff > math.pi * thresholdDeg / 180; // rad へ変換

    // 状態遷移判定
    if (overThreshold) {
      _poorSince ??= now;
      if (now.difference(_poorSince!) >= confirmDuration) {
        _emit(PostureState.poor);

        // ★ 通知を送る条件を確認
        final needNotify =
            isNotificationEnabled &&
            (_isNotificationSince == null ||
                now.difference(_isNotificationSince!) >= notificationInterval);

        if (needNotify) {
          _isNotificationSince = now; // 次回までクールダウン開始
          unawaited(_notifyPoorPosture()); // 実際に通知を発火
        }
      }
    } else {
      _poorSince = null;
      _emit(PostureState.good);
    }
  }

  void _emit(PostureState s) {
    if (!_stateCtl.isClosed && (_stateCtl.hasListener)) {
      _stateCtl.add(s);
    }
  }
}

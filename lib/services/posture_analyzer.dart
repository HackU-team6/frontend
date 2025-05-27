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
  final int thresholdDeg;
  final Duration avgWindow;
  bool Function() shouldNotify;
  Duration Function() getConfirmDuration;
  Duration Function() getNotificationInterval;
  final _stateController = StreamController<PostureState>.broadcast();
  Stream<PostureState> get state$ => _stateController.stream;

  PostureAnalyzer({
    required this.thresholdDeg,// 姿勢悪化の閾値（度）
    required this.avgWindow, // 移動平均のウィンドウ時間
    required this.getConfirmDuration, // 姿勢悪化を確定するまでの時間
    required this.getNotificationInterval, // 通知のクールダウン時間
    required this.shouldNotify, // 通知を有効にするか
  }) {
    maxBufferSize =
        (avgWindow.inMilliseconds * 60 / 1000).ceil(); // AirPodsの更新頻度は約60Hz
  }

  void updateSettings({
    required bool Function() shouldNotify,
    required Duration Function() getConfirmDuration,
    required Duration Function() getNotificationInterval,
  }) {
    this.shouldNotify = shouldNotify;
    this.getConfirmDuration = getConfirmDuration;
    this.getNotificationInterval = getNotificationInterval;
    debugPrint('PostureAnalyzer: settings updated');
  }

  late final int maxBufferSize;
  StreamSubscription<PostureState>? _subscription;

  // キャリブレーション値を取得するゲッター
  double? get baselinePitch => _baselinePitch;

  final _storage = CalibrationStorage();
  double? _baselinePitch; // キャリブレーション値
  StreamSubscription<Attitude>? _sub;
  final _buffer = <double>[]; // 移動平均バッファ
  bool _isCooldown = false;

  /// 通知初期 ─────────
  Future<void> _initNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestAlertPermission: true,
    );
    await _notifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    // Androidチャンネルの作成
    const channel = AndroidNotificationChannel(
      'posture_channel',
      '姿勢通知',
      description: '姿勢が崩れたときの通知チャネル',
      importance: Importance.high,
    );
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // ───────── 姿勢悪化通知を送る ─────────
  Future<void> _notifyPoorPosture() async {
    if (!shouldNotify() || _isCooldown) {
      return; // 通知が無効な場合は何もしない
    }
    debugPrint('PostureAnalyzer: cooldown finished, sending notification');

    _isCooldown = true; // クールダウン開始

    // 通知詳細
    const androidDetails = AndroidNotificationDetails(
      'posture_channel',
      '姿勢通知',
      channelDescription: '姿勢が崩れたときの通知チャネル',
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

    await Future.delayed(getNotificationInterval()); // クールダウン時間待機
    _isCooldown = false; // クールダウン終了
  }

  /// キャリブレーションを実行（現在値を基準に）
  Future<void> calibrate() async {
    debugPrint('PostureAnalyzer: calibrate() called');
    debugPrint('PostureAnalyzer: waiting for calibration...');
    await Future.delayed(const Duration(seconds: 2)); // 少し待つ
    debugPrint('PostureAnalyzer: calibration started');
    _baselinePitch = null; // 初期化
    final current = await AirPodsMotionService.attitude$().first;
    _baselinePitch = current.pitch as double?; // rad
    await _storage.savePitch(_baselinePitch!);
    debugPrint('PostureAnalyzer: calibration completed with pitch: $_baselinePitch');
  }

  /// 保存済みキャリブレーションを読み込み。なければ false。
  Future<bool> loadCalibration() async {
    _baselinePitch = await _storage.loadPitch();
    return _baselinePitch != null;
  }

  /// 解析開始
  Future<void> start() async {
    debugPrint('PostureAnalyzer: start() called');
    // 通知プラグインを初期化
    await _initNotifications();
    if (_baselinePitch == null && !await loadCalibration()) {
      throw StateError('キャリブレーション未実施');
    }
    _listenSensor();
  }

  PostureState? lastEmittedState;
  void _listenSensor() {
    // cancel any existing subscription before starting new
    _subscription?.cancel();
    final sensorStream = AirPodsMotionService.attitude$().map((attitude) {
      // 移動平均用バッファ更新
      _buffer.add(attitude.pitch.toDouble());
      if (_buffer.length > maxBufferSize) {
        _buffer.removeRange(
          0,
          _buffer.length - maxBufferSize,
        ); // avgWindow時間分だけ保持
      }

      if (_buffer.isEmpty) {
        return PostureState.good; // バッファが空の場合は良い姿勢とみなす
      }
      final avgPitch = _buffer.reduce((a, b) => a + b) / _buffer.length;

      final diff = (_baselinePitch! - avgPitch); // 正姿勢より負方向に倒れれば diff > 0
      final overThreshold = diff > math.pi * thresholdDeg / 180; // rad へ変換

      // 状態遷移判定
      return overThreshold ? PostureState.poor : PostureState.good;
    });

    _subscription = sensorStream.listen((state) async {
      if (state == PostureState.poor){
        if (lastEmittedState != PostureState.poor) {
          await Future.delayed(getConfirmDuration());
          if(lastEmittedState != PostureState.poor) {
            _stateController.add(PostureState.poor); // 姿勢悪化状態を設定
            lastEmittedState = PostureState.poor; // 最後の状態を更新
            debugPrint('PostureAnalyzer: posture is poor now');
            if (shouldNotify()) {
              debugPrint('PostureAnalyzer: posture is poor now, notifying');
              await _notifyPoorPosture(); // 姿勢悪化通知を送る
            }
          }
        } else {
          if (!_isCooldown && shouldNotify()) {
            debugPrint(
                'PostureAnalyzer: posture is still poor, no notification sent');
            await _notifyPoorPosture(); // 姿勢悪化通知を送る
          }
        }
      } else {
        if(lastEmittedState == PostureState.poor) {
          _stateController.add(PostureState.good); // 良い姿勢状態を設定
          lastEmittedState = PostureState.good; // 最後の状態を更新
          debugPrint('PostureAnalyzer: posture is good now');
        }
      }
    });
  }

  void dispose() {
    debugPrint('PostureAnalyzer: dispose() called');
    _subscription?.cancel();
    _stateController.close();
  }

  /// 内部状態をリセットするが、ストリームコントローラーはクローズしない
  Future<void> reset() async {
    await _sub?.cancel();
    _sub = null;
    _buffer.clear();
  }
}

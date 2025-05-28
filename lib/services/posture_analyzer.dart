// lib/services/posture_analyzer.dart
//
// AirPods ピッチ値を用いた姿勢解析クラス。
// ──────────────────────────────────────────
import 'dart:async';
import 'dart:math' as math;
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
    this.avgWindow = const Duration(milliseconds: 500), // 判定ウィンドウ時間 0.5s
    this.confirmDuration = const Duration(seconds: 3), // 姿勢悪化を確定するまでの時間
    this.notificationInterval = const Duration(seconds: 10), // 通知のクールダウン時間
    this.isNotificationEnabled = true, // 通知を有効にするか
  }) {
    // AirPods の更新頻度は約 60 Hz
    maxBufferSize = (avgWindow.inMilliseconds * 60 / 1000).ceil();
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
  final _buffer = <double>[]; // バッファ（Hampel フィルター用）
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
    const detail = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifications.show(
      0, // 通知ID（同じなら上書き）
      '姿勢が崩れています',
      '背筋を伸ばしましょう！',
      detail,
    );
  }

  /// キャリブレーションを実行（現在値を基準に）
  Future<void> calibrate() async {
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
    // ① roll, pitch, yaw を取得（double 型に変換）
    final rawPitch = att.pitch.toDouble();
    final rawRoll  = att.roll.toDouble();
    final rawYaw   = att.yaw.toDouble();

    // ② roll が [-10.0, 0.2], yaw が [-1.85, -0.20] の範囲外なら pitch を 0.0 に置き換え
    final samplePitch = (rawRoll < -0.6 || rawRoll > 0.15 || rawYaw < -1.1 || rawYaw > 0.1)
        ? 0.0
        : rawPitch;

    final now = DateTime.now();

    // ③ 置き換え後の pitch をバッファに追加
    _buffer.add(samplePitch);
    if (_buffer.length > maxBufferSize) {
      // avgWindow 時間分だけ保持
      _buffer.removeRange(0, _buffer.length - maxBufferSize);
    }

    if (_buffer.isEmpty) return;

    // ★ Hampel フィルターで中央値を取得
    final smoothedPitch = _hampelSmooth(_buffer);

    final diff = (_baselinePitch! - smoothedPitch); // 正姿勢より負方向に倒れれば diff > 0
    final overThreshold = diff > math.pi * thresholdDeg / 180; // rad へ変換

    // 状態遷移判定
    if (overThreshold) {
      _poorSince ??= now;
      if (now.difference(_poorSince!) >= confirmDuration) {
        _emit(PostureState.poor);

        // ───── 通知条件判定 ─────
        final needNotify = isNotificationEnabled &&
            (_isNotificationSince == null ||
                now.difference(_isNotificationSince!) >= notificationInterval);

        if (needNotify) {
          _isNotificationSince = now; // クールダウン開始
          // ignore: discarded_futures
          _notifyPoorPosture();
        }
      }
    } else {
      _poorSince = null;
      _emit(PostureState.good);
    }
  }

  /// Hampel フィルターで外れ値を除去し、**中央値**を返す。
  ///   1. データの中央値 (median) と MAD を計算
  ///   2. k × 1.4826 × MAD を超える外れ値を中央値に置換
  ///   3. フィルタ後データの中央値を返却
  double _hampelSmooth(List<double> data, {double k = 3.0}) {
    if (0 == data.length) return 0.0;
    if (1 == data.length) return data.first;

    // ① 中央値の計算
    final sorted = List<double>.from(data)..sort();
    final median = sorted[sorted.length ~/ 2];

    // ② MAD の計算
    final deviations = data.map((v) => (v - median).abs()).toList();
    final sortedDev = List<double>.from(deviations)..sort();
    final mad = sortedDev[sortedDev.length ~/ 2];

    // ③ 外れ値しきい値 (Gaussian 補正 1.4826)
    final threshold = k * 1.4826 * (mad == 0 ? 1e-6 : mad);

    // ④ 外れ値を中央値に置換
    final filtered = data.map((v) => (v - median).abs() > threshold ? median : v).toList();

    // ⑤ フィルタ後の中央値を返す
    final filteredSorted = List<double>.from(filtered)..sort();
    return filteredSorted[filteredSorted.length ~/ 2];
  }

  void _emit(PostureState s) {
    if (!_stateCtl.isClosed && _stateCtl.hasListener) {
      _stateCtl.add(s);
    }
  }
}

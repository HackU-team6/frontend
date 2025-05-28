import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../exceptions/app_exceptions.dart';
import '../services/posture_analyzer.dart';
import '../services/notification_service.dart';
import 'notification_settings_provider.dart';

// 姿勢モニタリングの状態
class PostureMonitoringState {
  final PostureState postureState;
  final bool isMonitoring;
  final bool isCalibrated;
  final AppException? error;

  const PostureMonitoringState({
    this.postureState = PostureState.good,
    this.isMonitoring = false,
    this.isCalibrated = false,
    this.error,
  });

  PostureMonitoringState copyWith({
    PostureState? postureState,
    bool? isMonitoring,
    bool? isCalibrated,
    AppException? error,
    bool clearError = false,
  }) {
    return PostureMonitoringState(
      postureState: postureState ?? this.postureState,
      isMonitoring: isMonitoring ?? this.isMonitoring,
      isCalibrated: isCalibrated ?? this.isCalibrated,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// 姿勢モニタリングのNotifier
class PostureMonitoringNotifier extends StateNotifier<PostureMonitoringState> {
  final Ref ref;
  final PostureAnalyzer _analyzer;
  final NotificationService _notificationService;

  StreamSubscription<PostureState>? _postureSubscription;
  StreamSubscription<AppException>? _errorSubscription;
  Timer? _notificationTimer;

  PostureMonitoringNotifier(this.ref)
      : _analyzer = PostureAnalyzer(
    getConfirmDuration: () => Duration(
      seconds: ref.read(notificationSettingsProvider).delay.round(),
    ),
    getNotificationInterval: () => Duration(
      seconds: ref.read(notificationSettingsProvider).interval.round(),
    ),
  ),
        _notificationService = NotificationService(),
        super(const PostureMonitoringState()) {
    _init();
  }

  Future<void> _init() async {
    // 通知サービスの初期化
    try {
      await _notificationService.initialize();
    } catch (e) {
      state = state.copyWith(
        error: e is AppException ? e : AppException('通知の初期化に失敗しました: $e'),
      );
    }

    // キャリブレーション状態の確認
    final isCalibrated = await _analyzer.loadCalibration();
    state = state.copyWith(isCalibrated: isCalibrated);

    // エラーストリームの購読
    _errorSubscription = _analyzer.error$.listen((error) {
      state = state.copyWith(error: error);
    });

    // 姿勢状態ストリームの購読
    _postureSubscription = _analyzer.state$.listen((postureState) {
      state = state.copyWith(postureState: postureState);

      // 姿勢が悪化した場合の通知処理
      if (postureState == PostureState.poor) {
        _handlePoorPosture();
      } else {
        _notificationTimer?.cancel();
      }
    });
  }

  void _handlePoorPosture() {
    final settings = ref.read(notificationSettingsProvider);
    if (!settings.enableNotification) return;

    // 既存のタイマーをキャンセル
    _notificationTimer?.cancel();

    // 新しいタイマーを設定
    _notificationTimer = Timer.periodic(
      Duration(seconds: settings.interval.round()),
          (_) async {
        if (state.postureState == PostureState.poor) {
          await _notificationService.showPostureNotification();
        }
      },
    );

    // 初回通知
    _notificationService.showPostureNotification();
  }

  Future<void> calibrate() async {
    state = state.copyWith(clearError: true);

    try {
      await _analyzer.calibrate();
      state = state.copyWith(isCalibrated: true);
    } catch (e) {
      state = state.copyWith(
        error: e is AppException ? e : CalibrationFailedException(e.toString()),
      );
    }
  }

  Future<void> startMonitoring() async {
    if (state.isMonitoring) return;

    state = state.copyWith(clearError: true);

    try {
      // 通知権限の確認
      final hasPermission = await _notificationService.checkPermission();
      if (!hasPermission) {
        final granted = await _notificationService.requestPermission();
        if (!granted) {
          throw NotificationPermissionDeniedException();
        }
      }

      await _analyzer.start();
      state = state.copyWith(isMonitoring: true);
    } catch (e) {
      state = state.copyWith(
        error: e is AppException ? e : AppException('モニタリングの開始に失敗しました: $e'),
      );
    }
  }

  void stopMonitoring() {
    _analyzer.stop();
    _notificationTimer?.cancel();
    state = state.copyWith(
      isMonitoring: false,
      postureState: PostureState.good,
    );
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  @override
  void dispose() {
    _postureSubscription?.cancel();
    _errorSubscription?.cancel();
    _notificationTimer?.cancel();
    _analyzer.dispose();
    super.dispose();
  }
}

// Provider定義
final postureMonitoringProvider =
StateNotifierProvider<PostureMonitoringNotifier, PostureMonitoringState>(
      (ref) => PostureMonitoringNotifier(ref),
);
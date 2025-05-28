import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'nekoze_app.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // エラーハンドリングの設定
  if (kReleaseMode) {
    // 本番環境でのエラーハンドリング
    FlutterError.onError = (FlutterErrorDetails details) {
      // エラーログをサーバーに送信するなどの処理
      debugPrint('Flutter Error: ${details.exception}');
    };
  }

  // 通知サービスの初期化を試みる（失敗してもアプリは起動する）
  try {
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Failed to initialize notifications: $e');
  }

  runApp(
    const ProviderScope(
      child: NekozeApp(),
    ),
  );
}
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'monitoring_service.dart';
import '../../../firebase_options.dart';
import '../../shared/repositories/content_repository.dart'; // For OfflineModeException

class FirebaseMonitoringService implements MonitoringService {
  bool _isInitialized = false;

  static const bool monitoringEnabled = bool.fromEnvironment(
    'MONITORING_ENABLED',
    defaultValue: false,
  );

  @override
  Future<void> init() async {
    if (!monitoringEnabled) {
      debugPrint('[Monitoring] Monitoring disabled by MONITORING_ENABLED=false. Using MockMonitoringService.');
      _isInitialized = false;
      return;
    }

    // Release config guard checking
    if (DefaultFirebaseOptions.isDummyFirebaseConfig) {
      throw StateError(
        'MONITORING_ENABLED=true but Firebase config is still dummy. Please run flutterfire configure to set up real configuration.',
      );
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Enable collection post initialization
      await setCollectionEnabled(true);

      // Pass all uncaught errors from the framework to Crashlytics
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

      // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      _isInitialized = true;
      debugPrint('[Monitoring] Firebase Monitoring Service initialized successfully.');
    } catch (e) {
      _isInitialized = false;
      debugPrint('[Monitoring] Firebase init failed. Using MockMonitoringService. reason=$e');
    }
  }

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    if (!_isInitialized || !monitoringEnabled) {
      debugPrint('[Mock-Analytics] event: $name, parameters: $parameters');
      return;
    }
    try {
      await FirebaseAnalytics.instance.logEvent(name: name, parameters: parameters);
    } catch (e) {
      debugPrint('Error logging Firebase event: $e');
    }
  }

  @override
  Future<void> logError(dynamic error, StackTrace? stackTrace, {String? reason, bool fatal = false}) async {
    // Filter out expected errors to keep Crashlytics clean
    if (_isExpectedError(error)) {
      debugPrint('[Monitoring] Ignored expected error: $error');
      return;
    }

    if (!_isInitialized || !monitoringEnabled) {
      debugPrint('[Mock-Crashlytics] error: $error, reason: $reason, fatal: $fatal\n$stackTrace');
      return;
    }

    try {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: reason,
        fatal: fatal,
      );
    } catch (e) {
      debugPrint('Error logging Firebase crash: $e');
    }
  }

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    if (!monitoringEnabled) return;
    
    try {
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(enabled);
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(enabled);
      debugPrint('[Monitoring] Firebase collection enabled: $enabled');
    } catch (e) {
      debugPrint('Error setting collection state: $e');
    }
  }

  bool _isExpectedError(dynamic error) {
    if (error is OfflineModeException) {
      return true;
    }
    if (error is SocketException) {
      return true;
    }
    if (error is DioException) {
      final type = error.type;
      if (type == DioExceptionType.connectionTimeout ||
          type == DioExceptionType.sendTimeout ||
          type == DioExceptionType.receiveTimeout ||
          type == DioExceptionType.connectionError ||
          type == DioExceptionType.cancel) {
        return true;
      }
      // Typical expected validation 4xx client errors
      final response = error.response;
      if (response != null && response.statusCode != null && response.statusCode! < 500) {
        return true;
      }
    }
    return false;
  }
}

class MonitoringServiceFactory {
  static Future<MonitoringService> createAndInit() async {
    final service = FirebaseMonitoringService();
    await service.init();
    return service;
  }
}

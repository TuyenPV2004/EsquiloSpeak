abstract class MonitoringService {
  Future<void> init();
  Future<void> logEvent(String name, {Map<String, Object>? parameters});
  Future<void> logError(dynamic error, StackTrace? stackTrace, {String? reason, bool fatal = false});
  Future<void> setCollectionEnabled(bool enabled);
}

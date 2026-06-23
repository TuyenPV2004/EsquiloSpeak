import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'monitoring_service.dart';
import 'firebase_monitoring_service.dart';

final monitoringServiceProvider = Provider<MonitoringService>((ref) {
  // Return placeholder implementation. In main.dart, we override this with the initialized service.
  return FirebaseMonitoringService();
});

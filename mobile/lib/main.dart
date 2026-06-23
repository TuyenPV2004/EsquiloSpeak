import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/app/app.dart';
import 'src/core/monitoring/monitoring_provider.dart';
import 'src/core/monitoring/firebase_monitoring_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final monitoring = await MonitoringServiceFactory.createAndInit();
  await monitoring.logEvent('app_opened');

  runApp(
    ProviderScope(
      overrides: [
        monitoringServiceProvider.overrideWithValue(monitoring),
      ],
      child: const EsquiloSpeakApp(),
    ),
  );
}

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/src/core/network/api_client.dart';
import '../../core/monitoring/monitoring_service.dart';
import '../../core/monitoring/monitoring_provider.dart';
import 'package:mobile/src/shared/data/local/app_database.dart';
import 'package:mobile/src/shared/data/local/database_provider.dart';

class SyncRepository {
  final Dio _dio;
  final AppDatabase _db;
  final MonitoringService _monitoring;

  SyncRepository(this._dio, this._db, this._monitoring);

  Future<void> syncPendingAttempts() async {
    // 1. Fetch attempts with status PENDING or FAILED_RETRYABLE
    final pending = await (_db.select(_db.pendingAttempts)
          ..where((tbl) => tbl.status.equals('PENDING') | tbl.status.equals('FAILED_RETRYABLE')))
        .get();

    if (pending.isEmpty) return;

    final ids = pending.map((e) => e.id).toList();

    // 2. Mark as SYNCING in local DB inside a transaction
    await _db.transaction(() async {
      for (final id in ids) {
        await (_db.update(_db.pendingAttempts)..where((t) => t.id.equals(id)))
            .write(const PendingAttemptsCompanion(status: Value('SYNCING')));
      }
    });

    try {
      // 3. Construct JSON payload
      final attemptsJson = pending.map((e) => {
        'clientRequestId': e.clientRequestId,
        'deviceId': e.deviceId,
        'courseId': e.courseId,
        'sourceLanguage': e.sourceLanguage,
        'targetLanguage': e.targetLanguage,
        'lessonId': e.lessonId,
        'lessonVersionId': e.lessonVersionId,
        'questionId': e.questionId,
        'questionVersionId': e.questionVersionId,
        'selectedAnswer': e.selectedAnswer,
        'responseTimeMs': e.responseTimeMs,
        'usedHint': e.usedHint,
        'answeredAt': e.answeredAt.toIso8601String(),
      }).toList();

      final response = await _dio.post(
        '/api/v1/sync/attempts',
        data: {'attempts': attemptsJson},
      );

      final data = response.data;
      if (data != null && data['success'] == true) {
        final results = data['results'] as List<dynamic>;
        
        await _db.transaction(() async {
          for (final result in results) {
            final clientReqId = result['clientRequestId'] as String;
            final status = result['status'] as String;
            final errorCode = result['errorCode'] as String?;
            final message = result['message'] as String?;

            if (status == 'SYNCED' || status == 'DUPLICATE') {
              // Delete successfully synced attempts
              await (_db.delete(_db.pendingAttempts)
                    ..where((t) => t.clientRequestId.equals(clientReqId)))
                  .go();
            } else if (status == 'FAILED') {
              // Mark as FAILED_PERMANENT
              await (_db.update(_db.pendingAttempts)
                    ..where((t) => t.clientRequestId.equals(clientReqId)))
                  .write(PendingAttemptsCompanion(
                    status: const Value('FAILED_PERMANENT'),
                    lastError: Value('$errorCode: $message'),
                    lastTriedAt: Value(DateTime.now()),
                  ));
            }
          }
        });

        // Log sync_completed event
        final successCount = results.where((r) => r['status'] == 'SYNCED' || r['status'] == 'DUPLICATE').length;
        final failedPermanentCount = results.where((r) => r['status'] == 'FAILED').length;
        _monitoring.logEvent(
          'sync_completed',
          parameters: {
            'attempts_count': pending.length,
            'success_count': successCount,
            'failed_retryable_count': 0,
            'failed_permanent_count': failedPermanentCount,
          },
        );
      } else {
        // Fallback: Revert to FAILED_RETRYABLE
        await _revertSyncingToRetryable(ids, 'Server returned success=false');
        _monitoring.logEvent(
          'sync_completed',
          parameters: {
            'attempts_count': pending.length,
            'success_count': 0,
            'failed_retryable_count': pending.length,
            'failed_permanent_count': 0,
          },
        );
      }
    } on DioException catch (de) {
      String errMsg = de.message ?? 'Unknown network error';
      final isTransient = de.type == DioExceptionType.connectionTimeout ||
          de.type == DioExceptionType.sendTimeout ||
          de.type == DioExceptionType.receiveTimeout ||
          de.type == DioExceptionType.connectionError ||
          (de.response != null && de.response!.statusCode != null && de.response!.statusCode! >= 500);

      if (isTransient) {
        await _revertSyncingToRetryable(ids, errMsg);
        _monitoring.logEvent(
          'sync_completed',
          parameters: {
            'attempts_count': pending.length,
            'success_count': 0,
            'failed_retryable_count': pending.length,
            'failed_permanent_count': 0,
          },
        );
      } else {
        // 4xx or other permanent error on the whole batch, mark all as FAILED_PERMANENT
        await _db.transaction(() async {
          for (final id in ids) {
            await (_db.update(_db.pendingAttempts)..where((t) => t.id.equals(id)))
                .write(PendingAttemptsCompanion(
                  status: const Value('FAILED_PERMANENT'),
                  lastError: Value(errMsg),
                  lastTriedAt: Value(DateTime.now()),
                ));
          }
        });
        _monitoring.logEvent(
          'sync_completed',
          parameters: {
            'attempts_count': pending.length,
            'success_count': 0,
            'failed_retryable_count': 0,
            'failed_permanent_count': pending.length,
          },
        );
      }
    } catch (e) {
      await _revertSyncingToRetryable(ids, e.toString());
      _monitoring.logEvent(
        'sync_completed',
        parameters: {
          'attempts_count': pending.length,
          'success_count': 0,
          'failed_retryable_count': pending.length,
          'failed_permanent_count': 0,
        },
      );
    }
  }

  Future<void> _revertSyncingToRetryable(List<int> ids, String error) async {
    await _db.transaction(() async {
      for (final id in ids) {
        final existing = await (_db.select(_db.pendingAttempts)..where((t) => t.id.equals(id))).getSingleOrNull();
        if (existing != null && existing.status == 'SYNCING') {
          final newRetryCount = existing.retryCount + 1;
          await (_db.update(_db.pendingAttempts)..where((t) => t.id.equals(id)))
              .write(PendingAttemptsCompanion(
                status: const Value('FAILED_RETRYABLE'),
                retryCount: Value(newRetryCount),
                lastError: Value(error),
                lastTriedAt: Value(DateTime.now()),
              ));
        }
      }
    });
  }

  Stream<int> watchPendingCount() {
    return (_db.select(_db.pendingAttempts)
          ..where((tbl) => tbl.status.equals('PENDING') | tbl.status.equals('FAILED_RETRYABLE')))
        .watch()
        .map((list) => list.length);
  }
}

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  final db = ref.watch(databaseProvider);
  final monitoring = ref.watch(monitoringServiceProvider);
  return SyncRepository(dio, db, monitoring);
});

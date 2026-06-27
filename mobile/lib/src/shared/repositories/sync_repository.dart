import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/src/core/network/api_client.dart';
import '../../core/monitoring/monitoring_service.dart';
import '../../core/monitoring/monitoring_provider.dart';
import 'package:mobile/src/shared/data/local/app_database.dart';
import 'package:mobile/src/shared/data/local/database_provider.dart';
import '../../core/network/network_error_helper.dart';
import '../network/api_error_parser.dart';

class SyncAuthRequiredException implements Exception {
  final String message;
  SyncAuthRequiredException([this.message = 'Phiên làm việc đã hết hạn. Vui lòng đăng nhập lại.']);

  @override
  String toString() => message;
}

class SyncRepository {
  final Dio _dio;
  final AppDatabase _db;
  final MonitoringService _monitoring;

  bool _isSyncing = false;

  SyncRepository(this._dio, this._db, this._monitoring);

  Future<void> recoverSyncingAttempts() async {
    await (_db.update(_db.pendingAttempts)..where((t) => t.status.equals('SYNCING')))
        .write(const PendingAttemptsCompanion(status: Value('PENDING')));
  }

  Future<void> syncPendingLessons() async {
    try {
      final pendingLessons = await (_db.select(_db.cachedLessons)
            ..where((tbl) => tbl.status.equals('completed') & tbl.syncStatus.equals('PENDING')))
          .get();

      for (final lesson in pendingLessons) {
        // Defer complete request if there are pending/failed attempts for this lesson (excluding FAILED_PERMANENT)
        final attemptsForLesson = await (_db.select(_db.pendingAttempts)
              ..where((tbl) => tbl.lessonId.equals(lesson.lessonId) &
                              (tbl.status.equals('PENDING') |
                               tbl.status.equals('FAILED_RETRYABLE') |
                               tbl.status.equals('SYNCING'))))
            .get();

        if (attemptsForLesson.isNotEmpty) {
          _monitoring.logEvent('sync_lesson_deferred_pending_attempts', parameters: {
            'lessonId': lesson.lessonId,
            'attemptsCount': attemptsForLesson.length,
          });
          continue;
        }

        try {
          await _dio.post('/api/v1/courses/${lesson.courseId}/lessons/${lesson.lessonId}/complete');
          await (_db.update(_db.cachedLessons)
                ..where((t) => t.courseId.equals(lesson.courseId) & t.lessonId.equals(lesson.lessonId)))
              .write(const CachedLessonsCompanion(syncStatus: Value('SYNCED')));
        } on DioException catch (de) {
          final statusCode = de.response?.statusCode;
          final errorCode = ApiErrorParser.extractErrorCode(de.response?.data);

          if (statusCode == 409 && errorCode == 'LESSON_ALREADY_COMPLETED') {
            await (_db.update(_db.cachedLessons)
                  ..where((t) => t.courseId.equals(lesson.courseId) & t.lessonId.equals(lesson.lessonId)))
                .write(const CachedLessonsCompanion(syncStatus: Value('SYNCED')));
          } else if (statusCode == 422) {
            // Revert lesson status to 'available' and mark syncStatus as 'SYNCED'
            // NOTE: Tạm revert về 'available' cho MVP do bài học đã từng được mở. 
            // Khi có logic locked/unlocked phức tạp hơn, cần tái tính toán lại trạng thái.
            await (_db.update(_db.cachedLessons)
                  ..where((t) => t.courseId.equals(lesson.courseId) & t.lessonId.equals(lesson.lessonId)))
                .write(const CachedLessonsCompanion(status: Value('available'), syncStatus: Value('SYNCED')));

            _monitoring.logEvent('sync_lesson_failed_incomplete', parameters: {
              'lessonId': lesson.lessonId,
              'statusCode': statusCode ?? -1,
              'error': de.message ?? 'No message',
            });
          } else if (statusCode == 401 || statusCode == 403) {
            _monitoring.logEvent('sync_lesson_failed_auth', parameters: {
              'lessonId': lesson.lessonId,
              'statusCode': statusCode ?? -1,
            });
            throw SyncAuthRequiredException();
          } else if (isTransientNetworkException(de)) {
            _monitoring.logEvent('sync_lesson_failed_transient', parameters: {
              'lessonId': lesson.lessonId,
              'statusCode': statusCode ?? -1,
              'error': de.message ?? 'No message',
            });
          } else {
            _monitoring.logEvent('sync_lesson_failed_permanent', parameters: {
              'lessonId': lesson.lessonId,
              'statusCode': statusCode ?? -1,
              'error': de.message ?? 'No message',
            });
          }
        } catch (e) {
          if (isTransientNetworkException(e)) {
            _monitoring.logEvent('sync_lesson_failed_transient', parameters: {
              'lessonId': lesson.lessonId,
              'error': e.toString(),
            });
          } else {
            _monitoring.logEvent('sync_lesson_failed_permanent', parameters: {
              'lessonId': lesson.lessonId,
              'error': e.toString(),
            });
          }
        }
      }
    } on SyncAuthRequiredException {
      _monitoring.logEvent('sync_lessons_auth_required_aborted');
      rethrow;
    } catch (e) {
      _monitoring.logEvent('sync_lessons_failed', parameters: {
        'error': e.toString(),
      });
    }
  }

  Future<void> syncPendingAttempts() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      // Khôi phục các attempts bị kẹt SYNCING
      await recoverSyncingAttempts();

      // 1. Fetch attempts with status PENDING or FAILED_RETRYABLE
      final pending = await (_db.select(_db.pendingAttempts)
            ..where((tbl) => tbl.status.equals('PENDING') | tbl.status.equals('FAILED_RETRYABLE')))
          .get();

      // Lọc in-memory chỉ đồng bộ các attempts thỏa mãn backoff delay và chưa quá 5 lần retry
      final eligiblePending = pending.where((e) {
        if (e.status == 'PENDING') return true;
        if (e.retryCount >= 5) return false;
        if (e.lastTriedAt == null) return true;
        final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));
        return e.lastTriedAt!.isBefore(fiveMinutesAgo);
      }).toList();

      if (eligiblePending.isNotEmpty) {
        final ids = eligiblePending.map((e) => e.id).toList();

        // 2. Mark as SYNCING in local DB inside a transaction
        await _db.transaction(() async {
          for (final id in ids) {
            await (_db.update(_db.pendingAttempts)..where((t) => t.id.equals(id)))
                .write(const PendingAttemptsCompanion(status: Value('SYNCING')));
          }
        });

        try {
          // 3. Construct JSON payload
          final attemptsJson = eligiblePending.map((e) => {
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
            
            // Map lookup nhanh để tránh crash firstWhere
            final attemptsByClientRequestId = {
              for (final attempt in eligiblePending) attempt.clientRequestId: attempt,
            };
            
            await _db.transaction(() async {
              for (final result in results) {
                final clientReqId = result['clientRequestId'] as String;
                final status = result['status'] as String;
                final errorCode = result['errorCode'] as String?;
                final message = result['message'] as String?;
                final attempt = attemptsByClientRequestId[clientReqId];

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
                  
                  if (errorCode == 'STALE_CONTENT' && attempt != null) {
                    await _db.invalidateLessonCache(
                      courseId: attempt.courseId,
                      lessonId: attempt.lessonId,
                    );
                  }
                } else if (status == 'RETRYABLE_FAILED') {
                  final currentRetryCount = attempt?.retryCount ?? 0;
                  final newRetryCount = currentRetryCount + 1;

                  // Log monitoring event
                  await _monitoring.logEvent('sync_attempt_retryable_failed', parameters: {
                    'clientRequestId': clientReqId,
                    'retryCount': newRetryCount,
                    'errorCode': errorCode ?? 'unknown',
                  });

                  await (_db.update(_db.pendingAttempts)
                        ..where((t) => t.clientRequestId.equals(clientReqId)))
                      .write(PendingAttemptsCompanion(
                        status: Value(newRetryCount >= 5 ? 'FAILED_PERMANENT' : 'FAILED_RETRYABLE'),
                        retryCount: Value(newRetryCount),
                        lastError: Value('$errorCode: $message'),
                        lastTriedAt: Value(DateTime.now()),
                      ));
                }
              }
            });

            // Log sync_completed event
            final successCount = results.where((r) => r['status'] == 'SYNCED' || r['status'] == 'DUPLICATE').length;
            final failedPermanentCount = results.where((r) => r['status'] == 'FAILED').length;
            final failedRetryableCount = results.where((r) => r['status'] == 'RETRYABLE_FAILED').length;
            
            _monitoring.logEvent(
              'sync_completed',
              parameters: {
                'attempts_count': eligiblePending.length,
                'success_count': successCount,
                'failed_retryable_count': failedRetryableCount,
                'failed_permanent_count': failedPermanentCount,
              },
            );
          } else {
            // Fallback: Revert to FAILED_RETRYABLE (hoặc FAILED_PERMANENT nếu quá số lần)
            await _revertSyncingToRetryable(ids, 'Server returned success=false');
            _monitoring.logEvent(
              'sync_completed',
              parameters: {
                'attempts_count': eligiblePending.length,
                'success_count': 0,
                'failed_retryable_count': eligiblePending.length,
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
                'attempts_count': eligiblePending.length,
                'success_count': 0,
                'failed_retryable_count': eligiblePending.length,
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
                'attempts_count': eligiblePending.length,
                'success_count': 0,
                'failed_retryable_count': 0,
                'failed_permanent_count': eligiblePending.length,
              },
            );
          }
        } catch (e) {
          await _revertSyncingToRetryable(ids, e.toString());
          _monitoring.logEvent(
            'sync_completed',
            parameters: {
              'attempts_count': eligiblePending.length,
              'success_count': 0,
              'failed_retryable_count': eligiblePending.length,
              'failed_permanent_count': 0,
            },
          );
        }
      }

      // Sync pending completed lessons AFTER attempts sync is done
      await syncPendingLessons();

    } finally {
      _isSyncing = false;
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
                status: Value(newRetryCount >= 5 ? 'FAILED_PERMANENT' : 'FAILED_RETRYABLE'),
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

  Stream<int> watchFailedPermanentCount() {
    return (_db.select(_db.pendingAttempts)
          ..where((tbl) => tbl.status.equals('FAILED_PERMANENT')))
        .watch()
        .map((list) => list.length);
  }

  Future<void> resetFailedPermanentAttempts() async {
    await _db.transaction(() async {
      await (_db.update(_db.pendingAttempts)
            ..where((t) => t.status.equals('FAILED_PERMANENT')))
          .write(const PendingAttemptsCompanion(
            status: Value('PENDING'),
            retryCount: Value(0),
            lastError: Value<String?>(null),
            lastTriedAt: Value<DateTime?>(null),
          ));
    });
  }

  Future<void> discardFailedPermanentAttempts() async {
    await _db.transaction(() async {
      await (_db.delete(_db.pendingAttempts)
            ..where((t) => t.status.equals('FAILED_PERMANENT')))
          .go();
    });
  }
}

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  final db = ref.watch(databaseProvider);
  final monitoring = ref.watch(monitoringServiceProvider);
  return SyncRepository(dio, db, monitoring);
});

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

class CachedCourses extends Table {
  TextColumn get courseId => text().withLength(min: 1, max: 50)();
  TextColumn get title => text()();
  TextColumn get sourceLanguage => text()();
  TextColumn get targetLanguage => text()();
  TextColumn get level => text()();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {courseId};
}

class CachedLessons extends Table {
  TextColumn get lessonId => text().withLength(min: 1, max: 50)();
  TextColumn get courseId => text().withLength(min: 1, max: 50)();
  TextColumn get title => text()();
  TextColumn get status => text()();
  TextColumn get syncStatus => text().withDefault(const Constant('SYNCED'))();
  TextColumn get lessonVersionId => text().nullable()();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {lessonId};
}

class CachedQuestions extends Table {
  TextColumn get questionId => text().withLength(min: 1, max: 50)();
  TextColumn get lessonId => text().withLength(min: 1, max: 50)();
  TextColumn get prompt => text()();
  TextColumn get type => text()();
  TextColumn get audioUrl => text().nullable()();
  TextColumn get correctAnswer => text()();
  TextColumn get explanation => text()();
  TextColumn get questionVersionId => text()();
  DateTimeColumn get cachedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {questionId};
}

class CachedQuestionOptions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get questionId => text().withLength(min: 1, max: 50)();
  IntColumn get optionId => integer()();
  TextColumn get optionText => text()();
}

class PendingAttempts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get clientRequestId => text().unique()();
  TextColumn get deviceId => text()();
  TextColumn get courseId => text()();
  TextColumn get sourceLanguage => text()();
  TextColumn get targetLanguage => text()();
  TextColumn get lessonId => text()();
  TextColumn get lessonVersionId => text()();
  TextColumn get questionId => text()();
  TextColumn get questionVersionId => text()();
  TextColumn get selectedAnswer => text()();
  IntColumn get responseTimeMs => integer()();
  BoolColumn get usedHint => boolean()();
  BoolColumn get isCorrectLocal => boolean()();
  DateTimeColumn get answeredAt => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get status => text().withDefault(const Constant('PENDING'))(); // PENDING, SYNCING, FAILED_RETRYABLE, FAILED_PERMANENT
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get lastTriedAt => dateTime().nullable()();
}

@DriftDatabase(tables: [
  CachedCourses,
  CachedLessons,
  CachedQuestions,
  CachedQuestionOptions,
  PendingAttempts,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(cachedLessons, cachedLessons.syncStatus);
          }
          if (from < 3) {
            await m.addColumn(cachedLessons, cachedLessons.lessonVersionId);
          }
        },
      );

  // Caching Lesson Details in transaction
  Future<void> cacheLessonDetails({
    required String lessonId,
    required List<CachedQuestionsCompanion> questions,
    required List<CachedQuestionOptionsCompanion> options,
  }) async {
    await transaction(() async {
      // 1. Delete existing cached questions and options for this lesson
      final existingQuestions = await (select(cachedQuestions)
            ..where((tbl) => tbl.lessonId.equals(lessonId)))
          .get();
      
      for (final q in existingQuestions) {
        await (delete(cachedQuestionOptions)
              ..where((tbl) => tbl.questionId.equals(q.questionId)))
            .go();
      }
      
      await (delete(cachedQuestions)
            ..where((tbl) => tbl.lessonId.equals(lessonId)))
          .go();

      // 2. Insert new questions and options
      for (final q in questions) {
        await into(cachedQuestions).insertOnConflictUpdate(q);
      }
      for (final opt in options) {
        await into(cachedQuestionOptions).insertOnConflictUpdate(opt);
      }
    });
  }

  // Safely invalidate cached questions/options by verifying the courseId and lessonId pair
  Future<void> invalidateLessonCache({
    required String courseId,
    required String lessonId,
  }) async {
    await transaction(() async {
      // 1. Xác thực cặp khóa an toàn từ bảng cachedLessons trước
      final lessonExists = await (select(cachedLessons)
            ..where((tbl) => tbl.courseId.equals(courseId) & tbl.lessonId.equals(lessonId)))
          .getSingleOrNull();
      
      if (lessonExists == null) {
        return; // Không tồn tại bài học phù hợp với courseId + lessonId -> không xóa cache
      }

      // 2. Tiến hành xóa questions và question options (lessonId/questionId globally unique)
      final existingQuestions = await (select(cachedQuestions)
            ..where((tbl) => tbl.lessonId.equals(lessonId)))
          .get();
      
      for (final q in existingQuestions) {
        await (delete(cachedQuestionOptions)
              ..where((tbl) => tbl.questionId.equals(q.questionId)))
            .go();
      }
      
      await (delete(cachedQuestions)
            ..where((tbl) => tbl.lessonId.equals(lessonId)))
          .go();
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'esquilospeak.db'));
    return NativeDatabase.createInBackground(file);
  });
}

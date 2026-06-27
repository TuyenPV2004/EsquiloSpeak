// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CachedCoursesTable extends CachedCourses
    with TableInfo<$CachedCoursesTable, CachedCourse> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedCoursesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _courseIdMeta = const VerificationMeta(
    'courseId',
  );
  @override
  late final GeneratedColumn<String> courseId = GeneratedColumn<String>(
    'course_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceLanguageMeta = const VerificationMeta(
    'sourceLanguage',
  );
  @override
  late final GeneratedColumn<String> sourceLanguage = GeneratedColumn<String>(
    'source_language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetLanguageMeta = const VerificationMeta(
    'targetLanguage',
  );
  @override
  late final GeneratedColumn<String> targetLanguage = GeneratedColumn<String>(
    'target_language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<String> level = GeneratedColumn<String>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    courseId,
    title,
    sourceLanguage,
    targetLanguage,
    level,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_courses';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedCourse> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('course_id')) {
      context.handle(
        _courseIdMeta,
        courseId.isAcceptableOrUnknown(data['course_id']!, _courseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_courseIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('source_language')) {
      context.handle(
        _sourceLanguageMeta,
        sourceLanguage.isAcceptableOrUnknown(
          data['source_language']!,
          _sourceLanguageMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceLanguageMeta);
    }
    if (data.containsKey('target_language')) {
      context.handle(
        _targetLanguageMeta,
        targetLanguage.isAcceptableOrUnknown(
          data['target_language']!,
          _targetLanguageMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetLanguageMeta);
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    } else if (isInserting) {
      context.missing(_levelMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {courseId};
  @override
  CachedCourse map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedCourse(
      courseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}course_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      sourceLanguage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_language'],
      )!,
      targetLanguage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_language'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}level'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedCoursesTable createAlias(String alias) {
    return $CachedCoursesTable(attachedDatabase, alias);
  }
}

class CachedCourse extends DataClass implements Insertable<CachedCourse> {
  final String courseId;
  final String title;
  final String sourceLanguage;
  final String targetLanguage;
  final String level;
  final DateTime cachedAt;
  const CachedCourse({
    required this.courseId,
    required this.title,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.level,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['course_id'] = Variable<String>(courseId);
    map['title'] = Variable<String>(title);
    map['source_language'] = Variable<String>(sourceLanguage);
    map['target_language'] = Variable<String>(targetLanguage);
    map['level'] = Variable<String>(level);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedCoursesCompanion toCompanion(bool nullToAbsent) {
    return CachedCoursesCompanion(
      courseId: Value(courseId),
      title: Value(title),
      sourceLanguage: Value(sourceLanguage),
      targetLanguage: Value(targetLanguage),
      level: Value(level),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedCourse.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedCourse(
      courseId: serializer.fromJson<String>(json['courseId']),
      title: serializer.fromJson<String>(json['title']),
      sourceLanguage: serializer.fromJson<String>(json['sourceLanguage']),
      targetLanguage: serializer.fromJson<String>(json['targetLanguage']),
      level: serializer.fromJson<String>(json['level']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'courseId': serializer.toJson<String>(courseId),
      'title': serializer.toJson<String>(title),
      'sourceLanguage': serializer.toJson<String>(sourceLanguage),
      'targetLanguage': serializer.toJson<String>(targetLanguage),
      'level': serializer.toJson<String>(level),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedCourse copyWith({
    String? courseId,
    String? title,
    String? sourceLanguage,
    String? targetLanguage,
    String? level,
    DateTime? cachedAt,
  }) => CachedCourse(
    courseId: courseId ?? this.courseId,
    title: title ?? this.title,
    sourceLanguage: sourceLanguage ?? this.sourceLanguage,
    targetLanguage: targetLanguage ?? this.targetLanguage,
    level: level ?? this.level,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedCourse copyWithCompanion(CachedCoursesCompanion data) {
    return CachedCourse(
      courseId: data.courseId.present ? data.courseId.value : this.courseId,
      title: data.title.present ? data.title.value : this.title,
      sourceLanguage: data.sourceLanguage.present
          ? data.sourceLanguage.value
          : this.sourceLanguage,
      targetLanguage: data.targetLanguage.present
          ? data.targetLanguage.value
          : this.targetLanguage,
      level: data.level.present ? data.level.value : this.level,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedCourse(')
          ..write('courseId: $courseId, ')
          ..write('title: $title, ')
          ..write('sourceLanguage: $sourceLanguage, ')
          ..write('targetLanguage: $targetLanguage, ')
          ..write('level: $level, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    courseId,
    title,
    sourceLanguage,
    targetLanguage,
    level,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedCourse &&
          other.courseId == this.courseId &&
          other.title == this.title &&
          other.sourceLanguage == this.sourceLanguage &&
          other.targetLanguage == this.targetLanguage &&
          other.level == this.level &&
          other.cachedAt == this.cachedAt);
}

class CachedCoursesCompanion extends UpdateCompanion<CachedCourse> {
  final Value<String> courseId;
  final Value<String> title;
  final Value<String> sourceLanguage;
  final Value<String> targetLanguage;
  final Value<String> level;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedCoursesCompanion({
    this.courseId = const Value.absent(),
    this.title = const Value.absent(),
    this.sourceLanguage = const Value.absent(),
    this.targetLanguage = const Value.absent(),
    this.level = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedCoursesCompanion.insert({
    required String courseId,
    required String title,
    required String sourceLanguage,
    required String targetLanguage,
    required String level,
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : courseId = Value(courseId),
       title = Value(title),
       sourceLanguage = Value(sourceLanguage),
       targetLanguage = Value(targetLanguage),
       level = Value(level);
  static Insertable<CachedCourse> custom({
    Expression<String>? courseId,
    Expression<String>? title,
    Expression<String>? sourceLanguage,
    Expression<String>? targetLanguage,
    Expression<String>? level,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (courseId != null) 'course_id': courseId,
      if (title != null) 'title': title,
      if (sourceLanguage != null) 'source_language': sourceLanguage,
      if (targetLanguage != null) 'target_language': targetLanguage,
      if (level != null) 'level': level,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedCoursesCompanion copyWith({
    Value<String>? courseId,
    Value<String>? title,
    Value<String>? sourceLanguage,
    Value<String>? targetLanguage,
    Value<String>? level,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return CachedCoursesCompanion(
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      level: level ?? this.level,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (courseId.present) {
      map['course_id'] = Variable<String>(courseId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (sourceLanguage.present) {
      map['source_language'] = Variable<String>(sourceLanguage.value);
    }
    if (targetLanguage.present) {
      map['target_language'] = Variable<String>(targetLanguage.value);
    }
    if (level.present) {
      map['level'] = Variable<String>(level.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedCoursesCompanion(')
          ..write('courseId: $courseId, ')
          ..write('title: $title, ')
          ..write('sourceLanguage: $sourceLanguage, ')
          ..write('targetLanguage: $targetLanguage, ')
          ..write('level: $level, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedLessonsTable extends CachedLessons
    with TableInfo<$CachedLessonsTable, CachedLesson> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedLessonsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _lessonIdMeta = const VerificationMeta(
    'lessonId',
  );
  @override
  late final GeneratedColumn<String> lessonId = GeneratedColumn<String>(
    'lesson_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _courseIdMeta = const VerificationMeta(
    'courseId',
  );
  @override
  late final GeneratedColumn<String> courseId = GeneratedColumn<String>(
    'course_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('SYNCED'),
  );
  static const VerificationMeta _lessonVersionIdMeta = const VerificationMeta(
    'lessonVersionId',
  );
  @override
  late final GeneratedColumn<String> lessonVersionId = GeneratedColumn<String>(
    'lesson_version_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    lessonId,
    courseId,
    title,
    status,
    syncStatus,
    lessonVersionId,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_lessons';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedLesson> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('lesson_id')) {
      context.handle(
        _lessonIdMeta,
        lessonId.isAcceptableOrUnknown(data['lesson_id']!, _lessonIdMeta),
      );
    } else if (isInserting) {
      context.missing(_lessonIdMeta);
    }
    if (data.containsKey('course_id')) {
      context.handle(
        _courseIdMeta,
        courseId.isAcceptableOrUnknown(data['course_id']!, _courseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_courseIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('lesson_version_id')) {
      context.handle(
        _lessonVersionIdMeta,
        lessonVersionId.isAcceptableOrUnknown(
          data['lesson_version_id']!,
          _lessonVersionIdMeta,
        ),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {lessonId};
  @override
  CachedLesson map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedLesson(
      lessonId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lesson_id'],
      )!,
      courseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}course_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      lessonVersionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lesson_version_id'],
      ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedLessonsTable createAlias(String alias) {
    return $CachedLessonsTable(attachedDatabase, alias);
  }
}

class CachedLesson extends DataClass implements Insertable<CachedLesson> {
  final String lessonId;
  final String courseId;
  final String title;
  final String status;
  final String syncStatus;
  final String? lessonVersionId;
  final DateTime cachedAt;
  const CachedLesson({
    required this.lessonId,
    required this.courseId,
    required this.title,
    required this.status,
    required this.syncStatus,
    this.lessonVersionId,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['lesson_id'] = Variable<String>(lessonId);
    map['course_id'] = Variable<String>(courseId);
    map['title'] = Variable<String>(title);
    map['status'] = Variable<String>(status);
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || lessonVersionId != null) {
      map['lesson_version_id'] = Variable<String>(lessonVersionId);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedLessonsCompanion toCompanion(bool nullToAbsent) {
    return CachedLessonsCompanion(
      lessonId: Value(lessonId),
      courseId: Value(courseId),
      title: Value(title),
      status: Value(status),
      syncStatus: Value(syncStatus),
      lessonVersionId: lessonVersionId == null && nullToAbsent
          ? const Value.absent()
          : Value(lessonVersionId),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedLesson.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedLesson(
      lessonId: serializer.fromJson<String>(json['lessonId']),
      courseId: serializer.fromJson<String>(json['courseId']),
      title: serializer.fromJson<String>(json['title']),
      status: serializer.fromJson<String>(json['status']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      lessonVersionId: serializer.fromJson<String?>(json['lessonVersionId']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'lessonId': serializer.toJson<String>(lessonId),
      'courseId': serializer.toJson<String>(courseId),
      'title': serializer.toJson<String>(title),
      'status': serializer.toJson<String>(status),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'lessonVersionId': serializer.toJson<String?>(lessonVersionId),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedLesson copyWith({
    String? lessonId,
    String? courseId,
    String? title,
    String? status,
    String? syncStatus,
    Value<String?> lessonVersionId = const Value.absent(),
    DateTime? cachedAt,
  }) => CachedLesson(
    lessonId: lessonId ?? this.lessonId,
    courseId: courseId ?? this.courseId,
    title: title ?? this.title,
    status: status ?? this.status,
    syncStatus: syncStatus ?? this.syncStatus,
    lessonVersionId: lessonVersionId.present
        ? lessonVersionId.value
        : this.lessonVersionId,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedLesson copyWithCompanion(CachedLessonsCompanion data) {
    return CachedLesson(
      lessonId: data.lessonId.present ? data.lessonId.value : this.lessonId,
      courseId: data.courseId.present ? data.courseId.value : this.courseId,
      title: data.title.present ? data.title.value : this.title,
      status: data.status.present ? data.status.value : this.status,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      lessonVersionId: data.lessonVersionId.present
          ? data.lessonVersionId.value
          : this.lessonVersionId,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedLesson(')
          ..write('lessonId: $lessonId, ')
          ..write('courseId: $courseId, ')
          ..write('title: $title, ')
          ..write('status: $status, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lessonVersionId: $lessonVersionId, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    lessonId,
    courseId,
    title,
    status,
    syncStatus,
    lessonVersionId,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedLesson &&
          other.lessonId == this.lessonId &&
          other.courseId == this.courseId &&
          other.title == this.title &&
          other.status == this.status &&
          other.syncStatus == this.syncStatus &&
          other.lessonVersionId == this.lessonVersionId &&
          other.cachedAt == this.cachedAt);
}

class CachedLessonsCompanion extends UpdateCompanion<CachedLesson> {
  final Value<String> lessonId;
  final Value<String> courseId;
  final Value<String> title;
  final Value<String> status;
  final Value<String> syncStatus;
  final Value<String?> lessonVersionId;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedLessonsCompanion({
    this.lessonId = const Value.absent(),
    this.courseId = const Value.absent(),
    this.title = const Value.absent(),
    this.status = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.lessonVersionId = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedLessonsCompanion.insert({
    required String lessonId,
    required String courseId,
    required String title,
    required String status,
    this.syncStatus = const Value.absent(),
    this.lessonVersionId = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : lessonId = Value(lessonId),
       courseId = Value(courseId),
       title = Value(title),
       status = Value(status);
  static Insertable<CachedLesson> custom({
    Expression<String>? lessonId,
    Expression<String>? courseId,
    Expression<String>? title,
    Expression<String>? status,
    Expression<String>? syncStatus,
    Expression<String>? lessonVersionId,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (lessonId != null) 'lesson_id': lessonId,
      if (courseId != null) 'course_id': courseId,
      if (title != null) 'title': title,
      if (status != null) 'status': status,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (lessonVersionId != null) 'lesson_version_id': lessonVersionId,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedLessonsCompanion copyWith({
    Value<String>? lessonId,
    Value<String>? courseId,
    Value<String>? title,
    Value<String>? status,
    Value<String>? syncStatus,
    Value<String?>? lessonVersionId,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return CachedLessonsCompanion(
      lessonId: lessonId ?? this.lessonId,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      status: status ?? this.status,
      syncStatus: syncStatus ?? this.syncStatus,
      lessonVersionId: lessonVersionId ?? this.lessonVersionId,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (lessonId.present) {
      map['lesson_id'] = Variable<String>(lessonId.value);
    }
    if (courseId.present) {
      map['course_id'] = Variable<String>(courseId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (lessonVersionId.present) {
      map['lesson_version_id'] = Variable<String>(lessonVersionId.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedLessonsCompanion(')
          ..write('lessonId: $lessonId, ')
          ..write('courseId: $courseId, ')
          ..write('title: $title, ')
          ..write('status: $status, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('lessonVersionId: $lessonVersionId, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedQuestionsTable extends CachedQuestions
    with TableInfo<$CachedQuestionsTable, CachedQuestion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedQuestionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _questionIdMeta = const VerificationMeta(
    'questionId',
  );
  @override
  late final GeneratedColumn<String> questionId = GeneratedColumn<String>(
    'question_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lessonIdMeta = const VerificationMeta(
    'lessonId',
  );
  @override
  late final GeneratedColumn<String> lessonId = GeneratedColumn<String>(
    'lesson_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _promptMeta = const VerificationMeta('prompt');
  @override
  late final GeneratedColumn<String> prompt = GeneratedColumn<String>(
    'prompt',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _audioUrlMeta = const VerificationMeta(
    'audioUrl',
  );
  @override
  late final GeneratedColumn<String> audioUrl = GeneratedColumn<String>(
    'audio_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _correctAnswerMeta = const VerificationMeta(
    'correctAnswer',
  );
  @override
  late final GeneratedColumn<String> correctAnswer = GeneratedColumn<String>(
    'correct_answer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _explanationMeta = const VerificationMeta(
    'explanation',
  );
  @override
  late final GeneratedColumn<String> explanation = GeneratedColumn<String>(
    'explanation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questionVersionIdMeta = const VerificationMeta(
    'questionVersionId',
  );
  @override
  late final GeneratedColumn<String> questionVersionId =
      GeneratedColumn<String>(
        'question_version_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    questionId,
    lessonId,
    prompt,
    type,
    audioUrl,
    correctAnswer,
    explanation,
    questionVersionId,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_questions';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedQuestion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('question_id')) {
      context.handle(
        _questionIdMeta,
        questionId.isAcceptableOrUnknown(data['question_id']!, _questionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('lesson_id')) {
      context.handle(
        _lessonIdMeta,
        lessonId.isAcceptableOrUnknown(data['lesson_id']!, _lessonIdMeta),
      );
    } else if (isInserting) {
      context.missing(_lessonIdMeta);
    }
    if (data.containsKey('prompt')) {
      context.handle(
        _promptMeta,
        prompt.isAcceptableOrUnknown(data['prompt']!, _promptMeta),
      );
    } else if (isInserting) {
      context.missing(_promptMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('audio_url')) {
      context.handle(
        _audioUrlMeta,
        audioUrl.isAcceptableOrUnknown(data['audio_url']!, _audioUrlMeta),
      );
    }
    if (data.containsKey('correct_answer')) {
      context.handle(
        _correctAnswerMeta,
        correctAnswer.isAcceptableOrUnknown(
          data['correct_answer']!,
          _correctAnswerMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_correctAnswerMeta);
    }
    if (data.containsKey('explanation')) {
      context.handle(
        _explanationMeta,
        explanation.isAcceptableOrUnknown(
          data['explanation']!,
          _explanationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_explanationMeta);
    }
    if (data.containsKey('question_version_id')) {
      context.handle(
        _questionVersionIdMeta,
        questionVersionId.isAcceptableOrUnknown(
          data['question_version_id']!,
          _questionVersionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_questionVersionIdMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {questionId};
  @override
  CachedQuestion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedQuestion(
      questionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_id'],
      )!,
      lessonId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lesson_id'],
      )!,
      prompt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prompt'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      audioUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio_url'],
      ),
      correctAnswer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}correct_answer'],
      )!,
      explanation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}explanation'],
      )!,
      questionVersionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_version_id'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedQuestionsTable createAlias(String alias) {
    return $CachedQuestionsTable(attachedDatabase, alias);
  }
}

class CachedQuestion extends DataClass implements Insertable<CachedQuestion> {
  final String questionId;
  final String lessonId;
  final String prompt;
  final String type;
  final String? audioUrl;
  final String correctAnswer;
  final String explanation;
  final String questionVersionId;
  final DateTime cachedAt;
  const CachedQuestion({
    required this.questionId,
    required this.lessonId,
    required this.prompt,
    required this.type,
    this.audioUrl,
    required this.correctAnswer,
    required this.explanation,
    required this.questionVersionId,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['question_id'] = Variable<String>(questionId);
    map['lesson_id'] = Variable<String>(lessonId);
    map['prompt'] = Variable<String>(prompt);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || audioUrl != null) {
      map['audio_url'] = Variable<String>(audioUrl);
    }
    map['correct_answer'] = Variable<String>(correctAnswer);
    map['explanation'] = Variable<String>(explanation);
    map['question_version_id'] = Variable<String>(questionVersionId);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedQuestionsCompanion toCompanion(bool nullToAbsent) {
    return CachedQuestionsCompanion(
      questionId: Value(questionId),
      lessonId: Value(lessonId),
      prompt: Value(prompt),
      type: Value(type),
      audioUrl: audioUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(audioUrl),
      correctAnswer: Value(correctAnswer),
      explanation: Value(explanation),
      questionVersionId: Value(questionVersionId),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedQuestion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedQuestion(
      questionId: serializer.fromJson<String>(json['questionId']),
      lessonId: serializer.fromJson<String>(json['lessonId']),
      prompt: serializer.fromJson<String>(json['prompt']),
      type: serializer.fromJson<String>(json['type']),
      audioUrl: serializer.fromJson<String?>(json['audioUrl']),
      correctAnswer: serializer.fromJson<String>(json['correctAnswer']),
      explanation: serializer.fromJson<String>(json['explanation']),
      questionVersionId: serializer.fromJson<String>(json['questionVersionId']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'questionId': serializer.toJson<String>(questionId),
      'lessonId': serializer.toJson<String>(lessonId),
      'prompt': serializer.toJson<String>(prompt),
      'type': serializer.toJson<String>(type),
      'audioUrl': serializer.toJson<String?>(audioUrl),
      'correctAnswer': serializer.toJson<String>(correctAnswer),
      'explanation': serializer.toJson<String>(explanation),
      'questionVersionId': serializer.toJson<String>(questionVersionId),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedQuestion copyWith({
    String? questionId,
    String? lessonId,
    String? prompt,
    String? type,
    Value<String?> audioUrl = const Value.absent(),
    String? correctAnswer,
    String? explanation,
    String? questionVersionId,
    DateTime? cachedAt,
  }) => CachedQuestion(
    questionId: questionId ?? this.questionId,
    lessonId: lessonId ?? this.lessonId,
    prompt: prompt ?? this.prompt,
    type: type ?? this.type,
    audioUrl: audioUrl.present ? audioUrl.value : this.audioUrl,
    correctAnswer: correctAnswer ?? this.correctAnswer,
    explanation: explanation ?? this.explanation,
    questionVersionId: questionVersionId ?? this.questionVersionId,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedQuestion copyWithCompanion(CachedQuestionsCompanion data) {
    return CachedQuestion(
      questionId: data.questionId.present
          ? data.questionId.value
          : this.questionId,
      lessonId: data.lessonId.present ? data.lessonId.value : this.lessonId,
      prompt: data.prompt.present ? data.prompt.value : this.prompt,
      type: data.type.present ? data.type.value : this.type,
      audioUrl: data.audioUrl.present ? data.audioUrl.value : this.audioUrl,
      correctAnswer: data.correctAnswer.present
          ? data.correctAnswer.value
          : this.correctAnswer,
      explanation: data.explanation.present
          ? data.explanation.value
          : this.explanation,
      questionVersionId: data.questionVersionId.present
          ? data.questionVersionId.value
          : this.questionVersionId,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedQuestion(')
          ..write('questionId: $questionId, ')
          ..write('lessonId: $lessonId, ')
          ..write('prompt: $prompt, ')
          ..write('type: $type, ')
          ..write('audioUrl: $audioUrl, ')
          ..write('correctAnswer: $correctAnswer, ')
          ..write('explanation: $explanation, ')
          ..write('questionVersionId: $questionVersionId, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    questionId,
    lessonId,
    prompt,
    type,
    audioUrl,
    correctAnswer,
    explanation,
    questionVersionId,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedQuestion &&
          other.questionId == this.questionId &&
          other.lessonId == this.lessonId &&
          other.prompt == this.prompt &&
          other.type == this.type &&
          other.audioUrl == this.audioUrl &&
          other.correctAnswer == this.correctAnswer &&
          other.explanation == this.explanation &&
          other.questionVersionId == this.questionVersionId &&
          other.cachedAt == this.cachedAt);
}

class CachedQuestionsCompanion extends UpdateCompanion<CachedQuestion> {
  final Value<String> questionId;
  final Value<String> lessonId;
  final Value<String> prompt;
  final Value<String> type;
  final Value<String?> audioUrl;
  final Value<String> correctAnswer;
  final Value<String> explanation;
  final Value<String> questionVersionId;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedQuestionsCompanion({
    this.questionId = const Value.absent(),
    this.lessonId = const Value.absent(),
    this.prompt = const Value.absent(),
    this.type = const Value.absent(),
    this.audioUrl = const Value.absent(),
    this.correctAnswer = const Value.absent(),
    this.explanation = const Value.absent(),
    this.questionVersionId = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedQuestionsCompanion.insert({
    required String questionId,
    required String lessonId,
    required String prompt,
    required String type,
    this.audioUrl = const Value.absent(),
    required String correctAnswer,
    required String explanation,
    required String questionVersionId,
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : questionId = Value(questionId),
       lessonId = Value(lessonId),
       prompt = Value(prompt),
       type = Value(type),
       correctAnswer = Value(correctAnswer),
       explanation = Value(explanation),
       questionVersionId = Value(questionVersionId);
  static Insertable<CachedQuestion> custom({
    Expression<String>? questionId,
    Expression<String>? lessonId,
    Expression<String>? prompt,
    Expression<String>? type,
    Expression<String>? audioUrl,
    Expression<String>? correctAnswer,
    Expression<String>? explanation,
    Expression<String>? questionVersionId,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (questionId != null) 'question_id': questionId,
      if (lessonId != null) 'lesson_id': lessonId,
      if (prompt != null) 'prompt': prompt,
      if (type != null) 'type': type,
      if (audioUrl != null) 'audio_url': audioUrl,
      if (correctAnswer != null) 'correct_answer': correctAnswer,
      if (explanation != null) 'explanation': explanation,
      if (questionVersionId != null) 'question_version_id': questionVersionId,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedQuestionsCompanion copyWith({
    Value<String>? questionId,
    Value<String>? lessonId,
    Value<String>? prompt,
    Value<String>? type,
    Value<String?>? audioUrl,
    Value<String>? correctAnswer,
    Value<String>? explanation,
    Value<String>? questionVersionId,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return CachedQuestionsCompanion(
      questionId: questionId ?? this.questionId,
      lessonId: lessonId ?? this.lessonId,
      prompt: prompt ?? this.prompt,
      type: type ?? this.type,
      audioUrl: audioUrl ?? this.audioUrl,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      explanation: explanation ?? this.explanation,
      questionVersionId: questionVersionId ?? this.questionVersionId,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (questionId.present) {
      map['question_id'] = Variable<String>(questionId.value);
    }
    if (lessonId.present) {
      map['lesson_id'] = Variable<String>(lessonId.value);
    }
    if (prompt.present) {
      map['prompt'] = Variable<String>(prompt.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (audioUrl.present) {
      map['audio_url'] = Variable<String>(audioUrl.value);
    }
    if (correctAnswer.present) {
      map['correct_answer'] = Variable<String>(correctAnswer.value);
    }
    if (explanation.present) {
      map['explanation'] = Variable<String>(explanation.value);
    }
    if (questionVersionId.present) {
      map['question_version_id'] = Variable<String>(questionVersionId.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedQuestionsCompanion(')
          ..write('questionId: $questionId, ')
          ..write('lessonId: $lessonId, ')
          ..write('prompt: $prompt, ')
          ..write('type: $type, ')
          ..write('audioUrl: $audioUrl, ')
          ..write('correctAnswer: $correctAnswer, ')
          ..write('explanation: $explanation, ')
          ..write('questionVersionId: $questionVersionId, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedQuestionOptionsTable extends CachedQuestionOptions
    with TableInfo<$CachedQuestionOptionsTable, CachedQuestionOption> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedQuestionOptionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _questionIdMeta = const VerificationMeta(
    'questionId',
  );
  @override
  late final GeneratedColumn<String> questionId = GeneratedColumn<String>(
    'question_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _optionIdMeta = const VerificationMeta(
    'optionId',
  );
  @override
  late final GeneratedColumn<int> optionId = GeneratedColumn<int>(
    'option_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _optionTextMeta = const VerificationMeta(
    'optionText',
  );
  @override
  late final GeneratedColumn<String> optionText = GeneratedColumn<String>(
    'option_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, questionId, optionId, optionText];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_question_options';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedQuestionOption> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('question_id')) {
      context.handle(
        _questionIdMeta,
        questionId.isAcceptableOrUnknown(data['question_id']!, _questionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('option_id')) {
      context.handle(
        _optionIdMeta,
        optionId.isAcceptableOrUnknown(data['option_id']!, _optionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_optionIdMeta);
    }
    if (data.containsKey('option_text')) {
      context.handle(
        _optionTextMeta,
        optionText.isAcceptableOrUnknown(data['option_text']!, _optionTextMeta),
      );
    } else if (isInserting) {
      context.missing(_optionTextMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedQuestionOption map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedQuestionOption(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      questionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_id'],
      )!,
      optionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}option_id'],
      )!,
      optionText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}option_text'],
      )!,
    );
  }

  @override
  $CachedQuestionOptionsTable createAlias(String alias) {
    return $CachedQuestionOptionsTable(attachedDatabase, alias);
  }
}

class CachedQuestionOption extends DataClass
    implements Insertable<CachedQuestionOption> {
  final int id;
  final String questionId;
  final int optionId;
  final String optionText;
  const CachedQuestionOption({
    required this.id,
    required this.questionId,
    required this.optionId,
    required this.optionText,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['question_id'] = Variable<String>(questionId);
    map['option_id'] = Variable<int>(optionId);
    map['option_text'] = Variable<String>(optionText);
    return map;
  }

  CachedQuestionOptionsCompanion toCompanion(bool nullToAbsent) {
    return CachedQuestionOptionsCompanion(
      id: Value(id),
      questionId: Value(questionId),
      optionId: Value(optionId),
      optionText: Value(optionText),
    );
  }

  factory CachedQuestionOption.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedQuestionOption(
      id: serializer.fromJson<int>(json['id']),
      questionId: serializer.fromJson<String>(json['questionId']),
      optionId: serializer.fromJson<int>(json['optionId']),
      optionText: serializer.fromJson<String>(json['optionText']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'questionId': serializer.toJson<String>(questionId),
      'optionId': serializer.toJson<int>(optionId),
      'optionText': serializer.toJson<String>(optionText),
    };
  }

  CachedQuestionOption copyWith({
    int? id,
    String? questionId,
    int? optionId,
    String? optionText,
  }) => CachedQuestionOption(
    id: id ?? this.id,
    questionId: questionId ?? this.questionId,
    optionId: optionId ?? this.optionId,
    optionText: optionText ?? this.optionText,
  );
  CachedQuestionOption copyWithCompanion(CachedQuestionOptionsCompanion data) {
    return CachedQuestionOption(
      id: data.id.present ? data.id.value : this.id,
      questionId: data.questionId.present
          ? data.questionId.value
          : this.questionId,
      optionId: data.optionId.present ? data.optionId.value : this.optionId,
      optionText: data.optionText.present
          ? data.optionText.value
          : this.optionText,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedQuestionOption(')
          ..write('id: $id, ')
          ..write('questionId: $questionId, ')
          ..write('optionId: $optionId, ')
          ..write('optionText: $optionText')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, questionId, optionId, optionText);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedQuestionOption &&
          other.id == this.id &&
          other.questionId == this.questionId &&
          other.optionId == this.optionId &&
          other.optionText == this.optionText);
}

class CachedQuestionOptionsCompanion
    extends UpdateCompanion<CachedQuestionOption> {
  final Value<int> id;
  final Value<String> questionId;
  final Value<int> optionId;
  final Value<String> optionText;
  const CachedQuestionOptionsCompanion({
    this.id = const Value.absent(),
    this.questionId = const Value.absent(),
    this.optionId = const Value.absent(),
    this.optionText = const Value.absent(),
  });
  CachedQuestionOptionsCompanion.insert({
    this.id = const Value.absent(),
    required String questionId,
    required int optionId,
    required String optionText,
  }) : questionId = Value(questionId),
       optionId = Value(optionId),
       optionText = Value(optionText);
  static Insertable<CachedQuestionOption> custom({
    Expression<int>? id,
    Expression<String>? questionId,
    Expression<int>? optionId,
    Expression<String>? optionText,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (questionId != null) 'question_id': questionId,
      if (optionId != null) 'option_id': optionId,
      if (optionText != null) 'option_text': optionText,
    });
  }

  CachedQuestionOptionsCompanion copyWith({
    Value<int>? id,
    Value<String>? questionId,
    Value<int>? optionId,
    Value<String>? optionText,
  }) {
    return CachedQuestionOptionsCompanion(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      optionId: optionId ?? this.optionId,
      optionText: optionText ?? this.optionText,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (questionId.present) {
      map['question_id'] = Variable<String>(questionId.value);
    }
    if (optionId.present) {
      map['option_id'] = Variable<int>(optionId.value);
    }
    if (optionText.present) {
      map['option_text'] = Variable<String>(optionText.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedQuestionOptionsCompanion(')
          ..write('id: $id, ')
          ..write('questionId: $questionId, ')
          ..write('optionId: $optionId, ')
          ..write('optionText: $optionText')
          ..write(')'))
        .toString();
  }
}

class $PendingAttemptsTable extends PendingAttempts
    with TableInfo<$PendingAttemptsTable, PendingAttempt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingAttemptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _clientRequestIdMeta = const VerificationMeta(
    'clientRequestId',
  );
  @override
  late final GeneratedColumn<String> clientRequestId = GeneratedColumn<String>(
    'client_request_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _courseIdMeta = const VerificationMeta(
    'courseId',
  );
  @override
  late final GeneratedColumn<String> courseId = GeneratedColumn<String>(
    'course_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceLanguageMeta = const VerificationMeta(
    'sourceLanguage',
  );
  @override
  late final GeneratedColumn<String> sourceLanguage = GeneratedColumn<String>(
    'source_language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetLanguageMeta = const VerificationMeta(
    'targetLanguage',
  );
  @override
  late final GeneratedColumn<String> targetLanguage = GeneratedColumn<String>(
    'target_language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lessonIdMeta = const VerificationMeta(
    'lessonId',
  );
  @override
  late final GeneratedColumn<String> lessonId = GeneratedColumn<String>(
    'lesson_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lessonVersionIdMeta = const VerificationMeta(
    'lessonVersionId',
  );
  @override
  late final GeneratedColumn<String> lessonVersionId = GeneratedColumn<String>(
    'lesson_version_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questionIdMeta = const VerificationMeta(
    'questionId',
  );
  @override
  late final GeneratedColumn<String> questionId = GeneratedColumn<String>(
    'question_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questionVersionIdMeta = const VerificationMeta(
    'questionVersionId',
  );
  @override
  late final GeneratedColumn<String> questionVersionId =
      GeneratedColumn<String>(
        'question_version_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _selectedAnswerMeta = const VerificationMeta(
    'selectedAnswer',
  );
  @override
  late final GeneratedColumn<String> selectedAnswer = GeneratedColumn<String>(
    'selected_answer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _responseTimeMsMeta = const VerificationMeta(
    'responseTimeMs',
  );
  @override
  late final GeneratedColumn<int> responseTimeMs = GeneratedColumn<int>(
    'response_time_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usedHintMeta = const VerificationMeta(
    'usedHint',
  );
  @override
  late final GeneratedColumn<bool> usedHint = GeneratedColumn<bool>(
    'used_hint',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("used_hint" IN (0, 1))',
    ),
  );
  static const VerificationMeta _isCorrectLocalMeta = const VerificationMeta(
    'isCorrectLocal',
  );
  @override
  late final GeneratedColumn<bool> isCorrectLocal = GeneratedColumn<bool>(
    'is_correct_local',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_correct_local" IN (0, 1))',
    ),
  );
  static const VerificationMeta _answeredAtMeta = const VerificationMeta(
    'answeredAt',
  );
  @override
  late final GeneratedColumn<DateTime> answeredAt = GeneratedColumn<DateTime>(
    'answered_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('PENDING'),
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastTriedAtMeta = const VerificationMeta(
    'lastTriedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastTriedAt = GeneratedColumn<DateTime>(
    'last_tried_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clientRequestId,
    deviceId,
    courseId,
    sourceLanguage,
    targetLanguage,
    lessonId,
    lessonVersionId,
    questionId,
    questionVersionId,
    selectedAnswer,
    responseTimeMs,
    usedHint,
    isCorrectLocal,
    answeredAt,
    createdAt,
    status,
    retryCount,
    lastError,
    lastTriedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_attempts';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingAttempt> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('client_request_id')) {
      context.handle(
        _clientRequestIdMeta,
        clientRequestId.isAcceptableOrUnknown(
          data['client_request_id']!,
          _clientRequestIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientRequestIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('course_id')) {
      context.handle(
        _courseIdMeta,
        courseId.isAcceptableOrUnknown(data['course_id']!, _courseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_courseIdMeta);
    }
    if (data.containsKey('source_language')) {
      context.handle(
        _sourceLanguageMeta,
        sourceLanguage.isAcceptableOrUnknown(
          data['source_language']!,
          _sourceLanguageMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceLanguageMeta);
    }
    if (data.containsKey('target_language')) {
      context.handle(
        _targetLanguageMeta,
        targetLanguage.isAcceptableOrUnknown(
          data['target_language']!,
          _targetLanguageMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetLanguageMeta);
    }
    if (data.containsKey('lesson_id')) {
      context.handle(
        _lessonIdMeta,
        lessonId.isAcceptableOrUnknown(data['lesson_id']!, _lessonIdMeta),
      );
    } else if (isInserting) {
      context.missing(_lessonIdMeta);
    }
    if (data.containsKey('lesson_version_id')) {
      context.handle(
        _lessonVersionIdMeta,
        lessonVersionId.isAcceptableOrUnknown(
          data['lesson_version_id']!,
          _lessonVersionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lessonVersionIdMeta);
    }
    if (data.containsKey('question_id')) {
      context.handle(
        _questionIdMeta,
        questionId.isAcceptableOrUnknown(data['question_id']!, _questionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('question_version_id')) {
      context.handle(
        _questionVersionIdMeta,
        questionVersionId.isAcceptableOrUnknown(
          data['question_version_id']!,
          _questionVersionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_questionVersionIdMeta);
    }
    if (data.containsKey('selected_answer')) {
      context.handle(
        _selectedAnswerMeta,
        selectedAnswer.isAcceptableOrUnknown(
          data['selected_answer']!,
          _selectedAnswerMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_selectedAnswerMeta);
    }
    if (data.containsKey('response_time_ms')) {
      context.handle(
        _responseTimeMsMeta,
        responseTimeMs.isAcceptableOrUnknown(
          data['response_time_ms']!,
          _responseTimeMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_responseTimeMsMeta);
    }
    if (data.containsKey('used_hint')) {
      context.handle(
        _usedHintMeta,
        usedHint.isAcceptableOrUnknown(data['used_hint']!, _usedHintMeta),
      );
    } else if (isInserting) {
      context.missing(_usedHintMeta);
    }
    if (data.containsKey('is_correct_local')) {
      context.handle(
        _isCorrectLocalMeta,
        isCorrectLocal.isAcceptableOrUnknown(
          data['is_correct_local']!,
          _isCorrectLocalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isCorrectLocalMeta);
    }
    if (data.containsKey('answered_at')) {
      context.handle(
        _answeredAtMeta,
        answeredAt.isAcceptableOrUnknown(data['answered_at']!, _answeredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_answeredAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('last_tried_at')) {
      context.handle(
        _lastTriedAtMeta,
        lastTriedAt.isAcceptableOrUnknown(
          data['last_tried_at']!,
          _lastTriedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingAttempt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingAttempt(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      clientRequestId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_request_id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      courseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}course_id'],
      )!,
      sourceLanguage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_language'],
      )!,
      targetLanguage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_language'],
      )!,
      lessonId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lesson_id'],
      )!,
      lessonVersionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lesson_version_id'],
      )!,
      questionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_id'],
      )!,
      questionVersionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_version_id'],
      )!,
      selectedAnswer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}selected_answer'],
      )!,
      responseTimeMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}response_time_ms'],
      )!,
      usedHint: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}used_hint'],
      )!,
      isCorrectLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_correct_local'],
      )!,
      answeredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}answered_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      lastTriedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_tried_at'],
      ),
    );
  }

  @override
  $PendingAttemptsTable createAlias(String alias) {
    return $PendingAttemptsTable(attachedDatabase, alias);
  }
}

class PendingAttempt extends DataClass implements Insertable<PendingAttempt> {
  final int id;
  final String clientRequestId;
  final String deviceId;
  final String courseId;
  final String sourceLanguage;
  final String targetLanguage;
  final String lessonId;
  final String lessonVersionId;
  final String questionId;
  final String questionVersionId;
  final String selectedAnswer;
  final int responseTimeMs;
  final bool usedHint;
  final bool isCorrectLocal;
  final DateTime answeredAt;
  final DateTime createdAt;
  final String status;
  final int retryCount;
  final String? lastError;
  final DateTime? lastTriedAt;
  const PendingAttempt({
    required this.id,
    required this.clientRequestId,
    required this.deviceId,
    required this.courseId,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.lessonId,
    required this.lessonVersionId,
    required this.questionId,
    required this.questionVersionId,
    required this.selectedAnswer,
    required this.responseTimeMs,
    required this.usedHint,
    required this.isCorrectLocal,
    required this.answeredAt,
    required this.createdAt,
    required this.status,
    required this.retryCount,
    this.lastError,
    this.lastTriedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['client_request_id'] = Variable<String>(clientRequestId);
    map['device_id'] = Variable<String>(deviceId);
    map['course_id'] = Variable<String>(courseId);
    map['source_language'] = Variable<String>(sourceLanguage);
    map['target_language'] = Variable<String>(targetLanguage);
    map['lesson_id'] = Variable<String>(lessonId);
    map['lesson_version_id'] = Variable<String>(lessonVersionId);
    map['question_id'] = Variable<String>(questionId);
    map['question_version_id'] = Variable<String>(questionVersionId);
    map['selected_answer'] = Variable<String>(selectedAnswer);
    map['response_time_ms'] = Variable<int>(responseTimeMs);
    map['used_hint'] = Variable<bool>(usedHint);
    map['is_correct_local'] = Variable<bool>(isCorrectLocal);
    map['answered_at'] = Variable<DateTime>(answeredAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['status'] = Variable<String>(status);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    if (!nullToAbsent || lastTriedAt != null) {
      map['last_tried_at'] = Variable<DateTime>(lastTriedAt);
    }
    return map;
  }

  PendingAttemptsCompanion toCompanion(bool nullToAbsent) {
    return PendingAttemptsCompanion(
      id: Value(id),
      clientRequestId: Value(clientRequestId),
      deviceId: Value(deviceId),
      courseId: Value(courseId),
      sourceLanguage: Value(sourceLanguage),
      targetLanguage: Value(targetLanguage),
      lessonId: Value(lessonId),
      lessonVersionId: Value(lessonVersionId),
      questionId: Value(questionId),
      questionVersionId: Value(questionVersionId),
      selectedAnswer: Value(selectedAnswer),
      responseTimeMs: Value(responseTimeMs),
      usedHint: Value(usedHint),
      isCorrectLocal: Value(isCorrectLocal),
      answeredAt: Value(answeredAt),
      createdAt: Value(createdAt),
      status: Value(status),
      retryCount: Value(retryCount),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      lastTriedAt: lastTriedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastTriedAt),
    );
  }

  factory PendingAttempt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingAttempt(
      id: serializer.fromJson<int>(json['id']),
      clientRequestId: serializer.fromJson<String>(json['clientRequestId']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      courseId: serializer.fromJson<String>(json['courseId']),
      sourceLanguage: serializer.fromJson<String>(json['sourceLanguage']),
      targetLanguage: serializer.fromJson<String>(json['targetLanguage']),
      lessonId: serializer.fromJson<String>(json['lessonId']),
      lessonVersionId: serializer.fromJson<String>(json['lessonVersionId']),
      questionId: serializer.fromJson<String>(json['questionId']),
      questionVersionId: serializer.fromJson<String>(json['questionVersionId']),
      selectedAnswer: serializer.fromJson<String>(json['selectedAnswer']),
      responseTimeMs: serializer.fromJson<int>(json['responseTimeMs']),
      usedHint: serializer.fromJson<bool>(json['usedHint']),
      isCorrectLocal: serializer.fromJson<bool>(json['isCorrectLocal']),
      answeredAt: serializer.fromJson<DateTime>(json['answeredAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      status: serializer.fromJson<String>(json['status']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      lastTriedAt: serializer.fromJson<DateTime?>(json['lastTriedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'clientRequestId': serializer.toJson<String>(clientRequestId),
      'deviceId': serializer.toJson<String>(deviceId),
      'courseId': serializer.toJson<String>(courseId),
      'sourceLanguage': serializer.toJson<String>(sourceLanguage),
      'targetLanguage': serializer.toJson<String>(targetLanguage),
      'lessonId': serializer.toJson<String>(lessonId),
      'lessonVersionId': serializer.toJson<String>(lessonVersionId),
      'questionId': serializer.toJson<String>(questionId),
      'questionVersionId': serializer.toJson<String>(questionVersionId),
      'selectedAnswer': serializer.toJson<String>(selectedAnswer),
      'responseTimeMs': serializer.toJson<int>(responseTimeMs),
      'usedHint': serializer.toJson<bool>(usedHint),
      'isCorrectLocal': serializer.toJson<bool>(isCorrectLocal),
      'answeredAt': serializer.toJson<DateTime>(answeredAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'status': serializer.toJson<String>(status),
      'retryCount': serializer.toJson<int>(retryCount),
      'lastError': serializer.toJson<String?>(lastError),
      'lastTriedAt': serializer.toJson<DateTime?>(lastTriedAt),
    };
  }

  PendingAttempt copyWith({
    int? id,
    String? clientRequestId,
    String? deviceId,
    String? courseId,
    String? sourceLanguage,
    String? targetLanguage,
    String? lessonId,
    String? lessonVersionId,
    String? questionId,
    String? questionVersionId,
    String? selectedAnswer,
    int? responseTimeMs,
    bool? usedHint,
    bool? isCorrectLocal,
    DateTime? answeredAt,
    DateTime? createdAt,
    String? status,
    int? retryCount,
    Value<String?> lastError = const Value.absent(),
    Value<DateTime?> lastTriedAt = const Value.absent(),
  }) => PendingAttempt(
    id: id ?? this.id,
    clientRequestId: clientRequestId ?? this.clientRequestId,
    deviceId: deviceId ?? this.deviceId,
    courseId: courseId ?? this.courseId,
    sourceLanguage: sourceLanguage ?? this.sourceLanguage,
    targetLanguage: targetLanguage ?? this.targetLanguage,
    lessonId: lessonId ?? this.lessonId,
    lessonVersionId: lessonVersionId ?? this.lessonVersionId,
    questionId: questionId ?? this.questionId,
    questionVersionId: questionVersionId ?? this.questionVersionId,
    selectedAnswer: selectedAnswer ?? this.selectedAnswer,
    responseTimeMs: responseTimeMs ?? this.responseTimeMs,
    usedHint: usedHint ?? this.usedHint,
    isCorrectLocal: isCorrectLocal ?? this.isCorrectLocal,
    answeredAt: answeredAt ?? this.answeredAt,
    createdAt: createdAt ?? this.createdAt,
    status: status ?? this.status,
    retryCount: retryCount ?? this.retryCount,
    lastError: lastError.present ? lastError.value : this.lastError,
    lastTriedAt: lastTriedAt.present ? lastTriedAt.value : this.lastTriedAt,
  );
  PendingAttempt copyWithCompanion(PendingAttemptsCompanion data) {
    return PendingAttempt(
      id: data.id.present ? data.id.value : this.id,
      clientRequestId: data.clientRequestId.present
          ? data.clientRequestId.value
          : this.clientRequestId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      courseId: data.courseId.present ? data.courseId.value : this.courseId,
      sourceLanguage: data.sourceLanguage.present
          ? data.sourceLanguage.value
          : this.sourceLanguage,
      targetLanguage: data.targetLanguage.present
          ? data.targetLanguage.value
          : this.targetLanguage,
      lessonId: data.lessonId.present ? data.lessonId.value : this.lessonId,
      lessonVersionId: data.lessonVersionId.present
          ? data.lessonVersionId.value
          : this.lessonVersionId,
      questionId: data.questionId.present
          ? data.questionId.value
          : this.questionId,
      questionVersionId: data.questionVersionId.present
          ? data.questionVersionId.value
          : this.questionVersionId,
      selectedAnswer: data.selectedAnswer.present
          ? data.selectedAnswer.value
          : this.selectedAnswer,
      responseTimeMs: data.responseTimeMs.present
          ? data.responseTimeMs.value
          : this.responseTimeMs,
      usedHint: data.usedHint.present ? data.usedHint.value : this.usedHint,
      isCorrectLocal: data.isCorrectLocal.present
          ? data.isCorrectLocal.value
          : this.isCorrectLocal,
      answeredAt: data.answeredAt.present
          ? data.answeredAt.value
          : this.answeredAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      status: data.status.present ? data.status.value : this.status,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      lastTriedAt: data.lastTriedAt.present
          ? data.lastTriedAt.value
          : this.lastTriedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingAttempt(')
          ..write('id: $id, ')
          ..write('clientRequestId: $clientRequestId, ')
          ..write('deviceId: $deviceId, ')
          ..write('courseId: $courseId, ')
          ..write('sourceLanguage: $sourceLanguage, ')
          ..write('targetLanguage: $targetLanguage, ')
          ..write('lessonId: $lessonId, ')
          ..write('lessonVersionId: $lessonVersionId, ')
          ..write('questionId: $questionId, ')
          ..write('questionVersionId: $questionVersionId, ')
          ..write('selectedAnswer: $selectedAnswer, ')
          ..write('responseTimeMs: $responseTimeMs, ')
          ..write('usedHint: $usedHint, ')
          ..write('isCorrectLocal: $isCorrectLocal, ')
          ..write('answeredAt: $answeredAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError, ')
          ..write('lastTriedAt: $lastTriedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clientRequestId,
    deviceId,
    courseId,
    sourceLanguage,
    targetLanguage,
    lessonId,
    lessonVersionId,
    questionId,
    questionVersionId,
    selectedAnswer,
    responseTimeMs,
    usedHint,
    isCorrectLocal,
    answeredAt,
    createdAt,
    status,
    retryCount,
    lastError,
    lastTriedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingAttempt &&
          other.id == this.id &&
          other.clientRequestId == this.clientRequestId &&
          other.deviceId == this.deviceId &&
          other.courseId == this.courseId &&
          other.sourceLanguage == this.sourceLanguage &&
          other.targetLanguage == this.targetLanguage &&
          other.lessonId == this.lessonId &&
          other.lessonVersionId == this.lessonVersionId &&
          other.questionId == this.questionId &&
          other.questionVersionId == this.questionVersionId &&
          other.selectedAnswer == this.selectedAnswer &&
          other.responseTimeMs == this.responseTimeMs &&
          other.usedHint == this.usedHint &&
          other.isCorrectLocal == this.isCorrectLocal &&
          other.answeredAt == this.answeredAt &&
          other.createdAt == this.createdAt &&
          other.status == this.status &&
          other.retryCount == this.retryCount &&
          other.lastError == this.lastError &&
          other.lastTriedAt == this.lastTriedAt);
}

class PendingAttemptsCompanion extends UpdateCompanion<PendingAttempt> {
  final Value<int> id;
  final Value<String> clientRequestId;
  final Value<String> deviceId;
  final Value<String> courseId;
  final Value<String> sourceLanguage;
  final Value<String> targetLanguage;
  final Value<String> lessonId;
  final Value<String> lessonVersionId;
  final Value<String> questionId;
  final Value<String> questionVersionId;
  final Value<String> selectedAnswer;
  final Value<int> responseTimeMs;
  final Value<bool> usedHint;
  final Value<bool> isCorrectLocal;
  final Value<DateTime> answeredAt;
  final Value<DateTime> createdAt;
  final Value<String> status;
  final Value<int> retryCount;
  final Value<String?> lastError;
  final Value<DateTime?> lastTriedAt;
  const PendingAttemptsCompanion({
    this.id = const Value.absent(),
    this.clientRequestId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.courseId = const Value.absent(),
    this.sourceLanguage = const Value.absent(),
    this.targetLanguage = const Value.absent(),
    this.lessonId = const Value.absent(),
    this.lessonVersionId = const Value.absent(),
    this.questionId = const Value.absent(),
    this.questionVersionId = const Value.absent(),
    this.selectedAnswer = const Value.absent(),
    this.responseTimeMs = const Value.absent(),
    this.usedHint = const Value.absent(),
    this.isCorrectLocal = const Value.absent(),
    this.answeredAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.lastTriedAt = const Value.absent(),
  });
  PendingAttemptsCompanion.insert({
    this.id = const Value.absent(),
    required String clientRequestId,
    required String deviceId,
    required String courseId,
    required String sourceLanguage,
    required String targetLanguage,
    required String lessonId,
    required String lessonVersionId,
    required String questionId,
    required String questionVersionId,
    required String selectedAnswer,
    required int responseTimeMs,
    required bool usedHint,
    required bool isCorrectLocal,
    required DateTime answeredAt,
    this.createdAt = const Value.absent(),
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.lastTriedAt = const Value.absent(),
  }) : clientRequestId = Value(clientRequestId),
       deviceId = Value(deviceId),
       courseId = Value(courseId),
       sourceLanguage = Value(sourceLanguage),
       targetLanguage = Value(targetLanguage),
       lessonId = Value(lessonId),
       lessonVersionId = Value(lessonVersionId),
       questionId = Value(questionId),
       questionVersionId = Value(questionVersionId),
       selectedAnswer = Value(selectedAnswer),
       responseTimeMs = Value(responseTimeMs),
       usedHint = Value(usedHint),
       isCorrectLocal = Value(isCorrectLocal),
       answeredAt = Value(answeredAt);
  static Insertable<PendingAttempt> custom({
    Expression<int>? id,
    Expression<String>? clientRequestId,
    Expression<String>? deviceId,
    Expression<String>? courseId,
    Expression<String>? sourceLanguage,
    Expression<String>? targetLanguage,
    Expression<String>? lessonId,
    Expression<String>? lessonVersionId,
    Expression<String>? questionId,
    Expression<String>? questionVersionId,
    Expression<String>? selectedAnswer,
    Expression<int>? responseTimeMs,
    Expression<bool>? usedHint,
    Expression<bool>? isCorrectLocal,
    Expression<DateTime>? answeredAt,
    Expression<DateTime>? createdAt,
    Expression<String>? status,
    Expression<int>? retryCount,
    Expression<String>? lastError,
    Expression<DateTime>? lastTriedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientRequestId != null) 'client_request_id': clientRequestId,
      if (deviceId != null) 'device_id': deviceId,
      if (courseId != null) 'course_id': courseId,
      if (sourceLanguage != null) 'source_language': sourceLanguage,
      if (targetLanguage != null) 'target_language': targetLanguage,
      if (lessonId != null) 'lesson_id': lessonId,
      if (lessonVersionId != null) 'lesson_version_id': lessonVersionId,
      if (questionId != null) 'question_id': questionId,
      if (questionVersionId != null) 'question_version_id': questionVersionId,
      if (selectedAnswer != null) 'selected_answer': selectedAnswer,
      if (responseTimeMs != null) 'response_time_ms': responseTimeMs,
      if (usedHint != null) 'used_hint': usedHint,
      if (isCorrectLocal != null) 'is_correct_local': isCorrectLocal,
      if (answeredAt != null) 'answered_at': answeredAt,
      if (createdAt != null) 'created_at': createdAt,
      if (status != null) 'status': status,
      if (retryCount != null) 'retry_count': retryCount,
      if (lastError != null) 'last_error': lastError,
      if (lastTriedAt != null) 'last_tried_at': lastTriedAt,
    });
  }

  PendingAttemptsCompanion copyWith({
    Value<int>? id,
    Value<String>? clientRequestId,
    Value<String>? deviceId,
    Value<String>? courseId,
    Value<String>? sourceLanguage,
    Value<String>? targetLanguage,
    Value<String>? lessonId,
    Value<String>? lessonVersionId,
    Value<String>? questionId,
    Value<String>? questionVersionId,
    Value<String>? selectedAnswer,
    Value<int>? responseTimeMs,
    Value<bool>? usedHint,
    Value<bool>? isCorrectLocal,
    Value<DateTime>? answeredAt,
    Value<DateTime>? createdAt,
    Value<String>? status,
    Value<int>? retryCount,
    Value<String?>? lastError,
    Value<DateTime?>? lastTriedAt,
  }) {
    return PendingAttemptsCompanion(
      id: id ?? this.id,
      clientRequestId: clientRequestId ?? this.clientRequestId,
      deviceId: deviceId ?? this.deviceId,
      courseId: courseId ?? this.courseId,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      lessonId: lessonId ?? this.lessonId,
      lessonVersionId: lessonVersionId ?? this.lessonVersionId,
      questionId: questionId ?? this.questionId,
      questionVersionId: questionVersionId ?? this.questionVersionId,
      selectedAnswer: selectedAnswer ?? this.selectedAnswer,
      responseTimeMs: responseTimeMs ?? this.responseTimeMs,
      usedHint: usedHint ?? this.usedHint,
      isCorrectLocal: isCorrectLocal ?? this.isCorrectLocal,
      answeredAt: answeredAt ?? this.answeredAt,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      lastTriedAt: lastTriedAt ?? this.lastTriedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (clientRequestId.present) {
      map['client_request_id'] = Variable<String>(clientRequestId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (courseId.present) {
      map['course_id'] = Variable<String>(courseId.value);
    }
    if (sourceLanguage.present) {
      map['source_language'] = Variable<String>(sourceLanguage.value);
    }
    if (targetLanguage.present) {
      map['target_language'] = Variable<String>(targetLanguage.value);
    }
    if (lessonId.present) {
      map['lesson_id'] = Variable<String>(lessonId.value);
    }
    if (lessonVersionId.present) {
      map['lesson_version_id'] = Variable<String>(lessonVersionId.value);
    }
    if (questionId.present) {
      map['question_id'] = Variable<String>(questionId.value);
    }
    if (questionVersionId.present) {
      map['question_version_id'] = Variable<String>(questionVersionId.value);
    }
    if (selectedAnswer.present) {
      map['selected_answer'] = Variable<String>(selectedAnswer.value);
    }
    if (responseTimeMs.present) {
      map['response_time_ms'] = Variable<int>(responseTimeMs.value);
    }
    if (usedHint.present) {
      map['used_hint'] = Variable<bool>(usedHint.value);
    }
    if (isCorrectLocal.present) {
      map['is_correct_local'] = Variable<bool>(isCorrectLocal.value);
    }
    if (answeredAt.present) {
      map['answered_at'] = Variable<DateTime>(answeredAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (lastTriedAt.present) {
      map['last_tried_at'] = Variable<DateTime>(lastTriedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingAttemptsCompanion(')
          ..write('id: $id, ')
          ..write('clientRequestId: $clientRequestId, ')
          ..write('deviceId: $deviceId, ')
          ..write('courseId: $courseId, ')
          ..write('sourceLanguage: $sourceLanguage, ')
          ..write('targetLanguage: $targetLanguage, ')
          ..write('lessonId: $lessonId, ')
          ..write('lessonVersionId: $lessonVersionId, ')
          ..write('questionId: $questionId, ')
          ..write('questionVersionId: $questionVersionId, ')
          ..write('selectedAnswer: $selectedAnswer, ')
          ..write('responseTimeMs: $responseTimeMs, ')
          ..write('usedHint: $usedHint, ')
          ..write('isCorrectLocal: $isCorrectLocal, ')
          ..write('answeredAt: $answeredAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError, ')
          ..write('lastTriedAt: $lastTriedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CachedCoursesTable cachedCourses = $CachedCoursesTable(this);
  late final $CachedLessonsTable cachedLessons = $CachedLessonsTable(this);
  late final $CachedQuestionsTable cachedQuestions = $CachedQuestionsTable(
    this,
  );
  late final $CachedQuestionOptionsTable cachedQuestionOptions =
      $CachedQuestionOptionsTable(this);
  late final $PendingAttemptsTable pendingAttempts = $PendingAttemptsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cachedCourses,
    cachedLessons,
    cachedQuestions,
    cachedQuestionOptions,
    pendingAttempts,
  ];
}

typedef $$CachedCoursesTableCreateCompanionBuilder =
    CachedCoursesCompanion Function({
      required String courseId,
      required String title,
      required String sourceLanguage,
      required String targetLanguage,
      required String level,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });
typedef $$CachedCoursesTableUpdateCompanionBuilder =
    CachedCoursesCompanion Function({
      Value<String> courseId,
      Value<String> title,
      Value<String> sourceLanguage,
      Value<String> targetLanguage,
      Value<String> level,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$CachedCoursesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedCoursesTable> {
  $$CachedCoursesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get courseId => $composableBuilder(
    column: $table.courseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceLanguage => $composableBuilder(
    column: $table.sourceLanguage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetLanguage => $composableBuilder(
    column: $table.targetLanguage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedCoursesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedCoursesTable> {
  $$CachedCoursesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get courseId => $composableBuilder(
    column: $table.courseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceLanguage => $composableBuilder(
    column: $table.sourceLanguage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetLanguage => $composableBuilder(
    column: $table.targetLanguage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedCoursesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedCoursesTable> {
  $$CachedCoursesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get courseId =>
      $composableBuilder(column: $table.courseId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get sourceLanguage => $composableBuilder(
    column: $table.sourceLanguage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetLanguage => $composableBuilder(
    column: $table.targetLanguage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedCoursesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedCoursesTable,
          CachedCourse,
          $$CachedCoursesTableFilterComposer,
          $$CachedCoursesTableOrderingComposer,
          $$CachedCoursesTableAnnotationComposer,
          $$CachedCoursesTableCreateCompanionBuilder,
          $$CachedCoursesTableUpdateCompanionBuilder,
          (
            CachedCourse,
            BaseReferences<_$AppDatabase, $CachedCoursesTable, CachedCourse>,
          ),
          CachedCourse,
          PrefetchHooks Function()
        > {
  $$CachedCoursesTableTableManager(_$AppDatabase db, $CachedCoursesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedCoursesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedCoursesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedCoursesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> courseId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> sourceLanguage = const Value.absent(),
                Value<String> targetLanguage = const Value.absent(),
                Value<String> level = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedCoursesCompanion(
                courseId: courseId,
                title: title,
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage,
                level: level,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String courseId,
                required String title,
                required String sourceLanguage,
                required String targetLanguage,
                required String level,
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedCoursesCompanion.insert(
                courseId: courseId,
                title: title,
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage,
                level: level,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedCoursesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedCoursesTable,
      CachedCourse,
      $$CachedCoursesTableFilterComposer,
      $$CachedCoursesTableOrderingComposer,
      $$CachedCoursesTableAnnotationComposer,
      $$CachedCoursesTableCreateCompanionBuilder,
      $$CachedCoursesTableUpdateCompanionBuilder,
      (
        CachedCourse,
        BaseReferences<_$AppDatabase, $CachedCoursesTable, CachedCourse>,
      ),
      CachedCourse,
      PrefetchHooks Function()
    >;
typedef $$CachedLessonsTableCreateCompanionBuilder =
    CachedLessonsCompanion Function({
      required String lessonId,
      required String courseId,
      required String title,
      required String status,
      Value<String> syncStatus,
      Value<String?> lessonVersionId,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });
typedef $$CachedLessonsTableUpdateCompanionBuilder =
    CachedLessonsCompanion Function({
      Value<String> lessonId,
      Value<String> courseId,
      Value<String> title,
      Value<String> status,
      Value<String> syncStatus,
      Value<String?> lessonVersionId,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$CachedLessonsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedLessonsTable> {
  $$CachedLessonsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get lessonId => $composableBuilder(
    column: $table.lessonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get courseId => $composableBuilder(
    column: $table.courseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lessonVersionId => $composableBuilder(
    column: $table.lessonVersionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedLessonsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedLessonsTable> {
  $$CachedLessonsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get lessonId => $composableBuilder(
    column: $table.lessonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get courseId => $composableBuilder(
    column: $table.courseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lessonVersionId => $composableBuilder(
    column: $table.lessonVersionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedLessonsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedLessonsTable> {
  $$CachedLessonsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get lessonId =>
      $composableBuilder(column: $table.lessonId, builder: (column) => column);

  GeneratedColumn<String> get courseId =>
      $composableBuilder(column: $table.courseId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lessonVersionId => $composableBuilder(
    column: $table.lessonVersionId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedLessonsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedLessonsTable,
          CachedLesson,
          $$CachedLessonsTableFilterComposer,
          $$CachedLessonsTableOrderingComposer,
          $$CachedLessonsTableAnnotationComposer,
          $$CachedLessonsTableCreateCompanionBuilder,
          $$CachedLessonsTableUpdateCompanionBuilder,
          (
            CachedLesson,
            BaseReferences<_$AppDatabase, $CachedLessonsTable, CachedLesson>,
          ),
          CachedLesson,
          PrefetchHooks Function()
        > {
  $$CachedLessonsTableTableManager(_$AppDatabase db, $CachedLessonsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedLessonsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedLessonsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedLessonsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> lessonId = const Value.absent(),
                Value<String> courseId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> lessonVersionId = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedLessonsCompanion(
                lessonId: lessonId,
                courseId: courseId,
                title: title,
                status: status,
                syncStatus: syncStatus,
                lessonVersionId: lessonVersionId,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String lessonId,
                required String courseId,
                required String title,
                required String status,
                Value<String> syncStatus = const Value.absent(),
                Value<String?> lessonVersionId = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedLessonsCompanion.insert(
                lessonId: lessonId,
                courseId: courseId,
                title: title,
                status: status,
                syncStatus: syncStatus,
                lessonVersionId: lessonVersionId,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedLessonsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedLessonsTable,
      CachedLesson,
      $$CachedLessonsTableFilterComposer,
      $$CachedLessonsTableOrderingComposer,
      $$CachedLessonsTableAnnotationComposer,
      $$CachedLessonsTableCreateCompanionBuilder,
      $$CachedLessonsTableUpdateCompanionBuilder,
      (
        CachedLesson,
        BaseReferences<_$AppDatabase, $CachedLessonsTable, CachedLesson>,
      ),
      CachedLesson,
      PrefetchHooks Function()
    >;
typedef $$CachedQuestionsTableCreateCompanionBuilder =
    CachedQuestionsCompanion Function({
      required String questionId,
      required String lessonId,
      required String prompt,
      required String type,
      Value<String?> audioUrl,
      required String correctAnswer,
      required String explanation,
      required String questionVersionId,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });
typedef $$CachedQuestionsTableUpdateCompanionBuilder =
    CachedQuestionsCompanion Function({
      Value<String> questionId,
      Value<String> lessonId,
      Value<String> prompt,
      Value<String> type,
      Value<String?> audioUrl,
      Value<String> correctAnswer,
      Value<String> explanation,
      Value<String> questionVersionId,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$CachedQuestionsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedQuestionsTable> {
  $$CachedQuestionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lessonId => $composableBuilder(
    column: $table.lessonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prompt => $composableBuilder(
    column: $table.prompt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audioUrl => $composableBuilder(
    column: $table.audioUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get correctAnswer => $composableBuilder(
    column: $table.correctAnswer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get questionVersionId => $composableBuilder(
    column: $table.questionVersionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedQuestionsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedQuestionsTable> {
  $$CachedQuestionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lessonId => $composableBuilder(
    column: $table.lessonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prompt => $composableBuilder(
    column: $table.prompt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audioUrl => $composableBuilder(
    column: $table.audioUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get correctAnswer => $composableBuilder(
    column: $table.correctAnswer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get questionVersionId => $composableBuilder(
    column: $table.questionVersionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedQuestionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedQuestionsTable> {
  $$CachedQuestionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lessonId =>
      $composableBuilder(column: $table.lessonId, builder: (column) => column);

  GeneratedColumn<String> get prompt =>
      $composableBuilder(column: $table.prompt, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get audioUrl =>
      $composableBuilder(column: $table.audioUrl, builder: (column) => column);

  GeneratedColumn<String> get correctAnswer => $composableBuilder(
    column: $table.correctAnswer,
    builder: (column) => column,
  );

  GeneratedColumn<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get questionVersionId => $composableBuilder(
    column: $table.questionVersionId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedQuestionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedQuestionsTable,
          CachedQuestion,
          $$CachedQuestionsTableFilterComposer,
          $$CachedQuestionsTableOrderingComposer,
          $$CachedQuestionsTableAnnotationComposer,
          $$CachedQuestionsTableCreateCompanionBuilder,
          $$CachedQuestionsTableUpdateCompanionBuilder,
          (
            CachedQuestion,
            BaseReferences<
              _$AppDatabase,
              $CachedQuestionsTable,
              CachedQuestion
            >,
          ),
          CachedQuestion,
          PrefetchHooks Function()
        > {
  $$CachedQuestionsTableTableManager(
    _$AppDatabase db,
    $CachedQuestionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedQuestionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedQuestionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedQuestionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> questionId = const Value.absent(),
                Value<String> lessonId = const Value.absent(),
                Value<String> prompt = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> audioUrl = const Value.absent(),
                Value<String> correctAnswer = const Value.absent(),
                Value<String> explanation = const Value.absent(),
                Value<String> questionVersionId = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedQuestionsCompanion(
                questionId: questionId,
                lessonId: lessonId,
                prompt: prompt,
                type: type,
                audioUrl: audioUrl,
                correctAnswer: correctAnswer,
                explanation: explanation,
                questionVersionId: questionVersionId,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String questionId,
                required String lessonId,
                required String prompt,
                required String type,
                Value<String?> audioUrl = const Value.absent(),
                required String correctAnswer,
                required String explanation,
                required String questionVersionId,
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedQuestionsCompanion.insert(
                questionId: questionId,
                lessonId: lessonId,
                prompt: prompt,
                type: type,
                audioUrl: audioUrl,
                correctAnswer: correctAnswer,
                explanation: explanation,
                questionVersionId: questionVersionId,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedQuestionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedQuestionsTable,
      CachedQuestion,
      $$CachedQuestionsTableFilterComposer,
      $$CachedQuestionsTableOrderingComposer,
      $$CachedQuestionsTableAnnotationComposer,
      $$CachedQuestionsTableCreateCompanionBuilder,
      $$CachedQuestionsTableUpdateCompanionBuilder,
      (
        CachedQuestion,
        BaseReferences<_$AppDatabase, $CachedQuestionsTable, CachedQuestion>,
      ),
      CachedQuestion,
      PrefetchHooks Function()
    >;
typedef $$CachedQuestionOptionsTableCreateCompanionBuilder =
    CachedQuestionOptionsCompanion Function({
      Value<int> id,
      required String questionId,
      required int optionId,
      required String optionText,
    });
typedef $$CachedQuestionOptionsTableUpdateCompanionBuilder =
    CachedQuestionOptionsCompanion Function({
      Value<int> id,
      Value<String> questionId,
      Value<int> optionId,
      Value<String> optionText,
    });

class $$CachedQuestionOptionsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedQuestionOptionsTable> {
  $$CachedQuestionOptionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get optionId => $composableBuilder(
    column: $table.optionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get optionText => $composableBuilder(
    column: $table.optionText,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedQuestionOptionsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedQuestionOptionsTable> {
  $$CachedQuestionOptionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get optionId => $composableBuilder(
    column: $table.optionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get optionText => $composableBuilder(
    column: $table.optionText,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedQuestionOptionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedQuestionOptionsTable> {
  $$CachedQuestionOptionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get optionId =>
      $composableBuilder(column: $table.optionId, builder: (column) => column);

  GeneratedColumn<String> get optionText => $composableBuilder(
    column: $table.optionText,
    builder: (column) => column,
  );
}

class $$CachedQuestionOptionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedQuestionOptionsTable,
          CachedQuestionOption,
          $$CachedQuestionOptionsTableFilterComposer,
          $$CachedQuestionOptionsTableOrderingComposer,
          $$CachedQuestionOptionsTableAnnotationComposer,
          $$CachedQuestionOptionsTableCreateCompanionBuilder,
          $$CachedQuestionOptionsTableUpdateCompanionBuilder,
          (
            CachedQuestionOption,
            BaseReferences<
              _$AppDatabase,
              $CachedQuestionOptionsTable,
              CachedQuestionOption
            >,
          ),
          CachedQuestionOption,
          PrefetchHooks Function()
        > {
  $$CachedQuestionOptionsTableTableManager(
    _$AppDatabase db,
    $CachedQuestionOptionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedQuestionOptionsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CachedQuestionOptionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedQuestionOptionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> questionId = const Value.absent(),
                Value<int> optionId = const Value.absent(),
                Value<String> optionText = const Value.absent(),
              }) => CachedQuestionOptionsCompanion(
                id: id,
                questionId: questionId,
                optionId: optionId,
                optionText: optionText,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String questionId,
                required int optionId,
                required String optionText,
              }) => CachedQuestionOptionsCompanion.insert(
                id: id,
                questionId: questionId,
                optionId: optionId,
                optionText: optionText,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedQuestionOptionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedQuestionOptionsTable,
      CachedQuestionOption,
      $$CachedQuestionOptionsTableFilterComposer,
      $$CachedQuestionOptionsTableOrderingComposer,
      $$CachedQuestionOptionsTableAnnotationComposer,
      $$CachedQuestionOptionsTableCreateCompanionBuilder,
      $$CachedQuestionOptionsTableUpdateCompanionBuilder,
      (
        CachedQuestionOption,
        BaseReferences<
          _$AppDatabase,
          $CachedQuestionOptionsTable,
          CachedQuestionOption
        >,
      ),
      CachedQuestionOption,
      PrefetchHooks Function()
    >;
typedef $$PendingAttemptsTableCreateCompanionBuilder =
    PendingAttemptsCompanion Function({
      Value<int> id,
      required String clientRequestId,
      required String deviceId,
      required String courseId,
      required String sourceLanguage,
      required String targetLanguage,
      required String lessonId,
      required String lessonVersionId,
      required String questionId,
      required String questionVersionId,
      required String selectedAnswer,
      required int responseTimeMs,
      required bool usedHint,
      required bool isCorrectLocal,
      required DateTime answeredAt,
      Value<DateTime> createdAt,
      Value<String> status,
      Value<int> retryCount,
      Value<String?> lastError,
      Value<DateTime?> lastTriedAt,
    });
typedef $$PendingAttemptsTableUpdateCompanionBuilder =
    PendingAttemptsCompanion Function({
      Value<int> id,
      Value<String> clientRequestId,
      Value<String> deviceId,
      Value<String> courseId,
      Value<String> sourceLanguage,
      Value<String> targetLanguage,
      Value<String> lessonId,
      Value<String> lessonVersionId,
      Value<String> questionId,
      Value<String> questionVersionId,
      Value<String> selectedAnswer,
      Value<int> responseTimeMs,
      Value<bool> usedHint,
      Value<bool> isCorrectLocal,
      Value<DateTime> answeredAt,
      Value<DateTime> createdAt,
      Value<String> status,
      Value<int> retryCount,
      Value<String?> lastError,
      Value<DateTime?> lastTriedAt,
    });

class $$PendingAttemptsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingAttemptsTable> {
  $$PendingAttemptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientRequestId => $composableBuilder(
    column: $table.clientRequestId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get courseId => $composableBuilder(
    column: $table.courseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceLanguage => $composableBuilder(
    column: $table.sourceLanguage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetLanguage => $composableBuilder(
    column: $table.targetLanguage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lessonId => $composableBuilder(
    column: $table.lessonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lessonVersionId => $composableBuilder(
    column: $table.lessonVersionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get questionVersionId => $composableBuilder(
    column: $table.questionVersionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get selectedAnswer => $composableBuilder(
    column: $table.selectedAnswer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get responseTimeMs => $composableBuilder(
    column: $table.responseTimeMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get usedHint => $composableBuilder(
    column: $table.usedHint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCorrectLocal => $composableBuilder(
    column: $table.isCorrectLocal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get answeredAt => $composableBuilder(
    column: $table.answeredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastTriedAt => $composableBuilder(
    column: $table.lastTriedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingAttemptsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingAttemptsTable> {
  $$PendingAttemptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientRequestId => $composableBuilder(
    column: $table.clientRequestId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get courseId => $composableBuilder(
    column: $table.courseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceLanguage => $composableBuilder(
    column: $table.sourceLanguage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetLanguage => $composableBuilder(
    column: $table.targetLanguage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lessonId => $composableBuilder(
    column: $table.lessonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lessonVersionId => $composableBuilder(
    column: $table.lessonVersionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get questionVersionId => $composableBuilder(
    column: $table.questionVersionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get selectedAnswer => $composableBuilder(
    column: $table.selectedAnswer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get responseTimeMs => $composableBuilder(
    column: $table.responseTimeMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get usedHint => $composableBuilder(
    column: $table.usedHint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCorrectLocal => $composableBuilder(
    column: $table.isCorrectLocal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get answeredAt => $composableBuilder(
    column: $table.answeredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastTriedAt => $composableBuilder(
    column: $table.lastTriedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingAttemptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingAttemptsTable> {
  $$PendingAttemptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clientRequestId => $composableBuilder(
    column: $table.clientRequestId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get courseId =>
      $composableBuilder(column: $table.courseId, builder: (column) => column);

  GeneratedColumn<String> get sourceLanguage => $composableBuilder(
    column: $table.sourceLanguage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetLanguage => $composableBuilder(
    column: $table.targetLanguage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lessonId =>
      $composableBuilder(column: $table.lessonId, builder: (column) => column);

  GeneratedColumn<String> get lessonVersionId => $composableBuilder(
    column: $table.lessonVersionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get questionVersionId => $composableBuilder(
    column: $table.questionVersionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get selectedAnswer => $composableBuilder(
    column: $table.selectedAnswer,
    builder: (column) => column,
  );

  GeneratedColumn<int> get responseTimeMs => $composableBuilder(
    column: $table.responseTimeMs,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get usedHint =>
      $composableBuilder(column: $table.usedHint, builder: (column) => column);

  GeneratedColumn<bool> get isCorrectLocal => $composableBuilder(
    column: $table.isCorrectLocal,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get answeredAt => $composableBuilder(
    column: $table.answeredAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get lastTriedAt => $composableBuilder(
    column: $table.lastTriedAt,
    builder: (column) => column,
  );
}

class $$PendingAttemptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingAttemptsTable,
          PendingAttempt,
          $$PendingAttemptsTableFilterComposer,
          $$PendingAttemptsTableOrderingComposer,
          $$PendingAttemptsTableAnnotationComposer,
          $$PendingAttemptsTableCreateCompanionBuilder,
          $$PendingAttemptsTableUpdateCompanionBuilder,
          (
            PendingAttempt,
            BaseReferences<
              _$AppDatabase,
              $PendingAttemptsTable,
              PendingAttempt
            >,
          ),
          PendingAttempt,
          PrefetchHooks Function()
        > {
  $$PendingAttemptsTableTableManager(
    _$AppDatabase db,
    $PendingAttemptsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingAttemptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingAttemptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingAttemptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> clientRequestId = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<String> courseId = const Value.absent(),
                Value<String> sourceLanguage = const Value.absent(),
                Value<String> targetLanguage = const Value.absent(),
                Value<String> lessonId = const Value.absent(),
                Value<String> lessonVersionId = const Value.absent(),
                Value<String> questionId = const Value.absent(),
                Value<String> questionVersionId = const Value.absent(),
                Value<String> selectedAnswer = const Value.absent(),
                Value<int> responseTimeMs = const Value.absent(),
                Value<bool> usedHint = const Value.absent(),
                Value<bool> isCorrectLocal = const Value.absent(),
                Value<DateTime> answeredAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime?> lastTriedAt = const Value.absent(),
              }) => PendingAttemptsCompanion(
                id: id,
                clientRequestId: clientRequestId,
                deviceId: deviceId,
                courseId: courseId,
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage,
                lessonId: lessonId,
                lessonVersionId: lessonVersionId,
                questionId: questionId,
                questionVersionId: questionVersionId,
                selectedAnswer: selectedAnswer,
                responseTimeMs: responseTimeMs,
                usedHint: usedHint,
                isCorrectLocal: isCorrectLocal,
                answeredAt: answeredAt,
                createdAt: createdAt,
                status: status,
                retryCount: retryCount,
                lastError: lastError,
                lastTriedAt: lastTriedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String clientRequestId,
                required String deviceId,
                required String courseId,
                required String sourceLanguage,
                required String targetLanguage,
                required String lessonId,
                required String lessonVersionId,
                required String questionId,
                required String questionVersionId,
                required String selectedAnswer,
                required int responseTimeMs,
                required bool usedHint,
                required bool isCorrectLocal,
                required DateTime answeredAt,
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime?> lastTriedAt = const Value.absent(),
              }) => PendingAttemptsCompanion.insert(
                id: id,
                clientRequestId: clientRequestId,
                deviceId: deviceId,
                courseId: courseId,
                sourceLanguage: sourceLanguage,
                targetLanguage: targetLanguage,
                lessonId: lessonId,
                lessonVersionId: lessonVersionId,
                questionId: questionId,
                questionVersionId: questionVersionId,
                selectedAnswer: selectedAnswer,
                responseTimeMs: responseTimeMs,
                usedHint: usedHint,
                isCorrectLocal: isCorrectLocal,
                answeredAt: answeredAt,
                createdAt: createdAt,
                status: status,
                retryCount: retryCount,
                lastError: lastError,
                lastTriedAt: lastTriedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingAttemptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingAttemptsTable,
      PendingAttempt,
      $$PendingAttemptsTableFilterComposer,
      $$PendingAttemptsTableOrderingComposer,
      $$PendingAttemptsTableAnnotationComposer,
      $$PendingAttemptsTableCreateCompanionBuilder,
      $$PendingAttemptsTableUpdateCompanionBuilder,
      (
        PendingAttempt,
        BaseReferences<_$AppDatabase, $PendingAttemptsTable, PendingAttempt>,
      ),
      PendingAttempt,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CachedCoursesTableTableManager get cachedCourses =>
      $$CachedCoursesTableTableManager(_db, _db.cachedCourses);
  $$CachedLessonsTableTableManager get cachedLessons =>
      $$CachedLessonsTableTableManager(_db, _db.cachedLessons);
  $$CachedQuestionsTableTableManager get cachedQuestions =>
      $$CachedQuestionsTableTableManager(_db, _db.cachedQuestions);
  $$CachedQuestionOptionsTableTableManager get cachedQuestionOptions =>
      $$CachedQuestionOptionsTableTableManager(_db, _db.cachedQuestionOptions);
  $$PendingAttemptsTableTableManager get pendingAttempts =>
      $$PendingAttemptsTableTableManager(_db, _db.pendingAttempts);
}

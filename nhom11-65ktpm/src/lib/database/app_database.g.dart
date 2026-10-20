// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SubjectsTable extends Subjects with TableInfo<$SubjectsTable, Subject> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _subjectPkMeta =
      const VerificationMeta('subjectPk');
  @override
  late final GeneratedColumn<String> subjectPk = GeneratedColumn<String>(
      'subject_pk', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
      'code', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 30),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 150),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _lecturerMeta =
      const VerificationMeta('lecturer');
  @override
  late final GeneratedColumn<String> lecturer = GeneratedColumn<String>(
      'lecturer', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _semesterMeta =
      const VerificationMeta('semester');
  @override
  late final GeneratedColumn<String> semester = GeneratedColumn<String>(
      'semester', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _colorHexMeta =
      const VerificationMeta('colorHex');
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
      'color_hex', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('#1E88E5'));
  static const VerificationMeta _dateTimeModifiedMeta =
      const VerificationMeta('dateTimeModified');
  @override
  late final GeneratedColumn<DateTime> dateTimeModified =
      GeneratedColumn<DateTime>('date_time_modified', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [subjectPk, code, name, lecturer, semester, colorHex, dateTimeModified];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subjects';
  @override
  VerificationContext validateIntegrity(Insertable<Subject> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('subject_pk')) {
      context.handle(_subjectPkMeta,
          subjectPk.isAcceptableOrUnknown(data['subject_pk']!, _subjectPkMeta));
    } else if (isInserting) {
      context.missing(_subjectPkMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
          _codeMeta, code.isAcceptableOrUnknown(data['code']!, _codeMeta));
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('lecturer')) {
      context.handle(_lecturerMeta,
          lecturer.isAcceptableOrUnknown(data['lecturer']!, _lecturerMeta));
    }
    if (data.containsKey('semester')) {
      context.handle(_semesterMeta,
          semester.isAcceptableOrUnknown(data['semester']!, _semesterMeta));
    }
    if (data.containsKey('color_hex')) {
      context.handle(_colorHexMeta,
          colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta));
    }
    if (data.containsKey('date_time_modified')) {
      context.handle(
          _dateTimeModifiedMeta,
          dateTimeModified.isAcceptableOrUnknown(
              data['date_time_modified']!, _dateTimeModifiedMeta));
    } else if (isInserting) {
      context.missing(_dateTimeModifiedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {subjectPk};
  @override
  Subject map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Subject(
      subjectPk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subject_pk'])!,
      code: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}code'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      lecturer: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lecturer']),
      semester: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}semester']),
      colorHex: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color_hex'])!,
      dateTimeModified: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}date_time_modified'])!,
    );
  }

  @override
  $SubjectsTable createAlias(String alias) {
    return $SubjectsTable(attachedDatabase, alias);
  }
}

class Subject extends DataClass implements Insertable<Subject> {
  final String subjectPk;
  final String code;
  final String name;
  final String? lecturer;
  final String? semester;
  final String colorHex;
  final DateTime dateTimeModified;
  const Subject(
      {required this.subjectPk,
      required this.code,
      required this.name,
      this.lecturer,
      this.semester,
      required this.colorHex,
      required this.dateTimeModified});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['subject_pk'] = Variable<String>(subjectPk);
    map['code'] = Variable<String>(code);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || lecturer != null) {
      map['lecturer'] = Variable<String>(lecturer);
    }
    if (!nullToAbsent || semester != null) {
      map['semester'] = Variable<String>(semester);
    }
    map['color_hex'] = Variable<String>(colorHex);
    map['date_time_modified'] = Variable<DateTime>(dateTimeModified);
    return map;
  }

  SubjectsCompanion toCompanion(bool nullToAbsent) {
    return SubjectsCompanion(
      subjectPk: Value(subjectPk),
      code: Value(code),
      name: Value(name),
      lecturer: lecturer == null && nullToAbsent
          ? const Value.absent()
          : Value(lecturer),
      semester: semester == null && nullToAbsent
          ? const Value.absent()
          : Value(semester),
      colorHex: Value(colorHex),
      dateTimeModified: Value(dateTimeModified),
    );
  }

  factory Subject.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Subject(
      subjectPk: serializer.fromJson<String>(json['subjectPk']),
      code: serializer.fromJson<String>(json['code']),
      name: serializer.fromJson<String>(json['name']),
      lecturer: serializer.fromJson<String?>(json['lecturer']),
      semester: serializer.fromJson<String?>(json['semester']),
      colorHex: serializer.fromJson<String>(json['colorHex']),
      dateTimeModified: serializer.fromJson<DateTime>(json['dateTimeModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'subjectPk': serializer.toJson<String>(subjectPk),
      'code': serializer.toJson<String>(code),
      'name': serializer.toJson<String>(name),
      'lecturer': serializer.toJson<String?>(lecturer),
      'semester': serializer.toJson<String?>(semester),
      'colorHex': serializer.toJson<String>(colorHex),
      'dateTimeModified': serializer.toJson<DateTime>(dateTimeModified),
    };
  }

  Subject copyWith(
          {String? subjectPk,
          String? code,
          String? name,
          Value<String?> lecturer = const Value.absent(),
          Value<String?> semester = const Value.absent(),
          String? colorHex,
          DateTime? dateTimeModified}) =>
      Subject(
        subjectPk: subjectPk ?? this.subjectPk,
        code: code ?? this.code,
        name: name ?? this.name,
        lecturer: lecturer.present ? lecturer.value : this.lecturer,
        semester: semester.present ? semester.value : this.semester,
        colorHex: colorHex ?? this.colorHex,
        dateTimeModified: dateTimeModified ?? this.dateTimeModified,
      );
  Subject copyWithCompanion(SubjectsCompanion data) {
    return Subject(
      subjectPk: data.subjectPk.present ? data.subjectPk.value : this.subjectPk,
      code: data.code.present ? data.code.value : this.code,
      name: data.name.present ? data.name.value : this.name,
      lecturer: data.lecturer.present ? data.lecturer.value : this.lecturer,
      semester: data.semester.present ? data.semester.value : this.semester,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      dateTimeModified: data.dateTimeModified.present
          ? data.dateTimeModified.value
          : this.dateTimeModified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Subject(')
          ..write('subjectPk: $subjectPk, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('lecturer: $lecturer, ')
          ..write('semester: $semester, ')
          ..write('colorHex: $colorHex, ')
          ..write('dateTimeModified: $dateTimeModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      subjectPk, code, name, lecturer, semester, colorHex, dateTimeModified);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Subject &&
          other.subjectPk == this.subjectPk &&
          other.code == this.code &&
          other.name == this.name &&
          other.lecturer == this.lecturer &&
          other.semester == this.semester &&
          other.colorHex == this.colorHex &&
          other.dateTimeModified == this.dateTimeModified);
}

class SubjectsCompanion extends UpdateCompanion<Subject> {
  final Value<String> subjectPk;
  final Value<String> code;
  final Value<String> name;
  final Value<String?> lecturer;
  final Value<String?> semester;
  final Value<String> colorHex;
  final Value<DateTime> dateTimeModified;
  final Value<int> rowid;
  const SubjectsCompanion({
    this.subjectPk = const Value.absent(),
    this.code = const Value.absent(),
    this.name = const Value.absent(),
    this.lecturer = const Value.absent(),
    this.semester = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.dateTimeModified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SubjectsCompanion.insert({
    required String subjectPk,
    required String code,
    required String name,
    this.lecturer = const Value.absent(),
    this.semester = const Value.absent(),
    this.colorHex = const Value.absent(),
    required DateTime dateTimeModified,
    this.rowid = const Value.absent(),
  })  : subjectPk = Value(subjectPk),
        code = Value(code),
        name = Value(name),
        dateTimeModified = Value(dateTimeModified);
  static Insertable<Subject> custom({
    Expression<String>? subjectPk,
    Expression<String>? code,
    Expression<String>? name,
    Expression<String>? lecturer,
    Expression<String>? semester,
    Expression<String>? colorHex,
    Expression<DateTime>? dateTimeModified,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (subjectPk != null) 'subject_pk': subjectPk,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (lecturer != null) 'lecturer': lecturer,
      if (semester != null) 'semester': semester,
      if (colorHex != null) 'color_hex': colorHex,
      if (dateTimeModified != null) 'date_time_modified': dateTimeModified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SubjectsCompanion copyWith(
      {Value<String>? subjectPk,
      Value<String>? code,
      Value<String>? name,
      Value<String?>? lecturer,
      Value<String?>? semester,
      Value<String>? colorHex,
      Value<DateTime>? dateTimeModified,
      Value<int>? rowid}) {
    return SubjectsCompanion(
      subjectPk: subjectPk ?? this.subjectPk,
      code: code ?? this.code,
      name: name ?? this.name,
      lecturer: lecturer ?? this.lecturer,
      semester: semester ?? this.semester,
      colorHex: colorHex ?? this.colorHex,
      dateTimeModified: dateTimeModified ?? this.dateTimeModified,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (subjectPk.present) {
      map['subject_pk'] = Variable<String>(subjectPk.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (lecturer.present) {
      map['lecturer'] = Variable<String>(lecturer.value);
    }
    if (semester.present) {
      map['semester'] = Variable<String>(semester.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (dateTimeModified.present) {
      map['date_time_modified'] = Variable<DateTime>(dateTimeModified.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubjectsCompanion(')
          ..write('subjectPk: $subjectPk, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('lecturer: $lecturer, ')
          ..write('semester: $semester, ')
          ..write('colorHex: $colorHex, ')
          ..write('dateTimeModified: $dateTimeModified, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DocumentsTable extends Documents
    with TableInfo<$DocumentsTable, Document> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DocumentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _documentPkMeta =
      const VerificationMeta('documentPk');
  @override
  late final GeneratedColumn<String> documentPk = GeneratedColumn<String>(
      'document_pk', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 200),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _subjectFkMeta =
      const VerificationMeta('subjectFk');
  @override
  late final GeneratedColumn<String> subjectFk = GeneratedColumn<String>(
      'subject_fk', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES subjects (subject_pk)'));
  static const VerificationMeta _docTypeMeta =
      const VerificationMeta('docType');
  @override
  late final GeneratedColumn<String> docType = GeneratedColumn<String>(
      'doc_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('lecture'));
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _fileUrlMeta =
      const VerificationMeta('fileUrl');
  @override
  late final GeneratedColumn<String> fileUrl = GeneratedColumn<String>(
      'file_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _priorityMeta =
      const VerificationMeta('priority');
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
      'priority', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('active'));
  static const VerificationMeta _dateTimeCreatedMeta =
      const VerificationMeta('dateTimeCreated');
  @override
  late final GeneratedColumn<DateTime> dateTimeCreated =
      GeneratedColumn<DateTime>('date_time_created', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _dateTimeModifiedMeta =
      const VerificationMeta('dateTimeModified');
  @override
  late final GeneratedColumn<DateTime> dateTimeModified =
      GeneratedColumn<DateTime>('date_time_modified', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        documentPk,
        title,
        subjectFk,
        docType,
        content,
        fileUrl,
        priority,
        status,
        dateTimeCreated,
        dateTimeModified
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'documents';
  @override
  VerificationContext validateIntegrity(Insertable<Document> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('document_pk')) {
      context.handle(
          _documentPkMeta,
          documentPk.isAcceptableOrUnknown(
              data['document_pk']!, _documentPkMeta));
    } else if (isInserting) {
      context.missing(_documentPkMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('subject_fk')) {
      context.handle(_subjectFkMeta,
          subjectFk.isAcceptableOrUnknown(data['subject_fk']!, _subjectFkMeta));
    }
    if (data.containsKey('doc_type')) {
      context.handle(_docTypeMeta,
          docType.isAcceptableOrUnknown(data['doc_type']!, _docTypeMeta));
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    }
    if (data.containsKey('file_url')) {
      context.handle(_fileUrlMeta,
          fileUrl.isAcceptableOrUnknown(data['file_url']!, _fileUrlMeta));
    }
    if (data.containsKey('priority')) {
      context.handle(_priorityMeta,
          priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('date_time_created')) {
      context.handle(
          _dateTimeCreatedMeta,
          dateTimeCreated.isAcceptableOrUnknown(
              data['date_time_created']!, _dateTimeCreatedMeta));
    } else if (isInserting) {
      context.missing(_dateTimeCreatedMeta);
    }
    if (data.containsKey('date_time_modified')) {
      context.handle(
          _dateTimeModifiedMeta,
          dateTimeModified.isAcceptableOrUnknown(
              data['date_time_modified']!, _dateTimeModifiedMeta));
    } else if (isInserting) {
      context.missing(_dateTimeModifiedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {documentPk};
  @override
  Document map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Document(
      documentPk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}document_pk'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      subjectFk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subject_fk']),
      docType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}doc_type'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content']),
      fileUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_url']),
      priority: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}priority'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      dateTimeCreated: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}date_time_created'])!,
      dateTimeModified: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}date_time_modified'])!,
    );
  }

  @override
  $DocumentsTable createAlias(String alias) {
    return $DocumentsTable(attachedDatabase, alias);
  }
}

class Document extends DataClass implements Insertable<Document> {
  final String documentPk;
  final String title;
  final String? subjectFk;
  final String docType;
  final String? content;
  final String? fileUrl;
  final int priority;
  final String status;
  final DateTime dateTimeCreated;
  final DateTime dateTimeModified;
  const Document(
      {required this.documentPk,
      required this.title,
      this.subjectFk,
      required this.docType,
      this.content,
      this.fileUrl,
      required this.priority,
      required this.status,
      required this.dateTimeCreated,
      required this.dateTimeModified});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['document_pk'] = Variable<String>(documentPk);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || subjectFk != null) {
      map['subject_fk'] = Variable<String>(subjectFk);
    }
    map['doc_type'] = Variable<String>(docType);
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    if (!nullToAbsent || fileUrl != null) {
      map['file_url'] = Variable<String>(fileUrl);
    }
    map['priority'] = Variable<int>(priority);
    map['status'] = Variable<String>(status);
    map['date_time_created'] = Variable<DateTime>(dateTimeCreated);
    map['date_time_modified'] = Variable<DateTime>(dateTimeModified);
    return map;
  }

  DocumentsCompanion toCompanion(bool nullToAbsent) {
    return DocumentsCompanion(
      documentPk: Value(documentPk),
      title: Value(title),
      subjectFk: subjectFk == null && nullToAbsent
          ? const Value.absent()
          : Value(subjectFk),
      docType: Value(docType),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
      fileUrl: fileUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(fileUrl),
      priority: Value(priority),
      status: Value(status),
      dateTimeCreated: Value(dateTimeCreated),
      dateTimeModified: Value(dateTimeModified),
    );
  }

  factory Document.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Document(
      documentPk: serializer.fromJson<String>(json['documentPk']),
      title: serializer.fromJson<String>(json['title']),
      subjectFk: serializer.fromJson<String?>(json['subjectFk']),
      docType: serializer.fromJson<String>(json['docType']),
      content: serializer.fromJson<String?>(json['content']),
      fileUrl: serializer.fromJson<String?>(json['fileUrl']),
      priority: serializer.fromJson<int>(json['priority']),
      status: serializer.fromJson<String>(json['status']),
      dateTimeCreated: serializer.fromJson<DateTime>(json['dateTimeCreated']),
      dateTimeModified: serializer.fromJson<DateTime>(json['dateTimeModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'documentPk': serializer.toJson<String>(documentPk),
      'title': serializer.toJson<String>(title),
      'subjectFk': serializer.toJson<String?>(subjectFk),
      'docType': serializer.toJson<String>(docType),
      'content': serializer.toJson<String?>(content),
      'fileUrl': serializer.toJson<String?>(fileUrl),
      'priority': serializer.toJson<int>(priority),
      'status': serializer.toJson<String>(status),
      'dateTimeCreated': serializer.toJson<DateTime>(dateTimeCreated),
      'dateTimeModified': serializer.toJson<DateTime>(dateTimeModified),
    };
  }

  Document copyWith(
          {String? documentPk,
          String? title,
          Value<String?> subjectFk = const Value.absent(),
          String? docType,
          Value<String?> content = const Value.absent(),
          Value<String?> fileUrl = const Value.absent(),
          int? priority,
          String? status,
          DateTime? dateTimeCreated,
          DateTime? dateTimeModified}) =>
      Document(
        documentPk: documentPk ?? this.documentPk,
        title: title ?? this.title,
        subjectFk: subjectFk.present ? subjectFk.value : this.subjectFk,
        docType: docType ?? this.docType,
        content: content.present ? content.value : this.content,
        fileUrl: fileUrl.present ? fileUrl.value : this.fileUrl,
        priority: priority ?? this.priority,
        status: status ?? this.status,
        dateTimeCreated: dateTimeCreated ?? this.dateTimeCreated,
        dateTimeModified: dateTimeModified ?? this.dateTimeModified,
      );
  Document copyWithCompanion(DocumentsCompanion data) {
    return Document(
      documentPk:
          data.documentPk.present ? data.documentPk.value : this.documentPk,
      title: data.title.present ? data.title.value : this.title,
      subjectFk: data.subjectFk.present ? data.subjectFk.value : this.subjectFk,
      docType: data.docType.present ? data.docType.value : this.docType,
      content: data.content.present ? data.content.value : this.content,
      fileUrl: data.fileUrl.present ? data.fileUrl.value : this.fileUrl,
      priority: data.priority.present ? data.priority.value : this.priority,
      status: data.status.present ? data.status.value : this.status,
      dateTimeCreated: data.dateTimeCreated.present
          ? data.dateTimeCreated.value
          : this.dateTimeCreated,
      dateTimeModified: data.dateTimeModified.present
          ? data.dateTimeModified.value
          : this.dateTimeModified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Document(')
          ..write('documentPk: $documentPk, ')
          ..write('title: $title, ')
          ..write('subjectFk: $subjectFk, ')
          ..write('docType: $docType, ')
          ..write('content: $content, ')
          ..write('fileUrl: $fileUrl, ')
          ..write('priority: $priority, ')
          ..write('status: $status, ')
          ..write('dateTimeCreated: $dateTimeCreated, ')
          ..write('dateTimeModified: $dateTimeModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(documentPk, title, subjectFk, docType,
      content, fileUrl, priority, status, dateTimeCreated, dateTimeModified);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Document &&
          other.documentPk == this.documentPk &&
          other.title == this.title &&
          other.subjectFk == this.subjectFk &&
          other.docType == this.docType &&
          other.content == this.content &&
          other.fileUrl == this.fileUrl &&
          other.priority == this.priority &&
          other.status == this.status &&
          other.dateTimeCreated == this.dateTimeCreated &&
          other.dateTimeModified == this.dateTimeModified);
}

class DocumentsCompanion extends UpdateCompanion<Document> {
  final Value<String> documentPk;
  final Value<String> title;
  final Value<String?> subjectFk;
  final Value<String> docType;
  final Value<String?> content;
  final Value<String?> fileUrl;
  final Value<int> priority;
  final Value<String> status;
  final Value<DateTime> dateTimeCreated;
  final Value<DateTime> dateTimeModified;
  final Value<int> rowid;
  const DocumentsCompanion({
    this.documentPk = const Value.absent(),
    this.title = const Value.absent(),
    this.subjectFk = const Value.absent(),
    this.docType = const Value.absent(),
    this.content = const Value.absent(),
    this.fileUrl = const Value.absent(),
    this.priority = const Value.absent(),
    this.status = const Value.absent(),
    this.dateTimeCreated = const Value.absent(),
    this.dateTimeModified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DocumentsCompanion.insert({
    required String documentPk,
    required String title,
    this.subjectFk = const Value.absent(),
    this.docType = const Value.absent(),
    this.content = const Value.absent(),
    this.fileUrl = const Value.absent(),
    this.priority = const Value.absent(),
    this.status = const Value.absent(),
    required DateTime dateTimeCreated,
    required DateTime dateTimeModified,
    this.rowid = const Value.absent(),
  })  : documentPk = Value(documentPk),
        title = Value(title),
        dateTimeCreated = Value(dateTimeCreated),
        dateTimeModified = Value(dateTimeModified);
  static Insertable<Document> custom({
    Expression<String>? documentPk,
    Expression<String>? title,
    Expression<String>? subjectFk,
    Expression<String>? docType,
    Expression<String>? content,
    Expression<String>? fileUrl,
    Expression<int>? priority,
    Expression<String>? status,
    Expression<DateTime>? dateTimeCreated,
    Expression<DateTime>? dateTimeModified,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (documentPk != null) 'document_pk': documentPk,
      if (title != null) 'title': title,
      if (subjectFk != null) 'subject_fk': subjectFk,
      if (docType != null) 'doc_type': docType,
      if (content != null) 'content': content,
      if (fileUrl != null) 'file_url': fileUrl,
      if (priority != null) 'priority': priority,
      if (status != null) 'status': status,
      if (dateTimeCreated != null) 'date_time_created': dateTimeCreated,
      if (dateTimeModified != null) 'date_time_modified': dateTimeModified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DocumentsCompanion copyWith(
      {Value<String>? documentPk,
      Value<String>? title,
      Value<String?>? subjectFk,
      Value<String>? docType,
      Value<String?>? content,
      Value<String?>? fileUrl,
      Value<int>? priority,
      Value<String>? status,
      Value<DateTime>? dateTimeCreated,
      Value<DateTime>? dateTimeModified,
      Value<int>? rowid}) {
    return DocumentsCompanion(
      documentPk: documentPk ?? this.documentPk,
      title: title ?? this.title,
      subjectFk: subjectFk ?? this.subjectFk,
      docType: docType ?? this.docType,
      content: content ?? this.content,
      fileUrl: fileUrl ?? this.fileUrl,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dateTimeCreated: dateTimeCreated ?? this.dateTimeCreated,
      dateTimeModified: dateTimeModified ?? this.dateTimeModified,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (documentPk.present) {
      map['document_pk'] = Variable<String>(documentPk.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (subjectFk.present) {
      map['subject_fk'] = Variable<String>(subjectFk.value);
    }
    if (docType.present) {
      map['doc_type'] = Variable<String>(docType.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (fileUrl.present) {
      map['file_url'] = Variable<String>(fileUrl.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (dateTimeCreated.present) {
      map['date_time_created'] = Variable<DateTime>(dateTimeCreated.value);
    }
    if (dateTimeModified.present) {
      map['date_time_modified'] = Variable<DateTime>(dateTimeModified.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DocumentsCompanion(')
          ..write('documentPk: $documentPk, ')
          ..write('title: $title, ')
          ..write('subjectFk: $subjectFk, ')
          ..write('docType: $docType, ')
          ..write('content: $content, ')
          ..write('fileUrl: $fileUrl, ')
          ..write('priority: $priority, ')
          ..write('status: $status, ')
          ..write('dateTimeCreated: $dateTimeCreated, ')
          ..write('dateTimeModified: $dateTimeModified, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DeleteLogsTable extends DeleteLogs
    with TableInfo<$DeleteLogsTable, DeleteLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeleteLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deleteLogPkMeta =
      const VerificationMeta('deleteLogPk');
  @override
  late final GeneratedColumn<String> deleteLogPk = GeneratedColumn<String>(
      'delete_log_pk', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entryPkMeta =
      const VerificationMeta('entryPk');
  @override
  late final GeneratedColumn<String> entryPk = GeneratedColumn<String>(
      'entry_pk', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _itemTypeMeta =
      const VerificationMeta('itemType');
  @override
  late final GeneratedColumn<String> itemType = GeneratedColumn<String>(
      'item_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dateTimeModifiedMeta =
      const VerificationMeta('dateTimeModified');
  @override
  late final GeneratedColumn<DateTime> dateTimeModified =
      GeneratedColumn<DateTime>('date_time_modified', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [deleteLogPk, entryPk, itemType, dateTimeModified];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'delete_logs';
  @override
  VerificationContext validateIntegrity(Insertable<DeleteLog> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('delete_log_pk')) {
      context.handle(
          _deleteLogPkMeta,
          deleteLogPk.isAcceptableOrUnknown(
              data['delete_log_pk']!, _deleteLogPkMeta));
    } else if (isInserting) {
      context.missing(_deleteLogPkMeta);
    }
    if (data.containsKey('entry_pk')) {
      context.handle(_entryPkMeta,
          entryPk.isAcceptableOrUnknown(data['entry_pk']!, _entryPkMeta));
    } else if (isInserting) {
      context.missing(_entryPkMeta);
    }
    if (data.containsKey('item_type')) {
      context.handle(_itemTypeMeta,
          itemType.isAcceptableOrUnknown(data['item_type']!, _itemTypeMeta));
    } else if (isInserting) {
      context.missing(_itemTypeMeta);
    }
    if (data.containsKey('date_time_modified')) {
      context.handle(
          _dateTimeModifiedMeta,
          dateTimeModified.isAcceptableOrUnknown(
              data['date_time_modified']!, _dateTimeModifiedMeta));
    } else if (isInserting) {
      context.missing(_dateTimeModifiedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deleteLogPk};
  @override
  DeleteLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeleteLog(
      deleteLogPk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}delete_log_pk'])!,
      entryPk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entry_pk'])!,
      itemType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}item_type'])!,
      dateTimeModified: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}date_time_modified'])!,
    );
  }

  @override
  $DeleteLogsTable createAlias(String alias) {
    return $DeleteLogsTable(attachedDatabase, alias);
  }
}

class DeleteLog extends DataClass implements Insertable<DeleteLog> {
  final String deleteLogPk;
  final String entryPk;
  final String itemType;
  final DateTime dateTimeModified;
  const DeleteLog(
      {required this.deleteLogPk,
      required this.entryPk,
      required this.itemType,
      required this.dateTimeModified});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['delete_log_pk'] = Variable<String>(deleteLogPk);
    map['entry_pk'] = Variable<String>(entryPk);
    map['item_type'] = Variable<String>(itemType);
    map['date_time_modified'] = Variable<DateTime>(dateTimeModified);
    return map;
  }

  DeleteLogsCompanion toCompanion(bool nullToAbsent) {
    return DeleteLogsCompanion(
      deleteLogPk: Value(deleteLogPk),
      entryPk: Value(entryPk),
      itemType: Value(itemType),
      dateTimeModified: Value(dateTimeModified),
    );
  }

  factory DeleteLog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeleteLog(
      deleteLogPk: serializer.fromJson<String>(json['deleteLogPk']),
      entryPk: serializer.fromJson<String>(json['entryPk']),
      itemType: serializer.fromJson<String>(json['itemType']),
      dateTimeModified: serializer.fromJson<DateTime>(json['dateTimeModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deleteLogPk': serializer.toJson<String>(deleteLogPk),
      'entryPk': serializer.toJson<String>(entryPk),
      'itemType': serializer.toJson<String>(itemType),
      'dateTimeModified': serializer.toJson<DateTime>(dateTimeModified),
    };
  }

  DeleteLog copyWith(
          {String? deleteLogPk,
          String? entryPk,
          String? itemType,
          DateTime? dateTimeModified}) =>
      DeleteLog(
        deleteLogPk: deleteLogPk ?? this.deleteLogPk,
        entryPk: entryPk ?? this.entryPk,
        itemType: itemType ?? this.itemType,
        dateTimeModified: dateTimeModified ?? this.dateTimeModified,
      );
  DeleteLog copyWithCompanion(DeleteLogsCompanion data) {
    return DeleteLog(
      deleteLogPk:
          data.deleteLogPk.present ? data.deleteLogPk.value : this.deleteLogPk,
      entryPk: data.entryPk.present ? data.entryPk.value : this.entryPk,
      itemType: data.itemType.present ? data.itemType.value : this.itemType,
      dateTimeModified: data.dateTimeModified.present
          ? data.dateTimeModified.value
          : this.dateTimeModified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeleteLog(')
          ..write('deleteLogPk: $deleteLogPk, ')
          ..write('entryPk: $entryPk, ')
          ..write('itemType: $itemType, ')
          ..write('dateTimeModified: $dateTimeModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(deleteLogPk, entryPk, itemType, dateTimeModified);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeleteLog &&
          other.deleteLogPk == this.deleteLogPk &&
          other.entryPk == this.entryPk &&
          other.itemType == this.itemType &&
          other.dateTimeModified == this.dateTimeModified);
}

class DeleteLogsCompanion extends UpdateCompanion<DeleteLog> {
  final Value<String> deleteLogPk;
  final Value<String> entryPk;
  final Value<String> itemType;
  final Value<DateTime> dateTimeModified;
  final Value<int> rowid;
  const DeleteLogsCompanion({
    this.deleteLogPk = const Value.absent(),
    this.entryPk = const Value.absent(),
    this.itemType = const Value.absent(),
    this.dateTimeModified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DeleteLogsCompanion.insert({
    required String deleteLogPk,
    required String entryPk,
    required String itemType,
    required DateTime dateTimeModified,
    this.rowid = const Value.absent(),
  })  : deleteLogPk = Value(deleteLogPk),
        entryPk = Value(entryPk),
        itemType = Value(itemType),
        dateTimeModified = Value(dateTimeModified);
  static Insertable<DeleteLog> custom({
    Expression<String>? deleteLogPk,
    Expression<String>? entryPk,
    Expression<String>? itemType,
    Expression<DateTime>? dateTimeModified,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deleteLogPk != null) 'delete_log_pk': deleteLogPk,
      if (entryPk != null) 'entry_pk': entryPk,
      if (itemType != null) 'item_type': itemType,
      if (dateTimeModified != null) 'date_time_modified': dateTimeModified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DeleteLogsCompanion copyWith(
      {Value<String>? deleteLogPk,
      Value<String>? entryPk,
      Value<String>? itemType,
      Value<DateTime>? dateTimeModified,
      Value<int>? rowid}) {
    return DeleteLogsCompanion(
      deleteLogPk: deleteLogPk ?? this.deleteLogPk,
      entryPk: entryPk ?? this.entryPk,
      itemType: itemType ?? this.itemType,
      dateTimeModified: dateTimeModified ?? this.dateTimeModified,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deleteLogPk.present) {
      map['delete_log_pk'] = Variable<String>(deleteLogPk.value);
    }
    if (entryPk.present) {
      map['entry_pk'] = Variable<String>(entryPk.value);
    }
    if (itemType.present) {
      map['item_type'] = Variable<String>(itemType.value);
    }
    if (dateTimeModified.present) {
      map['date_time_modified'] = Variable<DateTime>(dateTimeModified.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeleteLogsCompanion(')
          ..write('deleteLogPk: $deleteLogPk, ')
          ..write('entryPk: $entryPk, ')
          ..write('itemType: $itemType, ')
          ..write('dateTimeModified: $dateTimeModified, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _settingsPkMeta =
      const VerificationMeta('settingsPk');
  @override
  late final GeneratedColumn<String> settingsPk = GeneratedColumn<String>(
      'settings_pk', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _settingsJSONMeta =
      const VerificationMeta('settingsJSON');
  @override
  late final GeneratedColumn<String> settingsJSON = GeneratedColumn<String>(
      'settings_j_s_o_n', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dateTimeModifiedMeta =
      const VerificationMeta('dateTimeModified');
  @override
  late final GeneratedColumn<DateTime> dateTimeModified =
      GeneratedColumn<DateTime>('date_time_modified', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [settingsPk, settingsJSON, dateTimeModified];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(Insertable<AppSetting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('settings_pk')) {
      context.handle(
          _settingsPkMeta,
          settingsPk.isAcceptableOrUnknown(
              data['settings_pk']!, _settingsPkMeta));
    } else if (isInserting) {
      context.missing(_settingsPkMeta);
    }
    if (data.containsKey('settings_j_s_o_n')) {
      context.handle(
          _settingsJSONMeta,
          settingsJSON.isAcceptableOrUnknown(
              data['settings_j_s_o_n']!, _settingsJSONMeta));
    } else if (isInserting) {
      context.missing(_settingsJSONMeta);
    }
    if (data.containsKey('date_time_modified')) {
      context.handle(
          _dateTimeModifiedMeta,
          dateTimeModified.isAcceptableOrUnknown(
              data['date_time_modified']!, _dateTimeModifiedMeta));
    } else if (isInserting) {
      context.missing(_dateTimeModifiedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {settingsPk};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      settingsPk: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}settings_pk'])!,
      settingsJSON: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}settings_j_s_o_n'])!,
      dateTimeModified: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}date_time_modified'])!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String settingsPk;
  final String settingsJSON;
  final DateTime dateTimeModified;
  const AppSetting(
      {required this.settingsPk,
      required this.settingsJSON,
      required this.dateTimeModified});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['settings_pk'] = Variable<String>(settingsPk);
    map['settings_j_s_o_n'] = Variable<String>(settingsJSON);
    map['date_time_modified'] = Variable<DateTime>(dateTimeModified);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      settingsPk: Value(settingsPk),
      settingsJSON: Value(settingsJSON),
      dateTimeModified: Value(dateTimeModified),
    );
  }

  factory AppSetting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      settingsPk: serializer.fromJson<String>(json['settingsPk']),
      settingsJSON: serializer.fromJson<String>(json['settingsJSON']),
      dateTimeModified: serializer.fromJson<DateTime>(json['dateTimeModified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'settingsPk': serializer.toJson<String>(settingsPk),
      'settingsJSON': serializer.toJson<String>(settingsJSON),
      'dateTimeModified': serializer.toJson<DateTime>(dateTimeModified),
    };
  }

  AppSetting copyWith(
          {String? settingsPk,
          String? settingsJSON,
          DateTime? dateTimeModified}) =>
      AppSetting(
        settingsPk: settingsPk ?? this.settingsPk,
        settingsJSON: settingsJSON ?? this.settingsJSON,
        dateTimeModified: dateTimeModified ?? this.dateTimeModified,
      );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      settingsPk:
          data.settingsPk.present ? data.settingsPk.value : this.settingsPk,
      settingsJSON: data.settingsJSON.present
          ? data.settingsJSON.value
          : this.settingsJSON,
      dateTimeModified: data.dateTimeModified.present
          ? data.dateTimeModified.value
          : this.dateTimeModified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('settingsPk: $settingsPk, ')
          ..write('settingsJSON: $settingsJSON, ')
          ..write('dateTimeModified: $dateTimeModified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(settingsPk, settingsJSON, dateTimeModified);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.settingsPk == this.settingsPk &&
          other.settingsJSON == this.settingsJSON &&
          other.dateTimeModified == this.dateTimeModified);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> settingsPk;
  final Value<String> settingsJSON;
  final Value<DateTime> dateTimeModified;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.settingsPk = const Value.absent(),
    this.settingsJSON = const Value.absent(),
    this.dateTimeModified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String settingsPk,
    required String settingsJSON,
    required DateTime dateTimeModified,
    this.rowid = const Value.absent(),
  })  : settingsPk = Value(settingsPk),
        settingsJSON = Value(settingsJSON),
        dateTimeModified = Value(dateTimeModified);
  static Insertable<AppSetting> custom({
    Expression<String>? settingsPk,
    Expression<String>? settingsJSON,
    Expression<DateTime>? dateTimeModified,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (settingsPk != null) 'settings_pk': settingsPk,
      if (settingsJSON != null) 'settings_j_s_o_n': settingsJSON,
      if (dateTimeModified != null) 'date_time_modified': dateTimeModified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith(
      {Value<String>? settingsPk,
      Value<String>? settingsJSON,
      Value<DateTime>? dateTimeModified,
      Value<int>? rowid}) {
    return AppSettingsCompanion(
      settingsPk: settingsPk ?? this.settingsPk,
      settingsJSON: settingsJSON ?? this.settingsJSON,
      dateTimeModified: dateTimeModified ?? this.dateTimeModified,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (settingsPk.present) {
      map['settings_pk'] = Variable<String>(settingsPk.value);
    }
    if (settingsJSON.present) {
      map['settings_j_s_o_n'] = Variable<String>(settingsJSON.value);
    }
    if (dateTimeModified.present) {
      map['date_time_modified'] = Variable<DateTime>(dateTimeModified.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('settingsPk: $settingsPk, ')
          ..write('settingsJSON: $settingsJSON, ')
          ..write('dateTimeModified: $dateTimeModified, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SubjectsTable subjects = $SubjectsTable(this);
  late final $DocumentsTable documents = $DocumentsTable(this);
  late final $DeleteLogsTable deleteLogs = $DeleteLogsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final DocumentDao documentDao = DocumentDao(this as AppDatabase);
  late final SubjectDao subjectDao = SubjectDao(this as AppDatabase);
  late final DeleteLogDao deleteLogDao = DeleteLogDao(this as AppDatabase);
  late final SettingsDao settingsDao = SettingsDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [subjects, documents, deleteLogs, appSettings];
}

typedef $$SubjectsTableCreateCompanionBuilder = SubjectsCompanion Function({
  required String subjectPk,
  required String code,
  required String name,
  Value<String?> lecturer,
  Value<String?> semester,
  Value<String> colorHex,
  required DateTime dateTimeModified,
  Value<int> rowid,
});
typedef $$SubjectsTableUpdateCompanionBuilder = SubjectsCompanion Function({
  Value<String> subjectPk,
  Value<String> code,
  Value<String> name,
  Value<String?> lecturer,
  Value<String?> semester,
  Value<String> colorHex,
  Value<DateTime> dateTimeModified,
  Value<int> rowid,
});

final class $$SubjectsTableReferences
    extends BaseReferences<_$AppDatabase, $SubjectsTable, Subject> {
  $$SubjectsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$DocumentsTable, List<Document>>
      _documentsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.documents,
              aliasName: $_aliasNameGenerator(
                  db.subjects.subjectPk, db.documents.subjectFk));

  $$DocumentsTableProcessedTableManager get documentsRefs {
    final manager = $$DocumentsTableTableManager($_db, $_db.documents)
        .filter((f) => f.subjectFk.subjectPk($_item.subjectPk));

    final cache = $_typedResult.readTableOrNull(_documentsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$SubjectsTableFilterComposer
    extends Composer<_$AppDatabase, $SubjectsTable> {
  $$SubjectsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get subjectPk => $composableBuilder(
      column: $table.subjectPk, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lecturer => $composableBuilder(
      column: $table.lecturer, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get semester => $composableBuilder(
      column: $table.semester, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get colorHex => $composableBuilder(
      column: $table.colorHex, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dateTimeModified => $composableBuilder(
      column: $table.dateTimeModified,
      builder: (column) => ColumnFilters(column));

  Expression<bool> documentsRefs(
      Expression<bool> Function($$DocumentsTableFilterComposer f) f) {
    final $$DocumentsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.subjectPk,
        referencedTable: $db.documents,
        getReferencedColumn: (t) => t.subjectFk,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DocumentsTableFilterComposer(
              $db: $db,
              $table: $db.documents,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$SubjectsTableOrderingComposer
    extends Composer<_$AppDatabase, $SubjectsTable> {
  $$SubjectsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get subjectPk => $composableBuilder(
      column: $table.subjectPk, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lecturer => $composableBuilder(
      column: $table.lecturer, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get semester => $composableBuilder(
      column: $table.semester, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get colorHex => $composableBuilder(
      column: $table.colorHex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dateTimeModified => $composableBuilder(
      column: $table.dateTimeModified,
      builder: (column) => ColumnOrderings(column));
}

class $$SubjectsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubjectsTable> {
  $$SubjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get subjectPk =>
      $composableBuilder(column: $table.subjectPk, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get lecturer =>
      $composableBuilder(column: $table.lecturer, builder: (column) => column);

  GeneratedColumn<String> get semester =>
      $composableBuilder(column: $table.semester, builder: (column) => column);

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<DateTime> get dateTimeModified => $composableBuilder(
      column: $table.dateTimeModified, builder: (column) => column);

  Expression<T> documentsRefs<T extends Object>(
      Expression<T> Function($$DocumentsTableAnnotationComposer a) f) {
    final $$DocumentsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.subjectPk,
        referencedTable: $db.documents,
        getReferencedColumn: (t) => t.subjectFk,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DocumentsTableAnnotationComposer(
              $db: $db,
              $table: $db.documents,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$SubjectsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SubjectsTable,
    Subject,
    $$SubjectsTableFilterComposer,
    $$SubjectsTableOrderingComposer,
    $$SubjectsTableAnnotationComposer,
    $$SubjectsTableCreateCompanionBuilder,
    $$SubjectsTableUpdateCompanionBuilder,
    (Subject, $$SubjectsTableReferences),
    Subject,
    PrefetchHooks Function({bool documentsRefs})> {
  $$SubjectsTableTableManager(_$AppDatabase db, $SubjectsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> subjectPk = const Value.absent(),
            Value<String> code = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> lecturer = const Value.absent(),
            Value<String?> semester = const Value.absent(),
            Value<String> colorHex = const Value.absent(),
            Value<DateTime> dateTimeModified = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SubjectsCompanion(
            subjectPk: subjectPk,
            code: code,
            name: name,
            lecturer: lecturer,
            semester: semester,
            colorHex: colorHex,
            dateTimeModified: dateTimeModified,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String subjectPk,
            required String code,
            required String name,
            Value<String?> lecturer = const Value.absent(),
            Value<String?> semester = const Value.absent(),
            Value<String> colorHex = const Value.absent(),
            required DateTime dateTimeModified,
            Value<int> rowid = const Value.absent(),
          }) =>
              SubjectsCompanion.insert(
            subjectPk: subjectPk,
            code: code,
            name: name,
            lecturer: lecturer,
            semester: semester,
            colorHex: colorHex,
            dateTimeModified: dateTimeModified,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$SubjectsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({documentsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (documentsRefs) db.documents],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (documentsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$SubjectsTableReferences._documentsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SubjectsTableReferences(db, table, p0)
                                .documentsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.subjectFk == item.subjectPk),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$SubjectsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SubjectsTable,
    Subject,
    $$SubjectsTableFilterComposer,
    $$SubjectsTableOrderingComposer,
    $$SubjectsTableAnnotationComposer,
    $$SubjectsTableCreateCompanionBuilder,
    $$SubjectsTableUpdateCompanionBuilder,
    (Subject, $$SubjectsTableReferences),
    Subject,
    PrefetchHooks Function({bool documentsRefs})>;
typedef $$DocumentsTableCreateCompanionBuilder = DocumentsCompanion Function({
  required String documentPk,
  required String title,
  Value<String?> subjectFk,
  Value<String> docType,
  Value<String?> content,
  Value<String?> fileUrl,
  Value<int> priority,
  Value<String> status,
  required DateTime dateTimeCreated,
  required DateTime dateTimeModified,
  Value<int> rowid,
});
typedef $$DocumentsTableUpdateCompanionBuilder = DocumentsCompanion Function({
  Value<String> documentPk,
  Value<String> title,
  Value<String?> subjectFk,
  Value<String> docType,
  Value<String?> content,
  Value<String?> fileUrl,
  Value<int> priority,
  Value<String> status,
  Value<DateTime> dateTimeCreated,
  Value<DateTime> dateTimeModified,
  Value<int> rowid,
});

final class $$DocumentsTableReferences
    extends BaseReferences<_$AppDatabase, $DocumentsTable, Document> {
  $$DocumentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SubjectsTable _subjectFkTable(_$AppDatabase db) =>
      db.subjects.createAlias(
          $_aliasNameGenerator(db.documents.subjectFk, db.subjects.subjectPk));

  $$SubjectsTableProcessedTableManager? get subjectFk {
    if ($_item.subjectFk == null) return null;
    final manager = $$SubjectsTableTableManager($_db, $_db.subjects)
        .filter((f) => f.subjectPk($_item.subjectFk!));
    final item = $_typedResult.readTableOrNull(_subjectFkTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$DocumentsTableFilterComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get documentPk => $composableBuilder(
      column: $table.documentPk, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get docType => $composableBuilder(
      column: $table.docType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fileUrl => $composableBuilder(
      column: $table.fileUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dateTimeCreated => $composableBuilder(
      column: $table.dateTimeCreated,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dateTimeModified => $composableBuilder(
      column: $table.dateTimeModified,
      builder: (column) => ColumnFilters(column));

  $$SubjectsTableFilterComposer get subjectFk {
    final $$SubjectsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.subjectFk,
        referencedTable: $db.subjects,
        getReferencedColumn: (t) => t.subjectPk,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SubjectsTableFilterComposer(
              $db: $db,
              $table: $db.subjects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DocumentsTableOrderingComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get documentPk => $composableBuilder(
      column: $table.documentPk, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get docType => $composableBuilder(
      column: $table.docType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fileUrl => $composableBuilder(
      column: $table.fileUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dateTimeCreated => $composableBuilder(
      column: $table.dateTimeCreated,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dateTimeModified => $composableBuilder(
      column: $table.dateTimeModified,
      builder: (column) => ColumnOrderings(column));

  $$SubjectsTableOrderingComposer get subjectFk {
    final $$SubjectsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.subjectFk,
        referencedTable: $db.subjects,
        getReferencedColumn: (t) => t.subjectPk,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SubjectsTableOrderingComposer(
              $db: $db,
              $table: $db.subjects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DocumentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get documentPk => $composableBuilder(
      column: $table.documentPk, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get docType =>
      $composableBuilder(column: $table.docType, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get fileUrl =>
      $composableBuilder(column: $table.fileUrl, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get dateTimeCreated => $composableBuilder(
      column: $table.dateTimeCreated, builder: (column) => column);

  GeneratedColumn<DateTime> get dateTimeModified => $composableBuilder(
      column: $table.dateTimeModified, builder: (column) => column);

  $$SubjectsTableAnnotationComposer get subjectFk {
    final $$SubjectsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.subjectFk,
        referencedTable: $db.subjects,
        getReferencedColumn: (t) => t.subjectPk,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SubjectsTableAnnotationComposer(
              $db: $db,
              $table: $db.subjects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DocumentsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DocumentsTable,
    Document,
    $$DocumentsTableFilterComposer,
    $$DocumentsTableOrderingComposer,
    $$DocumentsTableAnnotationComposer,
    $$DocumentsTableCreateCompanionBuilder,
    $$DocumentsTableUpdateCompanionBuilder,
    (Document, $$DocumentsTableReferences),
    Document,
    PrefetchHooks Function({bool subjectFk})> {
  $$DocumentsTableTableManager(_$AppDatabase db, $DocumentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DocumentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DocumentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DocumentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> documentPk = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> subjectFk = const Value.absent(),
            Value<String> docType = const Value.absent(),
            Value<String?> content = const Value.absent(),
            Value<String?> fileUrl = const Value.absent(),
            Value<int> priority = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<DateTime> dateTimeCreated = const Value.absent(),
            Value<DateTime> dateTimeModified = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DocumentsCompanion(
            documentPk: documentPk,
            title: title,
            subjectFk: subjectFk,
            docType: docType,
            content: content,
            fileUrl: fileUrl,
            priority: priority,
            status: status,
            dateTimeCreated: dateTimeCreated,
            dateTimeModified: dateTimeModified,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String documentPk,
            required String title,
            Value<String?> subjectFk = const Value.absent(),
            Value<String> docType = const Value.absent(),
            Value<String?> content = const Value.absent(),
            Value<String?> fileUrl = const Value.absent(),
            Value<int> priority = const Value.absent(),
            Value<String> status = const Value.absent(),
            required DateTime dateTimeCreated,
            required DateTime dateTimeModified,
            Value<int> rowid = const Value.absent(),
          }) =>
              DocumentsCompanion.insert(
            documentPk: documentPk,
            title: title,
            subjectFk: subjectFk,
            docType: docType,
            content: content,
            fileUrl: fileUrl,
            priority: priority,
            status: status,
            dateTimeCreated: dateTimeCreated,
            dateTimeModified: dateTimeModified,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$DocumentsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({subjectFk = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (subjectFk) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.subjectFk,
                    referencedTable:
                        $$DocumentsTableReferences._subjectFkTable(db),
                    referencedColumn: $$DocumentsTableReferences
                        ._subjectFkTable(db)
                        .subjectPk,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$DocumentsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DocumentsTable,
    Document,
    $$DocumentsTableFilterComposer,
    $$DocumentsTableOrderingComposer,
    $$DocumentsTableAnnotationComposer,
    $$DocumentsTableCreateCompanionBuilder,
    $$DocumentsTableUpdateCompanionBuilder,
    (Document, $$DocumentsTableReferences),
    Document,
    PrefetchHooks Function({bool subjectFk})>;
typedef $$DeleteLogsTableCreateCompanionBuilder = DeleteLogsCompanion Function({
  required String deleteLogPk,
  required String entryPk,
  required String itemType,
  required DateTime dateTimeModified,
  Value<int> rowid,
});
typedef $$DeleteLogsTableUpdateCompanionBuilder = DeleteLogsCompanion Function({
  Value<String> deleteLogPk,
  Value<String> entryPk,
  Value<String> itemType,
  Value<DateTime> dateTimeModified,
  Value<int> rowid,
});

class $$DeleteLogsTableFilterComposer
    extends Composer<_$AppDatabase, $DeleteLogsTable> {
  $$DeleteLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get deleteLogPk => $composableBuilder(
      column: $table.deleteLogPk, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entryPk => $composableBuilder(
      column: $table.entryPk, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get itemType => $composableBuilder(
      column: $table.itemType, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dateTimeModified => $composableBuilder(
      column: $table.dateTimeModified,
      builder: (column) => ColumnFilters(column));
}

class $$DeleteLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $DeleteLogsTable> {
  $$DeleteLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get deleteLogPk => $composableBuilder(
      column: $table.deleteLogPk, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entryPk => $composableBuilder(
      column: $table.entryPk, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get itemType => $composableBuilder(
      column: $table.itemType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dateTimeModified => $composableBuilder(
      column: $table.dateTimeModified,
      builder: (column) => ColumnOrderings(column));
}

class $$DeleteLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DeleteLogsTable> {
  $$DeleteLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get deleteLogPk => $composableBuilder(
      column: $table.deleteLogPk, builder: (column) => column);

  GeneratedColumn<String> get entryPk =>
      $composableBuilder(column: $table.entryPk, builder: (column) => column);

  GeneratedColumn<String> get itemType =>
      $composableBuilder(column: $table.itemType, builder: (column) => column);

  GeneratedColumn<DateTime> get dateTimeModified => $composableBuilder(
      column: $table.dateTimeModified, builder: (column) => column);
}

class $$DeleteLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DeleteLogsTable,
    DeleteLog,
    $$DeleteLogsTableFilterComposer,
    $$DeleteLogsTableOrderingComposer,
    $$DeleteLogsTableAnnotationComposer,
    $$DeleteLogsTableCreateCompanionBuilder,
    $$DeleteLogsTableUpdateCompanionBuilder,
    (DeleteLog, BaseReferences<_$AppDatabase, $DeleteLogsTable, DeleteLog>),
    DeleteLog,
    PrefetchHooks Function()> {
  $$DeleteLogsTableTableManager(_$AppDatabase db, $DeleteLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeleteLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeleteLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DeleteLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> deleteLogPk = const Value.absent(),
            Value<String> entryPk = const Value.absent(),
            Value<String> itemType = const Value.absent(),
            Value<DateTime> dateTimeModified = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DeleteLogsCompanion(
            deleteLogPk: deleteLogPk,
            entryPk: entryPk,
            itemType: itemType,
            dateTimeModified: dateTimeModified,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String deleteLogPk,
            required String entryPk,
            required String itemType,
            required DateTime dateTimeModified,
            Value<int> rowid = const Value.absent(),
          }) =>
              DeleteLogsCompanion.insert(
            deleteLogPk: deleteLogPk,
            entryPk: entryPk,
            itemType: itemType,
            dateTimeModified: dateTimeModified,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DeleteLogsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DeleteLogsTable,
    DeleteLog,
    $$DeleteLogsTableFilterComposer,
    $$DeleteLogsTableOrderingComposer,
    $$DeleteLogsTableAnnotationComposer,
    $$DeleteLogsTableCreateCompanionBuilder,
    $$DeleteLogsTableUpdateCompanionBuilder,
    (DeleteLog, BaseReferences<_$AppDatabase, $DeleteLogsTable, DeleteLog>),
    DeleteLog,
    PrefetchHooks Function()>;
typedef $$AppSettingsTableCreateCompanionBuilder = AppSettingsCompanion
    Function({
  required String settingsPk,
  required String settingsJSON,
  required DateTime dateTimeModified,
  Value<int> rowid,
});
typedef $$AppSettingsTableUpdateCompanionBuilder = AppSettingsCompanion
    Function({
  Value<String> settingsPk,
  Value<String> settingsJSON,
  Value<DateTime> dateTimeModified,
  Value<int> rowid,
});

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get settingsPk => $composableBuilder(
      column: $table.settingsPk, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get settingsJSON => $composableBuilder(
      column: $table.settingsJSON, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dateTimeModified => $composableBuilder(
      column: $table.dateTimeModified,
      builder: (column) => ColumnFilters(column));
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get settingsPk => $composableBuilder(
      column: $table.settingsPk, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get settingsJSON => $composableBuilder(
      column: $table.settingsJSON,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dateTimeModified => $composableBuilder(
      column: $table.dateTimeModified,
      builder: (column) => ColumnOrderings(column));
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get settingsPk => $composableBuilder(
      column: $table.settingsPk, builder: (column) => column);

  GeneratedColumn<String> get settingsJSON => $composableBuilder(
      column: $table.settingsJSON, builder: (column) => column);

  GeneratedColumn<DateTime> get dateTimeModified => $composableBuilder(
      column: $table.dateTimeModified, builder: (column) => column);
}

class $$AppSettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AppSettingsTable,
    AppSetting,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableAnnotationComposer,
    $$AppSettingsTableCreateCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder,
    (AppSetting, BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>),
    AppSetting,
    PrefetchHooks Function()> {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> settingsPk = const Value.absent(),
            Value<String> settingsJSON = const Value.absent(),
            Value<DateTime> dateTimeModified = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AppSettingsCompanion(
            settingsPk: settingsPk,
            settingsJSON: settingsJSON,
            dateTimeModified: dateTimeModified,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String settingsPk,
            required String settingsJSON,
            required DateTime dateTimeModified,
            Value<int> rowid = const Value.absent(),
          }) =>
              AppSettingsCompanion.insert(
            settingsPk: settingsPk,
            settingsJSON: settingsJSON,
            dateTimeModified: dateTimeModified,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AppSettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AppSettingsTable,
    AppSetting,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableAnnotationComposer,
    $$AppSettingsTableCreateCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder,
    (AppSetting, BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>),
    AppSetting,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SubjectsTableTableManager get subjects =>
      $$SubjectsTableTableManager(_db, _db.subjects);
  $$DocumentsTableTableManager get documents =>
      $$DocumentsTableTableManager(_db, _db.documents);
  $$DeleteLogsTableTableManager get deleteLogs =>
      $$DeleteLogsTableTableManager(_db, _db.deleteLogs);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}

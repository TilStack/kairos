// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SavesTable extends Saves with TableInfo<$SavesTable, SaveRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _arcIdMeta = const VerificationMeta('arcId');
  @override
  late final GeneratedColumn<String> arcId = GeneratedColumn<String>(
    'arc_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateJsonMeta = const VerificationMeta(
    'stateJson',
  );
  @override
  late final GeneratedColumn<String> stateJson = GeneratedColumn<String>(
    'state_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [arcId, stateJson, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saves';
  @override
  VerificationContext validateIntegrity(
    Insertable<SaveRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('arc_id')) {
      context.handle(
        _arcIdMeta,
        arcId.isAcceptableOrUnknown(data['arc_id']!, _arcIdMeta),
      );
    } else if (isInserting) {
      context.missing(_arcIdMeta);
    }
    if (data.containsKey('state_json')) {
      context.handle(
        _stateJsonMeta,
        stateJson.isAcceptableOrUnknown(data['state_json']!, _stateJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_stateJsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {arcId};
  @override
  SaveRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SaveRow(
      arcId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}arc_id'],
      )!,
      stateJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state_json'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SavesTable createAlias(String alias) {
    return $SavesTable(attachedDatabase, alias);
  }
}

class SaveRow extends DataClass implements Insertable<SaveRow> {
  final String arcId;
  final String stateJson;
  final int updatedAt;
  const SaveRow({
    required this.arcId,
    required this.stateJson,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['arc_id'] = Variable<String>(arcId);
    map['state_json'] = Variable<String>(stateJson);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  SavesCompanion toCompanion(bool nullToAbsent) {
    return SavesCompanion(
      arcId: Value(arcId),
      stateJson: Value(stateJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory SaveRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SaveRow(
      arcId: serializer.fromJson<String>(json['arcId']),
      stateJson: serializer.fromJson<String>(json['stateJson']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'arcId': serializer.toJson<String>(arcId),
      'stateJson': serializer.toJson<String>(stateJson),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  SaveRow copyWith({String? arcId, String? stateJson, int? updatedAt}) =>
      SaveRow(
        arcId: arcId ?? this.arcId,
        stateJson: stateJson ?? this.stateJson,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  SaveRow copyWithCompanion(SavesCompanion data) {
    return SaveRow(
      arcId: data.arcId.present ? data.arcId.value : this.arcId,
      stateJson: data.stateJson.present ? data.stateJson.value : this.stateJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SaveRow(')
          ..write('arcId: $arcId, ')
          ..write('stateJson: $stateJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(arcId, stateJson, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SaveRow &&
          other.arcId == this.arcId &&
          other.stateJson == this.stateJson &&
          other.updatedAt == this.updatedAt);
}

class SavesCompanion extends UpdateCompanion<SaveRow> {
  final Value<String> arcId;
  final Value<String> stateJson;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const SavesCompanion({
    this.arcId = const Value.absent(),
    this.stateJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavesCompanion.insert({
    required String arcId,
    required String stateJson,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : arcId = Value(arcId),
       stateJson = Value(stateJson),
       updatedAt = Value(updatedAt);
  static Insertable<SaveRow> custom({
    Expression<String>? arcId,
    Expression<String>? stateJson,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (arcId != null) 'arc_id': arcId,
      if (stateJson != null) 'state_json': stateJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavesCompanion copyWith({
    Value<String>? arcId,
    Value<String>? stateJson,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return SavesCompanion(
      arcId: arcId ?? this.arcId,
      stateJson: stateJson ?? this.stateJson,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (arcId.present) {
      map['arc_id'] = Variable<String>(arcId.value);
    }
    if (stateJson.present) {
      map['state_json'] = Variable<String>(stateJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavesCompanion(')
          ..write('arcId: $arcId, ')
          ..write('stateJson: $stateJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $KeyMasteriesTable extends KeyMasteries
    with TableInfo<$KeyMasteriesTable, MasteryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KeyMasteriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _verseIdMeta = const VerificationMeta(
    'verseId',
  );
  @override
  late final GeneratedColumn<String> verseId = GeneratedColumn<String>(
    'verse_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueAtMeta = const VerificationMeta('dueAt');
  @override
  late final GeneratedColumn<int> dueAt = GeneratedColumn<int>(
    'due_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [verseId, json, dueAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'key_masteries';
  @override
  VerificationContext validateIntegrity(
    Insertable<MasteryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('verse_id')) {
      context.handle(
        _verseIdMeta,
        verseId.isAcceptableOrUnknown(data['verse_id']!, _verseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_verseIdMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('due_at')) {
      context.handle(
        _dueAtMeta,
        dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta),
      );
    } else if (isInserting) {
      context.missing(_dueAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {verseId};
  @override
  MasteryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MasteryRow(
      verseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}verse_id'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      dueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_at'],
      )!,
    );
  }

  @override
  $KeyMasteriesTable createAlias(String alias) {
    return $KeyMasteriesTable(attachedDatabase, alias);
  }
}

class MasteryRow extends DataClass implements Insertable<MasteryRow> {
  final String verseId;
  final String json;
  final int dueAt;
  const MasteryRow({
    required this.verseId,
    required this.json,
    required this.dueAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['verse_id'] = Variable<String>(verseId);
    map['json'] = Variable<String>(json);
    map['due_at'] = Variable<int>(dueAt);
    return map;
  }

  KeyMasteriesCompanion toCompanion(bool nullToAbsent) {
    return KeyMasteriesCompanion(
      verseId: Value(verseId),
      json: Value(json),
      dueAt: Value(dueAt),
    );
  }

  factory MasteryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MasteryRow(
      verseId: serializer.fromJson<String>(json['verseId']),
      json: serializer.fromJson<String>(json['json']),
      dueAt: serializer.fromJson<int>(json['dueAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'verseId': serializer.toJson<String>(verseId),
      'json': serializer.toJson<String>(json),
      'dueAt': serializer.toJson<int>(dueAt),
    };
  }

  MasteryRow copyWith({String? verseId, String? json, int? dueAt}) =>
      MasteryRow(
        verseId: verseId ?? this.verseId,
        json: json ?? this.json,
        dueAt: dueAt ?? this.dueAt,
      );
  MasteryRow copyWithCompanion(KeyMasteriesCompanion data) {
    return MasteryRow(
      verseId: data.verseId.present ? data.verseId.value : this.verseId,
      json: data.json.present ? data.json.value : this.json,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MasteryRow(')
          ..write('verseId: $verseId, ')
          ..write('json: $json, ')
          ..write('dueAt: $dueAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(verseId, json, dueAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MasteryRow &&
          other.verseId == this.verseId &&
          other.json == this.json &&
          other.dueAt == this.dueAt);
}

class KeyMasteriesCompanion extends UpdateCompanion<MasteryRow> {
  final Value<String> verseId;
  final Value<String> json;
  final Value<int> dueAt;
  final Value<int> rowid;
  const KeyMasteriesCompanion({
    this.verseId = const Value.absent(),
    this.json = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KeyMasteriesCompanion.insert({
    required String verseId,
    required String json,
    required int dueAt,
    this.rowid = const Value.absent(),
  }) : verseId = Value(verseId),
       json = Value(json),
       dueAt = Value(dueAt);
  static Insertable<MasteryRow> custom({
    Expression<String>? verseId,
    Expression<String>? json,
    Expression<int>? dueAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (verseId != null) 'verse_id': verseId,
      if (json != null) 'json': json,
      if (dueAt != null) 'due_at': dueAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KeyMasteriesCompanion copyWith({
    Value<String>? verseId,
    Value<String>? json,
    Value<int>? dueAt,
    Value<int>? rowid,
  }) {
    return KeyMasteriesCompanion(
      verseId: verseId ?? this.verseId,
      json: json ?? this.json,
      dueAt: dueAt ?? this.dueAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (verseId.present) {
      map['verse_id'] = Variable<String>(verseId.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (dueAt.present) {
      map['due_at'] = Variable<int>(dueAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KeyMasteriesCompanion(')
          ..write('verseId: $verseId, ')
          ..write('json: $json, ')
          ..write('dueAt: $dueAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $JournalRowsTable extends JournalRows
    with TableInfo<$JournalRowsTable, JournalRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JournalRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _arcIdMeta = const VerificationMeta('arcId');
  @override
  late final GeneratedColumn<String> arcId = GeneratedColumn<String>(
    'arc_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, type, createdAt, arcId, json];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'journal_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<JournalRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('arc_id')) {
      context.handle(
        _arcIdMeta,
        arcId.isAcceptableOrUnknown(data['arc_id']!, _arcIdMeta),
      );
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  JournalRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JournalRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      arcId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}arc_id'],
      ),
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
    );
  }

  @override
  $JournalRowsTable createAlias(String alias) {
    return $JournalRowsTable(attachedDatabase, alias);
  }
}

class JournalRow extends DataClass implements Insertable<JournalRow> {
  final String id;
  final String type;
  final int createdAt;
  final String? arcId;
  final String json;
  const JournalRow({
    required this.id,
    required this.type,
    required this.createdAt,
    this.arcId,
    required this.json,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || arcId != null) {
      map['arc_id'] = Variable<String>(arcId);
    }
    map['json'] = Variable<String>(json);
    return map;
  }

  JournalRowsCompanion toCompanion(bool nullToAbsent) {
    return JournalRowsCompanion(
      id: Value(id),
      type: Value(type),
      createdAt: Value(createdAt),
      arcId: arcId == null && nullToAbsent
          ? const Value.absent()
          : Value(arcId),
      json: Value(json),
    );
  }

  factory JournalRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JournalRow(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      arcId: serializer.fromJson<String?>(json['arcId']),
      json: serializer.fromJson<String>(json['json']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'createdAt': serializer.toJson<int>(createdAt),
      'arcId': serializer.toJson<String?>(arcId),
      'json': serializer.toJson<String>(json),
    };
  }

  JournalRow copyWith({
    String? id,
    String? type,
    int? createdAt,
    Value<String?> arcId = const Value.absent(),
    String? json,
  }) => JournalRow(
    id: id ?? this.id,
    type: type ?? this.type,
    createdAt: createdAt ?? this.createdAt,
    arcId: arcId.present ? arcId.value : this.arcId,
    json: json ?? this.json,
  );
  JournalRow copyWithCompanion(JournalRowsCompanion data) {
    return JournalRow(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      arcId: data.arcId.present ? data.arcId.value : this.arcId,
      json: data.json.present ? data.json.value : this.json,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JournalRow(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('createdAt: $createdAt, ')
          ..write('arcId: $arcId, ')
          ..write('json: $json')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, type, createdAt, arcId, json);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JournalRow &&
          other.id == this.id &&
          other.type == this.type &&
          other.createdAt == this.createdAt &&
          other.arcId == this.arcId &&
          other.json == this.json);
}

class JournalRowsCompanion extends UpdateCompanion<JournalRow> {
  final Value<String> id;
  final Value<String> type;
  final Value<int> createdAt;
  final Value<String?> arcId;
  final Value<String> json;
  final Value<int> rowid;
  const JournalRowsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.arcId = const Value.absent(),
    this.json = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JournalRowsCompanion.insert({
    required String id,
    required String type,
    required int createdAt,
    this.arcId = const Value.absent(),
    required String json,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       createdAt = Value(createdAt),
       json = Value(json);
  static Insertable<JournalRow> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<int>? createdAt,
    Expression<String>? arcId,
    Expression<String>? json,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (createdAt != null) 'created_at': createdAt,
      if (arcId != null) 'arc_id': arcId,
      if (json != null) 'json': json,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JournalRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<int>? createdAt,
    Value<String?>? arcId,
    Value<String>? json,
    Value<int>? rowid,
  }) {
    return JournalRowsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      arcId: arcId ?? this.arcId,
      json: json ?? this.json,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (arcId.present) {
      map['arc_id'] = Variable<String>(arcId.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JournalRowsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('createdAt: $createdAt, ')
          ..write('arcId: $arcId, ')
          ..write('json: $json, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProfileKvTable extends ProfileKv with TableInfo<$ProfileKvTable, KvRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfileKvTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profile_kv';
  @override
  VerificationContext validateIntegrity(
    Insertable<KvRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  KvRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KvRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $ProfileKvTable createAlias(String alias) {
    return $ProfileKvTable(attachedDatabase, alias);
  }
}

class KvRow extends DataClass implements Insertable<KvRow> {
  final String key;
  final String value;
  const KvRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  ProfileKvCompanion toCompanion(bool nullToAbsent) {
    return ProfileKvCompanion(key: Value(key), value: Value(value));
  }

  factory KvRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KvRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  KvRow copyWith({String? key, String? value}) =>
      KvRow(key: key ?? this.key, value: value ?? this.value);
  KvRow copyWithCompanion(ProfileKvCompanion data) {
    return KvRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KvRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KvRow && other.key == this.key && other.value == this.value);
}

class ProfileKvCompanion extends UpdateCompanion<KvRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const ProfileKvCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProfileKvCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<KvRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProfileKvCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return ProfileKvCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfileKvCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SavesTable saves = $SavesTable(this);
  late final $KeyMasteriesTable keyMasteries = $KeyMasteriesTable(this);
  late final $JournalRowsTable journalRows = $JournalRowsTable(this);
  late final $ProfileKvTable profileKv = $ProfileKvTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    saves,
    keyMasteries,
    journalRows,
    profileKv,
  ];
}

typedef $$SavesTableCreateCompanionBuilder = SavesCompanion Function({
  required String arcId,
  required String stateJson,
  required int updatedAt,
  Value<int> rowid,
});
typedef $$SavesTableUpdateCompanionBuilder = SavesCompanion Function({
  Value<String> arcId,
  Value<String> stateJson,
  Value<int> updatedAt,
  Value<int> rowid,
});

class $$SavesTableFilterComposer extends Composer<_$AppDatabase, $SavesTable> {
  $$SavesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get arcId => $composableBuilder(
    column: $table.arcId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stateJson => $composableBuilder(
    column: $table.stateJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SavesTableOrderingComposer
    extends Composer<_$AppDatabase, $SavesTable> {
  $$SavesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get arcId => $composableBuilder(
    column: $table.arcId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stateJson => $composableBuilder(
    column: $table.stateJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SavesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SavesTable> {
  $$SavesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get arcId =>
      $composableBuilder(column: $table.arcId, builder: (column) => column);

  GeneratedColumn<String> get stateJson =>
      $composableBuilder(column: $table.stateJson, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SavesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SavesTable,
          SaveRow,
          $$SavesTableFilterComposer,
          $$SavesTableOrderingComposer,
          $$SavesTableAnnotationComposer,
          $$SavesTableCreateCompanionBuilder,
          $$SavesTableUpdateCompanionBuilder,
          (SaveRow, BaseReferences<_$AppDatabase, $SavesTable, SaveRow>),
          SaveRow,
          PrefetchHooks Function()
        > {
  $$SavesTableTableManager(_$AppDatabase db, $SavesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> arcId = const Value.absent(),
                Value<String> stateJson = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavesCompanion(
                arcId: arcId,
                stateJson: stateJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String arcId,
                required String stateJson,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SavesCompanion.insert(
                arcId: arcId,
                stateJson: stateJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SavesTable, SaveRow>(table),
                  BaseReferences<_$AppDatabase, $SavesTable, SaveRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SavesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SavesTable,
      SaveRow,
      $$SavesTableFilterComposer,
      $$SavesTableOrderingComposer,
      $$SavesTableAnnotationComposer,
      $$SavesTableCreateCompanionBuilder,
      $$SavesTableUpdateCompanionBuilder,
      (SaveRow, BaseReferences<_$AppDatabase, $SavesTable, SaveRow>),
      SaveRow,
      PrefetchHooks Function()
    >;
typedef $$KeyMasteriesTableCreateCompanionBuilder =
    KeyMasteriesCompanion Function({
      required String verseId,
      required String json,
      required int dueAt,
      Value<int> rowid,
    });
typedef $$KeyMasteriesTableUpdateCompanionBuilder =
    KeyMasteriesCompanion Function({
      Value<String> verseId,
      Value<String> json,
      Value<int> dueAt,
      Value<int> rowid,
    });

class $$KeyMasteriesTableFilterComposer
    extends Composer<_$AppDatabase, $KeyMasteriesTable> {
  $$KeyMasteriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get verseId => $composableBuilder(
    column: $table.verseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KeyMasteriesTableOrderingComposer
    extends Composer<_$AppDatabase, $KeyMasteriesTable> {
  $$KeyMasteriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get verseId => $composableBuilder(
    column: $table.verseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KeyMasteriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $KeyMasteriesTable> {
  $$KeyMasteriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get verseId =>
      $composableBuilder(column: $table.verseId, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<int> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => column);
}

class $$KeyMasteriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KeyMasteriesTable,
          MasteryRow,
          $$KeyMasteriesTableFilterComposer,
          $$KeyMasteriesTableOrderingComposer,
          $$KeyMasteriesTableAnnotationComposer,
          $$KeyMasteriesTableCreateCompanionBuilder,
          $$KeyMasteriesTableUpdateCompanionBuilder,
          (
            MasteryRow,
            BaseReferences<_$AppDatabase, $KeyMasteriesTable, MasteryRow>,
          ),
          MasteryRow,
          PrefetchHooks Function()
        > {
  $$KeyMasteriesTableTableManager(_$AppDatabase db, $KeyMasteriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KeyMasteriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KeyMasteriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KeyMasteriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> verseId = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<int> dueAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KeyMasteriesCompanion(
                verseId: verseId,
                json: json,
                dueAt: dueAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String verseId,
                required String json,
                required int dueAt,
                Value<int> rowid = const Value.absent(),
              }) => KeyMasteriesCompanion.insert(
                verseId: verseId,
                json: json,
                dueAt: dueAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$KeyMasteriesTable, MasteryRow>(table),
                  BaseReferences<_$AppDatabase, $KeyMasteriesTable, MasteryRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KeyMasteriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KeyMasteriesTable,
      MasteryRow,
      $$KeyMasteriesTableFilterComposer,
      $$KeyMasteriesTableOrderingComposer,
      $$KeyMasteriesTableAnnotationComposer,
      $$KeyMasteriesTableCreateCompanionBuilder,
      $$KeyMasteriesTableUpdateCompanionBuilder,
      (
        MasteryRow,
        BaseReferences<_$AppDatabase, $KeyMasteriesTable, MasteryRow>,
      ),
      MasteryRow,
      PrefetchHooks Function()
    >;
typedef $$JournalRowsTableCreateCompanionBuilder =
    JournalRowsCompanion Function({
      required String id,
      required String type,
      required int createdAt,
      Value<String?> arcId,
      required String json,
      Value<int> rowid,
    });
typedef $$JournalRowsTableUpdateCompanionBuilder =
    JournalRowsCompanion Function({
      Value<String> id,
      Value<String> type,
      Value<int> createdAt,
      Value<String?> arcId,
      Value<String> json,
      Value<int> rowid,
    });

class $$JournalRowsTableFilterComposer
    extends Composer<_$AppDatabase, $JournalRowsTable> {
  $$JournalRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get arcId => $composableBuilder(
    column: $table.arcId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );
}

class $$JournalRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $JournalRowsTable> {
  $$JournalRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get arcId => $composableBuilder(
    column: $table.arcId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$JournalRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $JournalRowsTable> {
  $$JournalRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get arcId =>
      $composableBuilder(column: $table.arcId, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);
}

class $$JournalRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $JournalRowsTable,
          JournalRow,
          $$JournalRowsTableFilterComposer,
          $$JournalRowsTableOrderingComposer,
          $$JournalRowsTableAnnotationComposer,
          $$JournalRowsTableCreateCompanionBuilder,
          $$JournalRowsTableUpdateCompanionBuilder,
          (
            JournalRow,
            BaseReferences<_$AppDatabase, $JournalRowsTable, JournalRow>,
          ),
          JournalRow,
          PrefetchHooks Function()
        > {
  $$JournalRowsTableTableManager(_$AppDatabase db, $JournalRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JournalRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JournalRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JournalRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<String?> arcId = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JournalRowsCompanion(
                id: id,
                type: type,
                createdAt: createdAt,
                arcId: arcId,
                json: json,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String type,
                required int createdAt,
                Value<String?> arcId = const Value.absent(),
                required String json,
                Value<int> rowid = const Value.absent(),
              }) => JournalRowsCompanion.insert(
                id: id,
                type: type,
                createdAt: createdAt,
                arcId: arcId,
                json: json,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$JournalRowsTable, JournalRow>(table),
                  BaseReferences<_$AppDatabase, $JournalRowsTable, JournalRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$JournalRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $JournalRowsTable,
      JournalRow,
      $$JournalRowsTableFilterComposer,
      $$JournalRowsTableOrderingComposer,
      $$JournalRowsTableAnnotationComposer,
      $$JournalRowsTableCreateCompanionBuilder,
      $$JournalRowsTableUpdateCompanionBuilder,
      (
        JournalRow,
        BaseReferences<_$AppDatabase, $JournalRowsTable, JournalRow>,
      ),
      JournalRow,
      PrefetchHooks Function()
    >;
typedef $$ProfileKvTableCreateCompanionBuilder = ProfileKvCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$ProfileKvTableUpdateCompanionBuilder = ProfileKvCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$ProfileKvTableFilterComposer
    extends Composer<_$AppDatabase, $ProfileKvTable> {
  $$ProfileKvTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProfileKvTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfileKvTable> {
  $$ProfileKvTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfileKvTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfileKvTable> {
  $$ProfileKvTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$ProfileKvTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfileKvTable,
          KvRow,
          $$ProfileKvTableFilterComposer,
          $$ProfileKvTableOrderingComposer,
          $$ProfileKvTableAnnotationComposer,
          $$ProfileKvTableCreateCompanionBuilder,
          $$ProfileKvTableUpdateCompanionBuilder,
          (KvRow, BaseReferences<_$AppDatabase, $ProfileKvTable, KvRow>),
          KvRow,
          PrefetchHooks Function()
        > {
  $$ProfileKvTableTableManager(_$AppDatabase db, $ProfileKvTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfileKvTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfileKvTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfileKvTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => ProfileKvCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => ProfileKvCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProfileKvTable, KvRow>(table),
                  BaseReferences<_$AppDatabase, $ProfileKvTable, KvRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfileKvTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfileKvTable,
      KvRow,
      $$ProfileKvTableFilterComposer,
      $$ProfileKvTableOrderingComposer,
      $$ProfileKvTableAnnotationComposer,
      $$ProfileKvTableCreateCompanionBuilder,
      $$ProfileKvTableUpdateCompanionBuilder,
      (KvRow, BaseReferences<_$AppDatabase, $ProfileKvTable, KvRow>),
      KvRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SavesTableTableManager get saves =>
      $$SavesTableTableManager(_db, _db.saves);
  $$KeyMasteriesTableTableManager get keyMasteries =>
      $$KeyMasteriesTableTableManager(_db, _db.keyMasteries);
  $$JournalRowsTableTableManager get journalRows =>
      $$JournalRowsTableTableManager(_db, _db.journalRows);
  $$ProfileKvTableTableManager get profileKv =>
      $$ProfileKvTableTableManager(_db, _db.profileKv);
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ScorecardsTable extends Scorecards
    with TableInfo<$ScorecardsTable, Scorecard> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScorecardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _formatVersionMeta = const VerificationMeta(
    'formatVersion',
  );
  @override
  late final GeneratedColumn<int> formatVersion = GeneratedColumn<int>(
    'format_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _faceIdMeta = const VerificationMeta('faceId');
  @override
  late final GeneratedColumn<String> faceId = GeneratedColumn<String>(
    'face_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conversionMeta = const VerificationMeta(
    'conversion',
  );
  @override
  late final GeneratedColumn<String> conversion = GeneratedColumn<String>(
    'conversion',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shootLenMeta = const VerificationMeta(
    'shootLen',
  );
  @override
  late final GeneratedColumn<int> shootLen = GeneratedColumn<int>(
    'shoot_len',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetNumberMeta = const VerificationMeta(
    'targetNumber',
  );
  @override
  late final GeneratedColumn<String> targetNumber = GeneratedColumn<String>(
    'target_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _savedAtMeta = const VerificationMeta(
    'savedAt',
  );
  @override
  late final GeneratedColumn<String> savedAt = GeneratedColumn<String>(
    'saved_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shotsJsonMeta = const VerificationMeta(
    'shotsJson',
  );
  @override
  late final GeneratedColumn<String> shotsJson = GeneratedColumn<String>(
    'shots_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    formatVersion,
    faceId,
    conversion,
    shootLen,
    targetNumber,
    savedAt,
    shotsJson,
    ownerId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scorecards';
  @override
  VerificationContext validateIntegrity(
    Insertable<Scorecard> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('format_version')) {
      context.handle(
        _formatVersionMeta,
        formatVersion.isAcceptableOrUnknown(
          data['format_version']!,
          _formatVersionMeta,
        ),
      );
    }
    if (data.containsKey('face_id')) {
      context.handle(
        _faceIdMeta,
        faceId.isAcceptableOrUnknown(data['face_id']!, _faceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_faceIdMeta);
    }
    if (data.containsKey('conversion')) {
      context.handle(
        _conversionMeta,
        conversion.isAcceptableOrUnknown(data['conversion']!, _conversionMeta),
      );
    } else if (isInserting) {
      context.missing(_conversionMeta);
    }
    if (data.containsKey('shoot_len')) {
      context.handle(
        _shootLenMeta,
        shootLen.isAcceptableOrUnknown(data['shoot_len']!, _shootLenMeta),
      );
    } else if (isInserting) {
      context.missing(_shootLenMeta);
    }
    if (data.containsKey('target_number')) {
      context.handle(
        _targetNumberMeta,
        targetNumber.isAcceptableOrUnknown(
          data['target_number']!,
          _targetNumberMeta,
        ),
      );
    }
    if (data.containsKey('saved_at')) {
      context.handle(
        _savedAtMeta,
        savedAt.isAcceptableOrUnknown(data['saved_at']!, _savedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_savedAtMeta);
    }
    if (data.containsKey('shots_json')) {
      context.handle(
        _shotsJsonMeta,
        shotsJson.isAcceptableOrUnknown(data['shots_json']!, _shotsJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_shotsJsonMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Scorecard map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Scorecard(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      formatVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}format_version'],
      )!,
      faceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}face_id'],
      )!,
      conversion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conversion'],
      )!,
      shootLen: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}shoot_len'],
      )!,
      targetNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_number'],
      )!,
      savedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}saved_at'],
      )!,
      shotsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shots_json'],
      )!,
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      ),
    );
  }

  @override
  $ScorecardsTable createAlias(String alias) {
    return $ScorecardsTable(attachedDatabase, alias);
  }
}

class Scorecard extends DataClass implements Insertable<Scorecard> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int formatVersion;
  final String faceId;
  final String conversion;
  final int shootLen;
  final String targetNumber;
  final String savedAt;
  final String shotsJson;
  final String? ownerId;
  const Scorecard({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.formatVersion,
    required this.faceId,
    required this.conversion,
    required this.shootLen,
    required this.targetNumber,
    required this.savedAt,
    required this.shotsJson,
    this.ownerId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['format_version'] = Variable<int>(formatVersion);
    map['face_id'] = Variable<String>(faceId);
    map['conversion'] = Variable<String>(conversion);
    map['shoot_len'] = Variable<int>(shootLen);
    map['target_number'] = Variable<String>(targetNumber);
    map['saved_at'] = Variable<String>(savedAt);
    map['shots_json'] = Variable<String>(shotsJson);
    if (!nullToAbsent || ownerId != null) {
      map['owner_id'] = Variable<String>(ownerId);
    }
    return map;
  }

  ScorecardsCompanion toCompanion(bool nullToAbsent) {
    return ScorecardsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      formatVersion: Value(formatVersion),
      faceId: Value(faceId),
      conversion: Value(conversion),
      shootLen: Value(shootLen),
      targetNumber: Value(targetNumber),
      savedAt: Value(savedAt),
      shotsJson: Value(shotsJson),
      ownerId: ownerId == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerId),
    );
  }

  factory Scorecard.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Scorecard(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      formatVersion: serializer.fromJson<int>(json['formatVersion']),
      faceId: serializer.fromJson<String>(json['faceId']),
      conversion: serializer.fromJson<String>(json['conversion']),
      shootLen: serializer.fromJson<int>(json['shootLen']),
      targetNumber: serializer.fromJson<String>(json['targetNumber']),
      savedAt: serializer.fromJson<String>(json['savedAt']),
      shotsJson: serializer.fromJson<String>(json['shotsJson']),
      ownerId: serializer.fromJson<String?>(json['ownerId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'formatVersion': serializer.toJson<int>(formatVersion),
      'faceId': serializer.toJson<String>(faceId),
      'conversion': serializer.toJson<String>(conversion),
      'shootLen': serializer.toJson<int>(shootLen),
      'targetNumber': serializer.toJson<String>(targetNumber),
      'savedAt': serializer.toJson<String>(savedAt),
      'shotsJson': serializer.toJson<String>(shotsJson),
      'ownerId': serializer.toJson<String?>(ownerId),
    };
  }

  Scorecard copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? formatVersion,
    String? faceId,
    String? conversion,
    int? shootLen,
    String? targetNumber,
    String? savedAt,
    String? shotsJson,
    Value<String?> ownerId = const Value.absent(),
  }) => Scorecard(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    formatVersion: formatVersion ?? this.formatVersion,
    faceId: faceId ?? this.faceId,
    conversion: conversion ?? this.conversion,
    shootLen: shootLen ?? this.shootLen,
    targetNumber: targetNumber ?? this.targetNumber,
    savedAt: savedAt ?? this.savedAt,
    shotsJson: shotsJson ?? this.shotsJson,
    ownerId: ownerId.present ? ownerId.value : this.ownerId,
  );
  Scorecard copyWithCompanion(ScorecardsCompanion data) {
    return Scorecard(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      formatVersion: data.formatVersion.present
          ? data.formatVersion.value
          : this.formatVersion,
      faceId: data.faceId.present ? data.faceId.value : this.faceId,
      conversion: data.conversion.present
          ? data.conversion.value
          : this.conversion,
      shootLen: data.shootLen.present ? data.shootLen.value : this.shootLen,
      targetNumber: data.targetNumber.present
          ? data.targetNumber.value
          : this.targetNumber,
      savedAt: data.savedAt.present ? data.savedAt.value : this.savedAt,
      shotsJson: data.shotsJson.present ? data.shotsJson.value : this.shotsJson,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Scorecard(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('formatVersion: $formatVersion, ')
          ..write('faceId: $faceId, ')
          ..write('conversion: $conversion, ')
          ..write('shootLen: $shootLen, ')
          ..write('targetNumber: $targetNumber, ')
          ..write('savedAt: $savedAt, ')
          ..write('shotsJson: $shotsJson, ')
          ..write('ownerId: $ownerId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    formatVersion,
    faceId,
    conversion,
    shootLen,
    targetNumber,
    savedAt,
    shotsJson,
    ownerId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Scorecard &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.formatVersion == this.formatVersion &&
          other.faceId == this.faceId &&
          other.conversion == this.conversion &&
          other.shootLen == this.shootLen &&
          other.targetNumber == this.targetNumber &&
          other.savedAt == this.savedAt &&
          other.shotsJson == this.shotsJson &&
          other.ownerId == this.ownerId);
}

class ScorecardsCompanion extends UpdateCompanion<Scorecard> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> formatVersion;
  final Value<String> faceId;
  final Value<String> conversion;
  final Value<int> shootLen;
  final Value<String> targetNumber;
  final Value<String> savedAt;
  final Value<String> shotsJson;
  final Value<String?> ownerId;
  final Value<int> rowid;
  const ScorecardsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.formatVersion = const Value.absent(),
    this.faceId = const Value.absent(),
    this.conversion = const Value.absent(),
    this.shootLen = const Value.absent(),
    this.targetNumber = const Value.absent(),
    this.savedAt = const Value.absent(),
    this.shotsJson = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScorecardsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.formatVersion = const Value.absent(),
    required String faceId,
    required String conversion,
    required int shootLen,
    this.targetNumber = const Value.absent(),
    required String savedAt,
    required String shotsJson,
    this.ownerId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       faceId = Value(faceId),
       conversion = Value(conversion),
       shootLen = Value(shootLen),
       savedAt = Value(savedAt),
       shotsJson = Value(shotsJson);
  static Insertable<Scorecard> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? formatVersion,
    Expression<String>? faceId,
    Expression<String>? conversion,
    Expression<int>? shootLen,
    Expression<String>? targetNumber,
    Expression<String>? savedAt,
    Expression<String>? shotsJson,
    Expression<String>? ownerId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (formatVersion != null) 'format_version': formatVersion,
      if (faceId != null) 'face_id': faceId,
      if (conversion != null) 'conversion': conversion,
      if (shootLen != null) 'shoot_len': shootLen,
      if (targetNumber != null) 'target_number': targetNumber,
      if (savedAt != null) 'saved_at': savedAt,
      if (shotsJson != null) 'shots_json': shotsJson,
      if (ownerId != null) 'owner_id': ownerId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScorecardsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? formatVersion,
    Value<String>? faceId,
    Value<String>? conversion,
    Value<int>? shootLen,
    Value<String>? targetNumber,
    Value<String>? savedAt,
    Value<String>? shotsJson,
    Value<String?>? ownerId,
    Value<int>? rowid,
  }) {
    return ScorecardsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      formatVersion: formatVersion ?? this.formatVersion,
      faceId: faceId ?? this.faceId,
      conversion: conversion ?? this.conversion,
      shootLen: shootLen ?? this.shootLen,
      targetNumber: targetNumber ?? this.targetNumber,
      savedAt: savedAt ?? this.savedAt,
      shotsJson: shotsJson ?? this.shotsJson,
      ownerId: ownerId ?? this.ownerId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (formatVersion.present) {
      map['format_version'] = Variable<int>(formatVersion.value);
    }
    if (faceId.present) {
      map['face_id'] = Variable<String>(faceId.value);
    }
    if (conversion.present) {
      map['conversion'] = Variable<String>(conversion.value);
    }
    if (shootLen.present) {
      map['shoot_len'] = Variable<int>(shootLen.value);
    }
    if (targetNumber.present) {
      map['target_number'] = Variable<String>(targetNumber.value);
    }
    if (savedAt.present) {
      map['saved_at'] = Variable<String>(savedAt.value);
    }
    if (shotsJson.present) {
      map['shots_json'] = Variable<String>(shotsJson.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScorecardsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('formatVersion: $formatVersion, ')
          ..write('faceId: $faceId, ')
          ..write('conversion: $conversion, ')
          ..write('shootLen: $shootLen, ')
          ..write('targetNumber: $targetNumber, ')
          ..write('savedAt: $savedAt, ')
          ..write('shotsJson: $shotsJson, ')
          ..write('ownerId: $ownerId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SightPresetsTable extends SightPresets
    with TableInfo<$SightPresetsTable, SightPreset> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SightPresetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _formatVersionMeta = const VerificationMeta(
    'formatVersion',
  );
  @override
  late final GeneratedColumn<int> formatVersion = GeneratedColumn<int>(
    'format_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _faceIdMeta = const VerificationMeta('faceId');
  @override
  late final GeneratedColumn<String> faceId = GeneratedColumn<String>(
    'face_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _windMoaMeta = const VerificationMeta(
    'windMoa',
  );
  @override
  late final GeneratedColumn<double> windMoa = GeneratedColumn<double>(
    'wind_moa',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _elevMoaMeta = const VerificationMeta(
    'elevMoa',
  );
  @override
  late final GeneratedColumn<double> elevMoa = GeneratedColumn<double>(
    'elev_moa',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _apertureMeta = const VerificationMeta(
    'aperture',
  );
  @override
  late final GeneratedColumn<String> aperture = GeneratedColumn<String>(
    'aperture',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    formatVersion,
    faceId,
    windMoa,
    elevMoa,
    label,
    aperture,
    ownerId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sight_presets';
  @override
  VerificationContext validateIntegrity(
    Insertable<SightPreset> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('format_version')) {
      context.handle(
        _formatVersionMeta,
        formatVersion.isAcceptableOrUnknown(
          data['format_version']!,
          _formatVersionMeta,
        ),
      );
    }
    if (data.containsKey('face_id')) {
      context.handle(
        _faceIdMeta,
        faceId.isAcceptableOrUnknown(data['face_id']!, _faceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_faceIdMeta);
    }
    if (data.containsKey('wind_moa')) {
      context.handle(
        _windMoaMeta,
        windMoa.isAcceptableOrUnknown(data['wind_moa']!, _windMoaMeta),
      );
    } else if (isInserting) {
      context.missing(_windMoaMeta);
    }
    if (data.containsKey('elev_moa')) {
      context.handle(
        _elevMoaMeta,
        elevMoa.isAcceptableOrUnknown(data['elev_moa']!, _elevMoaMeta),
      );
    } else if (isInserting) {
      context.missing(_elevMoaMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('aperture')) {
      context.handle(
        _apertureMeta,
        aperture.isAcceptableOrUnknown(data['aperture']!, _apertureMeta),
      );
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SightPreset map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SightPreset(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      formatVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}format_version'],
      )!,
      faceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}face_id'],
      )!,
      windMoa: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}wind_moa'],
      )!,
      elevMoa: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}elev_moa'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      aperture: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}aperture'],
      )!,
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      ),
    );
  }

  @override
  $SightPresetsTable createAlias(String alias) {
    return $SightPresetsTable(attachedDatabase, alias);
  }
}

class SightPreset extends DataClass implements Insertable<SightPreset> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int formatVersion;
  final String faceId;
  final double windMoa;
  final double elevMoa;
  final String label;
  final String aperture;
  final String? ownerId;
  const SightPreset({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.formatVersion,
    required this.faceId,
    required this.windMoa,
    required this.elevMoa,
    required this.label,
    required this.aperture,
    this.ownerId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['format_version'] = Variable<int>(formatVersion);
    map['face_id'] = Variable<String>(faceId);
    map['wind_moa'] = Variable<double>(windMoa);
    map['elev_moa'] = Variable<double>(elevMoa);
    map['label'] = Variable<String>(label);
    map['aperture'] = Variable<String>(aperture);
    if (!nullToAbsent || ownerId != null) {
      map['owner_id'] = Variable<String>(ownerId);
    }
    return map;
  }

  SightPresetsCompanion toCompanion(bool nullToAbsent) {
    return SightPresetsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      formatVersion: Value(formatVersion),
      faceId: Value(faceId),
      windMoa: Value(windMoa),
      elevMoa: Value(elevMoa),
      label: Value(label),
      aperture: Value(aperture),
      ownerId: ownerId == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerId),
    );
  }

  factory SightPreset.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SightPreset(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      formatVersion: serializer.fromJson<int>(json['formatVersion']),
      faceId: serializer.fromJson<String>(json['faceId']),
      windMoa: serializer.fromJson<double>(json['windMoa']),
      elevMoa: serializer.fromJson<double>(json['elevMoa']),
      label: serializer.fromJson<String>(json['label']),
      aperture: serializer.fromJson<String>(json['aperture']),
      ownerId: serializer.fromJson<String?>(json['ownerId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'formatVersion': serializer.toJson<int>(formatVersion),
      'faceId': serializer.toJson<String>(faceId),
      'windMoa': serializer.toJson<double>(windMoa),
      'elevMoa': serializer.toJson<double>(elevMoa),
      'label': serializer.toJson<String>(label),
      'aperture': serializer.toJson<String>(aperture),
      'ownerId': serializer.toJson<String?>(ownerId),
    };
  }

  SightPreset copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? formatVersion,
    String? faceId,
    double? windMoa,
    double? elevMoa,
    String? label,
    String? aperture,
    Value<String?> ownerId = const Value.absent(),
  }) => SightPreset(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    formatVersion: formatVersion ?? this.formatVersion,
    faceId: faceId ?? this.faceId,
    windMoa: windMoa ?? this.windMoa,
    elevMoa: elevMoa ?? this.elevMoa,
    label: label ?? this.label,
    aperture: aperture ?? this.aperture,
    ownerId: ownerId.present ? ownerId.value : this.ownerId,
  );
  SightPreset copyWithCompanion(SightPresetsCompanion data) {
    return SightPreset(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      formatVersion: data.formatVersion.present
          ? data.formatVersion.value
          : this.formatVersion,
      faceId: data.faceId.present ? data.faceId.value : this.faceId,
      windMoa: data.windMoa.present ? data.windMoa.value : this.windMoa,
      elevMoa: data.elevMoa.present ? data.elevMoa.value : this.elevMoa,
      label: data.label.present ? data.label.value : this.label,
      aperture: data.aperture.present ? data.aperture.value : this.aperture,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SightPreset(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('formatVersion: $formatVersion, ')
          ..write('faceId: $faceId, ')
          ..write('windMoa: $windMoa, ')
          ..write('elevMoa: $elevMoa, ')
          ..write('label: $label, ')
          ..write('aperture: $aperture, ')
          ..write('ownerId: $ownerId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    formatVersion,
    faceId,
    windMoa,
    elevMoa,
    label,
    aperture,
    ownerId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SightPreset &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.formatVersion == this.formatVersion &&
          other.faceId == this.faceId &&
          other.windMoa == this.windMoa &&
          other.elevMoa == this.elevMoa &&
          other.label == this.label &&
          other.aperture == this.aperture &&
          other.ownerId == this.ownerId);
}

class SightPresetsCompanion extends UpdateCompanion<SightPreset> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> formatVersion;
  final Value<String> faceId;
  final Value<double> windMoa;
  final Value<double> elevMoa;
  final Value<String> label;
  final Value<String> aperture;
  final Value<String?> ownerId;
  final Value<int> rowid;
  const SightPresetsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.formatVersion = const Value.absent(),
    this.faceId = const Value.absent(),
    this.windMoa = const Value.absent(),
    this.elevMoa = const Value.absent(),
    this.label = const Value.absent(),
    this.aperture = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SightPresetsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.formatVersion = const Value.absent(),
    required String faceId,
    required double windMoa,
    required double elevMoa,
    this.label = const Value.absent(),
    this.aperture = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       faceId = Value(faceId),
       windMoa = Value(windMoa),
       elevMoa = Value(elevMoa);
  static Insertable<SightPreset> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? formatVersion,
    Expression<String>? faceId,
    Expression<double>? windMoa,
    Expression<double>? elevMoa,
    Expression<String>? label,
    Expression<String>? aperture,
    Expression<String>? ownerId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (formatVersion != null) 'format_version': formatVersion,
      if (faceId != null) 'face_id': faceId,
      if (windMoa != null) 'wind_moa': windMoa,
      if (elevMoa != null) 'elev_moa': elevMoa,
      if (label != null) 'label': label,
      if (aperture != null) 'aperture': aperture,
      if (ownerId != null) 'owner_id': ownerId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SightPresetsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? formatVersion,
    Value<String>? faceId,
    Value<double>? windMoa,
    Value<double>? elevMoa,
    Value<String>? label,
    Value<String>? aperture,
    Value<String?>? ownerId,
    Value<int>? rowid,
  }) {
    return SightPresetsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      formatVersion: formatVersion ?? this.formatVersion,
      faceId: faceId ?? this.faceId,
      windMoa: windMoa ?? this.windMoa,
      elevMoa: elevMoa ?? this.elevMoa,
      label: label ?? this.label,
      aperture: aperture ?? this.aperture,
      ownerId: ownerId ?? this.ownerId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (formatVersion.present) {
      map['format_version'] = Variable<int>(formatVersion.value);
    }
    if (faceId.present) {
      map['face_id'] = Variable<String>(faceId.value);
    }
    if (windMoa.present) {
      map['wind_moa'] = Variable<double>(windMoa.value);
    }
    if (elevMoa.present) {
      map['elev_moa'] = Variable<double>(elevMoa.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (aperture.present) {
      map['aperture'] = Variable<String>(aperture.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SightPresetsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('formatVersion: $formatVersion, ')
          ..write('faceId: $faceId, ')
          ..write('windMoa: $windMoa, ')
          ..write('elevMoa: $elevMoa, ')
          ..write('label: $label, ')
          ..write('aperture: $aperture, ')
          ..write('ownerId: $ownerId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ScorecardsTable scorecards = $ScorecardsTable(this);
  late final $SightPresetsTable sightPresets = $SightPresetsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    scorecards,
    sightPresets,
  ];
}

typedef $$ScorecardsTableCreateCompanionBuilder =
    ScorecardsCompanion Function({
      required String id,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> formatVersion,
      required String faceId,
      required String conversion,
      required int shootLen,
      Value<String> targetNumber,
      required String savedAt,
      required String shotsJson,
      Value<String?> ownerId,
      Value<int> rowid,
    });
typedef $$ScorecardsTableUpdateCompanionBuilder =
    ScorecardsCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> formatVersion,
      Value<String> faceId,
      Value<String> conversion,
      Value<int> shootLen,
      Value<String> targetNumber,
      Value<String> savedAt,
      Value<String> shotsJson,
      Value<String?> ownerId,
      Value<int> rowid,
    });

class $$ScorecardsTableFilterComposer
    extends Composer<_$AppDatabase, $ScorecardsTable> {
  $$ScorecardsTableFilterComposer({
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get formatVersion => $composableBuilder(
    column: $table.formatVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get faceId => $composableBuilder(
    column: $table.faceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conversion => $composableBuilder(
    column: $table.conversion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get shootLen => $composableBuilder(
    column: $table.shootLen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetNumber => $composableBuilder(
    column: $table.targetNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shotsJson => $composableBuilder(
    column: $table.shotsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ScorecardsTableOrderingComposer
    extends Composer<_$AppDatabase, $ScorecardsTable> {
  $$ScorecardsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get formatVersion => $composableBuilder(
    column: $table.formatVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get faceId => $composableBuilder(
    column: $table.faceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conversion => $composableBuilder(
    column: $table.conversion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get shootLen => $composableBuilder(
    column: $table.shootLen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetNumber => $composableBuilder(
    column: $table.targetNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shotsJson => $composableBuilder(
    column: $table.shotsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ScorecardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScorecardsTable> {
  $$ScorecardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get formatVersion => $composableBuilder(
    column: $table.formatVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get faceId =>
      $composableBuilder(column: $table.faceId, builder: (column) => column);

  GeneratedColumn<String> get conversion => $composableBuilder(
    column: $table.conversion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get shootLen =>
      $composableBuilder(column: $table.shootLen, builder: (column) => column);

  GeneratedColumn<String> get targetNumber => $composableBuilder(
    column: $table.targetNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => column);

  GeneratedColumn<String> get shotsJson =>
      $composableBuilder(column: $table.shotsJson, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);
}

class $$ScorecardsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScorecardsTable,
          Scorecard,
          $$ScorecardsTableFilterComposer,
          $$ScorecardsTableOrderingComposer,
          $$ScorecardsTableAnnotationComposer,
          $$ScorecardsTableCreateCompanionBuilder,
          $$ScorecardsTableUpdateCompanionBuilder,
          (
            Scorecard,
            BaseReferences<_$AppDatabase, $ScorecardsTable, Scorecard>,
          ),
          Scorecard,
          PrefetchHooks Function()
        > {
  $$ScorecardsTableTableManager(_$AppDatabase db, $ScorecardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScorecardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScorecardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScorecardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> formatVersion = const Value.absent(),
                Value<String> faceId = const Value.absent(),
                Value<String> conversion = const Value.absent(),
                Value<int> shootLen = const Value.absent(),
                Value<String> targetNumber = const Value.absent(),
                Value<String> savedAt = const Value.absent(),
                Value<String> shotsJson = const Value.absent(),
                Value<String?> ownerId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScorecardsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                formatVersion: formatVersion,
                faceId: faceId,
                conversion: conversion,
                shootLen: shootLen,
                targetNumber: targetNumber,
                savedAt: savedAt,
                shotsJson: shotsJson,
                ownerId: ownerId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> formatVersion = const Value.absent(),
                required String faceId,
                required String conversion,
                required int shootLen,
                Value<String> targetNumber = const Value.absent(),
                required String savedAt,
                required String shotsJson,
                Value<String?> ownerId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScorecardsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                formatVersion: formatVersion,
                faceId: faceId,
                conversion: conversion,
                shootLen: shootLen,
                targetNumber: targetNumber,
                savedAt: savedAt,
                shotsJson: shotsJson,
                ownerId: ownerId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ScorecardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScorecardsTable,
      Scorecard,
      $$ScorecardsTableFilterComposer,
      $$ScorecardsTableOrderingComposer,
      $$ScorecardsTableAnnotationComposer,
      $$ScorecardsTableCreateCompanionBuilder,
      $$ScorecardsTableUpdateCompanionBuilder,
      (Scorecard, BaseReferences<_$AppDatabase, $ScorecardsTable, Scorecard>),
      Scorecard,
      PrefetchHooks Function()
    >;
typedef $$SightPresetsTableCreateCompanionBuilder =
    SightPresetsCompanion Function({
      required String id,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> formatVersion,
      required String faceId,
      required double windMoa,
      required double elevMoa,
      Value<String> label,
      Value<String> aperture,
      Value<String?> ownerId,
      Value<int> rowid,
    });
typedef $$SightPresetsTableUpdateCompanionBuilder =
    SightPresetsCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> formatVersion,
      Value<String> faceId,
      Value<double> windMoa,
      Value<double> elevMoa,
      Value<String> label,
      Value<String> aperture,
      Value<String?> ownerId,
      Value<int> rowid,
    });

class $$SightPresetsTableFilterComposer
    extends Composer<_$AppDatabase, $SightPresetsTable> {
  $$SightPresetsTableFilterComposer({
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get formatVersion => $composableBuilder(
    column: $table.formatVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get faceId => $composableBuilder(
    column: $table.faceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get windMoa => $composableBuilder(
    column: $table.windMoa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get elevMoa => $composableBuilder(
    column: $table.elevMoa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aperture => $composableBuilder(
    column: $table.aperture,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SightPresetsTableOrderingComposer
    extends Composer<_$AppDatabase, $SightPresetsTable> {
  $$SightPresetsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get formatVersion => $composableBuilder(
    column: $table.formatVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get faceId => $composableBuilder(
    column: $table.faceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get windMoa => $composableBuilder(
    column: $table.windMoa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get elevMoa => $composableBuilder(
    column: $table.elevMoa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aperture => $composableBuilder(
    column: $table.aperture,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SightPresetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SightPresetsTable> {
  $$SightPresetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get formatVersion => $composableBuilder(
    column: $table.formatVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get faceId =>
      $composableBuilder(column: $table.faceId, builder: (column) => column);

  GeneratedColumn<double> get windMoa =>
      $composableBuilder(column: $table.windMoa, builder: (column) => column);

  GeneratedColumn<double> get elevMoa =>
      $composableBuilder(column: $table.elevMoa, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get aperture =>
      $composableBuilder(column: $table.aperture, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);
}

class $$SightPresetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SightPresetsTable,
          SightPreset,
          $$SightPresetsTableFilterComposer,
          $$SightPresetsTableOrderingComposer,
          $$SightPresetsTableAnnotationComposer,
          $$SightPresetsTableCreateCompanionBuilder,
          $$SightPresetsTableUpdateCompanionBuilder,
          (
            SightPreset,
            BaseReferences<_$AppDatabase, $SightPresetsTable, SightPreset>,
          ),
          SightPreset,
          PrefetchHooks Function()
        > {
  $$SightPresetsTableTableManager(_$AppDatabase db, $SightPresetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SightPresetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SightPresetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SightPresetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> formatVersion = const Value.absent(),
                Value<String> faceId = const Value.absent(),
                Value<double> windMoa = const Value.absent(),
                Value<double> elevMoa = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String> aperture = const Value.absent(),
                Value<String?> ownerId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SightPresetsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                formatVersion: formatVersion,
                faceId: faceId,
                windMoa: windMoa,
                elevMoa: elevMoa,
                label: label,
                aperture: aperture,
                ownerId: ownerId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> formatVersion = const Value.absent(),
                required String faceId,
                required double windMoa,
                required double elevMoa,
                Value<String> label = const Value.absent(),
                Value<String> aperture = const Value.absent(),
                Value<String?> ownerId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SightPresetsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                formatVersion: formatVersion,
                faceId: faceId,
                windMoa: windMoa,
                elevMoa: elevMoa,
                label: label,
                aperture: aperture,
                ownerId: ownerId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SightPresetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SightPresetsTable,
      SightPreset,
      $$SightPresetsTableFilterComposer,
      $$SightPresetsTableOrderingComposer,
      $$SightPresetsTableAnnotationComposer,
      $$SightPresetsTableCreateCompanionBuilder,
      $$SightPresetsTableUpdateCompanionBuilder,
      (
        SightPreset,
        BaseReferences<_$AppDatabase, $SightPresetsTable, SightPreset>,
      ),
      SightPreset,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ScorecardsTableTableManager get scorecards =>
      $$ScorecardsTableTableManager(_db, _db.scorecards);
  $$SightPresetsTableTableManager get sightPresets =>
      $$SightPresetsTableTableManager(_db, _db.sightPresets);
}

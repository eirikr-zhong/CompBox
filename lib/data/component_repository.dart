import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

class ComponentRecord {
  const ComponentRecord({
    required this.location,
    required this.categoryId,
    required this.values,
  });

  final String location;
  final String categoryId;
  final Map<String, Object?> values;

  int get quantity {
    final value = values['quantity'];
    return value is int ? value : 0;
  }

  Map<String, Object?> toJson() => {
    'location': location,
    'categoryId': categoryId,
    ...values,
  };

  factory ComponentRecord.fromJson(Map<String, Object?> json) {
    final location = json['location'];
    final categoryId = json['categoryId'];
    if (location is! String || location.isEmpty) {
      throw const FormatException('A component record needs a location.');
    }
    if (categoryId is! String || categoryId.isEmpty) {
      throw const FormatException('A component record needs a categoryId.');
    }
    return ComponentRecord(
      location: location,
      categoryId: categoryId,
      values: Map<String, Object?>.from(json)
        ..remove('location')
        ..remove('categoryId'),
    );
  }
}

class ComponentRepository {
  ComponentRepository._(this._database) {
    _database.execute('''
      CREATE TABLE IF NOT EXISTS component_records(
        location TEXT PRIMARY KEY,
        data BLOB NOT NULL
      )
    ''');
  }

  final Database _database;

  factory ComponentRepository.inMemory() =>
      ComponentRepository._(sqlite3.openInMemory());

  static Future<ComponentRepository> openDefault() async {
    final directory = await getApplicationDocumentsDirectory();
    final separator = Platform.pathSeparator;
    return ComponentRepository._(
      sqlite3.open('${directory.path}${separator}components.db'),
    );
  }

  List<ComponentRecord> all() {
    final result = _database.select(
      'SELECT location, json(data) AS data FROM component_records ORDER BY location',
    );
    return result.map(_recordFromRow).toList(growable: false);
  }

  ComponentRecord? byLocation(String location) {
    final result = _database.select(
      'SELECT location, json(data) AS data FROM component_records WHERE location = ?',
      [location],
    );
    return result.isEmpty ? null : _recordFromRow(result.first);
  }

  void save(ComponentRecord record) {
    final encoded = jsonEncode(record.toJson());
    _database.execute(
      '''
      INSERT INTO component_records(location, data) VALUES (?, jsonb(?))
      ON CONFLICT(location) DO UPDATE SET data = excluded.data
      ''',
      [record.location, encoded],
    );
  }

  void clear() => _database.execute('DELETE FROM component_records');

  void replaceAll(Iterable<ComponentRecord> records) {
    _database.execute('BEGIN IMMEDIATE');
    try {
      _database.execute('DELETE FROM component_records');
      for (final record in records) {
        save(record);
      }
      _database.execute('COMMIT');
    } catch (_) {
      _database.execute('ROLLBACK');
      rethrow;
    }
  }

  void delete(String location) {
    _database.execute('DELETE FROM component_records WHERE location = ?', [
      location,
    ]);
  }

  void close() => _database.close();

  ComponentRecord _recordFromRow(Row row) {
    final data = row['data'];
    if (data is! String) {
      throw const FormatException('The stored component record is not JSON.');
    }
    final decoded = jsonDecode(data);
    if (decoded is! Map) {
      throw const FormatException('The stored component record is invalid.');
    }
    return ComponentRecord.fromJson(Map<String, Object?>.from(decoded));
  }
}

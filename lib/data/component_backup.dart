import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';

import 'component_repository.dart';
import 'resource_catalog.dart';

const _backupFormat = 'compbox.inventory.backup';
const _backupVersion = 1;
const _backupFileTypes = XTypeGroup(
  label: 'CompBox backup',
  extensions: ['json'],
  mimeTypes: ['application/json'],
  uniformTypeIdentifiers: ['public.json'],
  webWildCards: ['application/json'],
);

class ComponentBackup {
  const ComponentBackup({required this.exportedAt, required this.records});

  final DateTime exportedAt;
  final List<ComponentRecord> records;

  String encode() => const JsonEncoder.withIndent('  ').convert({
    'format': _backupFormat,
    'version': _backupVersion,
    'exportedAt': exportedAt.toUtc().toIso8601String(),
    'records': [
      for (final record in records)
        {
          'location': record.location,
          'categoryId': record.categoryId,
          'values': record.values,
        },
    ],
  });

  factory ComponentBackup.decode(
    String source, {
    required ResourceCatalog catalog,
  }) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('The backup root must be an object.');
    }
    final json = Map<String, Object?>.from(decoded);
    if (json['format'] != _backupFormat || json['version'] != _backupVersion) {
      throw const FormatException('Unsupported CompBox backup format.');
    }
    final exportedAtText = json['exportedAt'];
    final exportedAt = exportedAtText is String
        ? DateTime.tryParse(exportedAtText)
        : null;
    if (exportedAt == null) {
      throw const FormatException('The backup date is invalid.');
    }
    final sourceRecords = json['records'];
    if (sourceRecords is! List) {
      throw const FormatException('The backup records must be a list.');
    }
    final knownCategories = catalog.categories
        .map((category) => category.id)
        .toSet();
    final locations = <String>{};
    final records = <ComponentRecord>[];
    for (var index = 0; index < sourceRecords.length; index++) {
      final sourceRecord = sourceRecords[index];
      if (sourceRecord is! Map) {
        throw FormatException('Record $index must be an object.');
      }
      final recordJson = Map<String, Object?>.from(sourceRecord);
      final location = recordJson['location'];
      final categoryId = recordJson['categoryId'];
      final values = recordJson['values'];
      if (location is! String || !_validLocation(location)) {
        throw FormatException('Record $index has an invalid location.');
      }
      if (!locations.add(location)) {
        throw FormatException(
          'The backup contains duplicate location $location.',
        );
      }
      if (categoryId is! String || !knownCategories.contains(categoryId)) {
        throw FormatException('Record $index has an unknown category.');
      }
      if (values is! Map) {
        throw FormatException('Record $index values must be an object.');
      }
      final recordValues = Map<String, Object?>.from(values);
      if (recordValues.values.any(
        (value) =>
            value != null &&
            value is! String &&
            value is! num &&
            value is! bool,
      )) {
        throw FormatException('Record $index contains an invalid field value.');
      }
      final quantity = recordValues['quantity'];
      if (quantity is! int || quantity < 0) {
        throw FormatException('Record $index has an invalid quantity.');
      }
      records.add(
        ComponentRecord(
          location: location,
          categoryId: categoryId,
          values: recordValues,
        ),
      );
    }
    return ComponentBackup(
      exportedAt: exportedAt.toUtc(),
      records: List.unmodifiable(records),
    );
  }

  static bool _validLocation(String location) {
    final match = RegExp(r'^([A-Z])-(\d{1,3})-(\d{1,3})$').firstMatch(location);
    if (match == null) {
      return false;
    }
    final rack = int.parse(match.group(2)!);
    final slot = int.parse(match.group(3)!);
    return rack >= 1 && rack <= 255 && slot >= 1 && slot <= 255;
  }
}

abstract interface class ComponentBackupFileService {
  Future<bool> exportBackup({
    required String contents,
    required String fileName,
  });

  Future<String?> importBackup();
}

class PlatformComponentBackupFileService implements ComponentBackupFileService {
  const PlatformComponentBackupFileService();

  static const _backupChannel = MethodChannel(
    'io.github.eirikrzhong.compbox/component_backup',
  );

  @override
  Future<bool> exportBackup({
    required String contents,
    required String fileName,
  }) async {
    return await _backupChannel.invokeMethod<bool>('exportBackup', {
          'contents': contents,
          'fileName': fileName,
          'mimeType': 'application/json',
        }) ??
        false;
  }

  @override
  Future<String?> importBackup() async {
    final file = await openFile(acceptedTypeGroups: const [_backupFileTypes]);
    return file?.readAsString();
  }
}

String componentBackupFileName(DateTime now) {
  final local = now.toLocal();
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return 'compbox-backup-${local.year}${twoDigits(local.month)}'
      '${twoDigits(local.day)}-${twoDigits(local.hour)}'
      '${twoDigits(local.minute)}${twoDigits(local.second)}.json';
}

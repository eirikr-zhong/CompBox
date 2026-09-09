import 'dart:convert';

import 'package:comp_box/data/component_backup.dart';
import 'package:comp_box/data/component_repository.dart';
import 'package:comp_box/data/resource_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ResourceCatalog catalog;

  setUpAll(() async {
    catalog = await ResourceCatalog.loadFromAssets();
  });

  test('backup JSON round-trips all component values', () {
    final backup = ComponentBackup(
      exportedAt: DateTime.utc(2026, 9, 8, 12, 30),
      records: const [
        ComponentRecord(
          location: 'A-01-03',
          categoryId: 'capacitor',
          values: {
            'capacitorType': 3,
            'value': 0.0000001,
            'manufacturerModel': 'C100N',
            'quantity': 12,
          },
        ),
      ],
    );

    final restored = ComponentBackup.decode(backup.encode(), catalog: catalog);

    expect(restored.exportedAt, DateTime.utc(2026, 9, 8, 12, 30));
    expect(restored.records.single.location, 'A-01-03');
    expect(restored.records.single.values['capacitorType'], 3);
    expect(restored.records.single.values['value'], 0.0000001);
    expect(restored.records.single.quantity, 12);
  });

  test(
    'backup decoder rejects invalid versions, categories, and duplicates',
    () {
      final source = {
        'format': 'compbox.inventory.backup',
        'version': 1,
        'exportedAt': '2026-09-08T12:30:00Z',
        'records': [
          {
            'location': 'A-01-01',
            'categoryId': 'missing-category',
            'values': {'quantity': 1},
          },
        ],
      };
      expect(
        () => ComponentBackup.decode(jsonEncode(source), catalog: catalog),
        throwsFormatException,
      );

      source['records'] = [
        {
          'location': 'A-01-01',
          'categoryId': 'resistor',
          'values': {'quantity': 1},
        },
        {
          'location': 'A-01-01',
          'categoryId': 'capacitor',
          'values': {'quantity': 2},
        },
      ];
      expect(
        () => ComponentBackup.decode(jsonEncode(source), catalog: catalog),
        throwsFormatException,
      );

      source['version'] = 2;
      expect(
        () => ComponentBackup.decode(jsonEncode(source), catalog: catalog),
        throwsFormatException,
      );
    },
  );

  test('backup file name uses a sortable local timestamp', () {
    expect(
      componentBackupFileName(DateTime(2026, 9, 8, 7, 5, 9)),
      'compbox-backup-20260908-070509.json',
    );
  });
}

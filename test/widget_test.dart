import 'dart:async';
import 'dart:typed_data';

import 'package:comp_box/data/component_backup.dart';
import 'package:comp_box/data/component_repository.dart';
import 'package:comp_box/data/nfc_snapshot.dart';
import 'package:comp_box/data/nfc_tag_service.dart';
import 'package:comp_box/data/resource_catalog.dart';
import 'package:comp_box/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_manager/ndef_record.dart';

void main() {
  late ResourceCatalog catalog;
  late ComponentRepository repository;
  late FakeNfcTagService nfc;
  late FakeComponentBackupFileService backupFiles;

  setUpAll(() async {
    catalog = await ResourceCatalog.loadFromAssets();
  });

  setUp(() {
    repository = ComponentRepository.inMemory();
    nfc = FakeNfcTagService();
    backupFiles = FakeComponentBackupFileService();
  });

  tearDown(() => repository.close());

  Future<void> pumpApp(
    WidgetTester tester, {
    Size surfaceSize = const Size(393, 800),
  }) async {
    await tester.binding.setSurfaceSize(surfaceSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      CompBoxApp(
        locale: const Locale('zh'),
        catalog: catalog,
        repository: repository,
        nfcTagService: nfc,
        backupFileService: backupFiles,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openNfc(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('nfc-button')));
    await tester.pumpAndSettle();
  }

  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('profile-tab')));
    await tester.pumpAndSettle();
  }

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  Future<void> systemBack(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
  }

  Future<void> enterResistor(
    WidgetTester tester, {
    String location = 'A-01-03',
  }) async {
    await reveal(tester, find.byKey(const Key('nfc-field-value')));
    await tester.enterText(find.byKey(const Key('nfc-field-value')), '10 kΩ');
    await reveal(tester, find.byKey(const Key('nfc-location')));
    await tester.enterText(find.byKey(const Key('nfc-location')), location);
  }

  testWidgets('home navigation stays fixed when the keyboard opens', (
    tester,
  ) async {
    await pumpApp(tester);

    final scaffold = tester.widget<Scaffold>(
      find.byKey(const Key('home-scaffold')),
    );
    expect(scaffold.resizeToAvoidBottomInset, isFalse);
  });

  testWidgets('category picker filters and clears the inventory filter', (
    tester,
  ) async {
    repository
      ..save(_resistor('A-01-01'))
      ..save(_capacitor('A-01-02'));
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('category-filter')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('category-picker-sheet')), findsOneWidget);

    await tester.tap(find.byKey(const Key('category-filter-option-capacitor')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('component-A-01-01')), findsNothing);
    expect(find.byKey(const Key('component-A-01-02')), findsOneWidget);

    await tester.tap(find.byKey(const Key('category-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('category-filter-option-all')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('component-A-01-01')), findsOneWidget);
    expect(find.byKey(const Key('component-A-01-02')), findsOneWidget);
  });

  testWidgets('detail page deletes a component record from its bottom action', (
    tester,
  ) async {
    repository.save(_resistor('A-01-01'));
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('component-A-01-01')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('component-detail-delete-button')),
      findsOneWidget,
    );
    expect(repository.byLocation('A-01-01'), isNotNull);

    await tester.tap(find.byKey(const Key('component-detail-delete-button')));
    await tester.pumpAndSettle();
    expect(repository.byLocation('A-01-01'), isNull);
    expect(find.byKey(const Key('component-A-01-01')), findsNothing);
    expect(find.text('记录已删除'), findsOneWidget);
  });

  testWidgets('cancelling database clearing preserves component records', (
    tester,
  ) async {
    repository.save(_resistor('A-01-01'));
    await pumpApp(tester);
    await openSettings(tester);
    expect(find.text('库存概览'), findsNothing);
    expect(find.text('本地数据'), findsNothing);
    await reveal(tester, find.byKey(const Key('clear-database-button')));

    await tester.tap(find.byKey(const Key('clear-database-button')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('clear-database-confirmation')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('clear-database-cancel-button')));
    await tester.pumpAndSettle();

    expect(repository.all(), hasLength(1));
  });

  testWidgets('settings exports all component records as a backup', (
    tester,
  ) async {
    repository
      ..save(_resistor('A-01-01'))
      ..save(_capacitor('B-02-03'));
    await pumpApp(tester);
    await openSettings(tester);

    expect(find.text('备份与恢复'), findsNothing);
    expect(find.byKey(const Key('export-database-card')), findsOneWidget);
    expect(find.byKey(const Key('import-database-card')), findsOneWidget);
    final exportRect = tester.getRect(
      find.byKey(const Key('export-database-button')),
    );
    final importRect = tester.getRect(
      find.byKey(const Key('import-database-button')),
    );
    expect(exportRect.width, 393);
    expect(exportRect.height, greaterThanOrEqualTo(64));
    expect(importRect.top, exportRect.bottom);
    expect(find.text('生成包含全部本地元器件记录的 JSON 备份。'), findsNothing);
    expect(find.text('从芯盒 JSON 备份恢复并覆盖当前库存。'), findsNothing);
    expect(find.text('删除本地保存的全部元器件记录。'), findsNothing);

    await tester.tap(find.byKey(const Key('export-database-button')));
    await tester.pumpAndSettle();

    expect(backupFiles.exportCalls, 1);
    expect(backupFiles.exportedFileName, startsWith('compbox-backup-'));
    expect(backupFiles.exportedFileName, endsWith('.json'));
    final backup = ComponentBackup.decode(
      backupFiles.exportedContents!,
      catalog: catalog,
    );
    expect(backup.records, hasLength(2));
    expect(find.text('已导出 2 条元器件记录'), findsOneWidget);
  });

  testWidgets('cancelling the system export destination shows no success', (
    tester,
  ) async {
    backupFiles.exportResult = false;
    await pumpApp(tester);
    await openSettings(tester);

    await tester.tap(find.byKey(const Key('export-database-button')));
    await tester.pumpAndSettle();

    expect(backupFiles.exportCalls, 1);
    expect(find.textContaining('已导出'), findsNothing);
  });

  testWidgets('database import only replaces inventory after confirmation', (
    tester,
  ) async {
    repository.save(_resistor('A-01-01'));
    backupFiles.importedContents = ComponentBackup(
      exportedAt: DateTime.utc(2026, 9, 8),
      records: [_capacitor('B-02-03')],
    ).encode();
    await pumpApp(tester);
    await openSettings(tester);

    await tester.tap(find.byKey(const Key('import-database-button')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('import-database-confirmation')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('import-database-cancel-button')));
    await tester.pumpAndSettle();
    expect(repository.byLocation('A-01-01'), isNotNull);
    expect(repository.byLocation('B-02-03'), isNull);

    await tester.tap(find.byKey(const Key('import-database-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('import-database-confirm-button')));
    await tester.pumpAndSettle();

    expect(repository.byLocation('A-01-01'), isNull);
    expect(repository.byLocation('B-02-03'), isNotNull);
    expect(find.text('已导入 1 条元器件记录'), findsOneWidget);
    await tester.tap(find.byKey(const Key('home-tab')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('component-A-01-01')), findsNothing);
    expect(find.byKey(const Key('component-B-02-03')), findsOneWidget);
  });

  testWidgets('confirming database clearing refreshes inventory and settings', (
    tester,
  ) async {
    repository
      ..save(_resistor('A-01-01'))
      ..save(_resistor('B-02-03'));
    await pumpApp(tester);
    await openSettings(tester);
    await reveal(tester, find.byKey(const Key('clear-database-button')));

    await tester.tap(find.byKey(const Key('clear-database-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('clear-database-confirm-button')));
    await tester.pumpAndSettle();

    expect(repository.all(), isEmpty);
    expect(find.text('本地数据库已清空'), findsOneWidget);

    await tester.tap(find.byKey(const Key('home-tab')));
    await tester.pumpAndSettle();
    expect(find.text('还没有元器件记录'), findsOneWidget);
  });

  testWidgets(
    'initialization returns to the NFC page with the selected layout',
    (tester) async {
      nfc.scans.add(_blankTag('C0FFEE'));
      await pumpApp(tester);
      await openNfc(tester);

      await tester.tap(find.byKey(const Key('nfc-initialize-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('nfc-initialize-confirm-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('nfc-initialize-columns-3')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('nfc-slot-0')), findsOneWidget);
      expect(find.byKey(const Key('nfc-slot-1')), findsOneWidget);
      expect(find.byKey(const Key('nfc-slot-2')), findsOneWidget);
      expect(nfc.writeCalls, 0);
      expect(repository.all(), isEmpty);
      expect(
        find.byKey(const Key('profile-initialize-tag-button')),
        findsNothing,
      );
      expect(find.byKey(const Key('nfc-grid-overview-page')), findsOneWidget);
    },
  );

  testWidgets('scanned 1x3 grid shows each slot before opening a form', (
    tester,
  ) async {
    nfc.scans.add(_gridTag('A1', [null, _resistor('B-02-01'), null], catalog));
    await pumpApp(tester);
    await openNfc(tester);

    expect(find.byKey(const Key('nfc-slot-0')), findsOneWidget);
    expect(find.byKey(const Key('nfc-slot-1')), findsOneWidget);
    expect(find.byKey(const Key('nfc-slot-2')), findsOneWidget);
    expect(find.byKey(const Key('nfc-category-input')), findsNothing);
    expect(find.text('B-02-01'), findsOneWidget);
  });

  testWidgets('slot editor uses the category picker sheet', (tester) async {
    nfc.scans.add(_gridTag('A1', [null], catalog));
    await pumpApp(tester);
    await openNfc(tester);
    await tester.tap(find.byKey(const Key('nfc-slot-0')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nfc-category-input')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('nfc-category-picker-sheet')), findsOneWidget);
    expect(find.byKey(const Key('nfc-category-option-all')), findsNothing);

    await tester.tap(find.byKey(const Key('nfc-category-option-capacitor')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('nfc-category-picker-sheet')), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const Key('nfc-category-input')),
        matching: find.text('电容'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('slot editor shows and changes a capacitor subtype', (
    tester,
  ) async {
    nfc.scans.add(_gridTag('A1', [_capacitor('A-01-02')], catalog));
    await pumpApp(tester);
    await openNfc(tester);
    await tester.tap(find.byKey(const Key('nfc-slot-0')));
    await tester.pumpAndSettle();

    final valueField = find.byKey(const Key('nfc-field-value'));
    final unitField = find.byKey(const Key('nfc-field-value-unit'));
    await reveal(tester, unitField);
    expect(
      find.descendant(of: unitField, matching: find.text('nF')),
      findsOneWidget,
    );
    expect(tester.widget<TextFormField>(valueField).controller?.text, '100');
    await tester.tap(unitField);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('nfc-field-value-unit-picker-sheet')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const Key('nfc-field-value-unit-option-microfarad')),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: unitField, matching: find.text('µF')),
      findsOneWidget,
    );
    expect(tester.widget<TextFormField>(valueField).controller?.text, '0.1');

    final typeField = find.byKey(const Key('nfc-field-capacitorType'));
    await reveal(tester, typeField);
    expect(
      find.descendant(of: typeField, matching: find.text('陶瓷电容')),
      findsOneWidget,
    );
    await tester.tap(typeField);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('nfc-field-capacitorType-picker-sheet')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const Key('nfc-field-capacitorType-option-tantalum')),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: typeField, matching: find.text('钽电容')),
      findsOneWidget,
    );
  });

  testWidgets(
    'editor back navigation discards drafts until explicitly completed',
    (tester) async {
      nfc.scans.add(_gridTag('A1', [null, null, null], catalog));
      await pumpApp(tester);
      await openNfc(tester);
      await tester.tap(find.byKey(const Key('nfc-slot-0')));
      await tester.pumpAndSettle();
      await enterResistor(tester, location: 'A-01-01');
      await systemBack(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('nfc-slot-1')));
      await tester.pumpAndSettle();
      await enterResistor(tester, location: 'A-01-02');
      await reveal(tester, find.byKey(const Key('nfc-finish-slot-button')));
      await tester.tap(find.byKey(const Key('nfc-finish-slot-button')));
      await tester.pumpAndSettle();

      expect(find.text('A-01-01'), findsNothing);
      expect(find.text('A-01-02'), findsOneWidget);
      expect(nfc.writeCalls, 0);
      expect(repository.all(), isEmpty);

      await reveal(tester, find.byKey(const Key('nfc-save-button')));
      await tester.tap(find.byKey(const Key('nfc-save-button')));
      await tester.pumpAndSettle();

      final written = CompBoxSnapshot.decodeGrid(
        payload: nfc.lastPayload!,
        catalog: catalog,
      );
      expect(written.recordAt(0), isNull);
      expect(written.recordAt(1)?.location, 'A-01-02');
      expect(written.recordAt(2), isNull);
      expect(nfc.writeCalls, 1);
      expect(repository.byLocation('A-01-01'), isNull);
      expect(repository.byLocation('A-01-02')?.quantity, 1);
    },
  );

  testWidgets(
    'final save persists every occupied grid slot after NFC succeeds',
    (tester) async {
      final first = _resistor('A-01-01');
      final second = _resistor('A-01-02');
      nfc.scans.add(_gridTag('A1', [first, second], catalog));
      await pumpApp(tester);
      await openNfc(tester);
      await tester.tap(find.byKey(const Key('nfc-slot-0')));
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const Key('nfc-quantity-input')));
      await tester.enterText(find.byKey(const Key('nfc-quantity-input')), '8');
      await tester.tap(find.byKey(const Key('nfc-finish-slot-button')));
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const Key('nfc-save-button')));
      await tester.tap(find.byKey(const Key('nfc-save-button')));
      await tester.pumpAndSettle();

      final written = CompBoxSnapshot.decodeGrid(
        payload: nfc.lastPayload!,
        catalog: catalog,
      );
      expect(written.recordAt(0)?.quantity, 8);
      expect(written.recordAt(1)?.location, second.location);
      expect(written.recordAt(1)?.quantity, second.quantity);
      expect(repository.byLocation(first.location)?.quantity, 8);
      expect(repository.byLocation(second.location)?.quantity, 1);
    },
  );

  testWidgets('an oversized rewritten grid does not start an NFC write', (
    tester,
  ) async {
    late List<ComponentRecord?> records;
    for (var noteLength = 0; noteLength <= 255; noteLength++) {
      final occupied = List<ComponentRecord>.generate(
        4,
        (index) => ComponentRecord(
          location: 'A-01-0${index + 1}',
          categoryId: 'resistor',
          values: {
            'value': 10000,
            'package': 2,
            'notes': 'x' * noteLength,
            'quantity': 1,
          },
        ),
      );
      final candidate = [...occupied, null];
      try {
        CompBoxSnapshot.encodeGrid(grid: _grid(candidate), catalog: catalog);
      } on SnapshotFormatException {
        continue;
      }
      try {
        CompBoxSnapshot.encodeGrid(
          grid: _grid([...occupied, _formResistor('A-01-05')]),
          catalog: catalog,
        );
      } on SnapshotFormatException {
        records = candidate;
        break;
      }
    }
    nfc.scans.add(_gridTag('A1', records, catalog));
    await pumpApp(tester, surfaceSize: const Size(393, 852));
    await openNfc(tester);
    await tester.tap(find.byKey(const Key('nfc-slot-4')));
    await tester.pumpAndSettle();
    await enterResistor(tester, location: 'A-01-05');
    await tester.tap(find.byKey(const Key('nfc-finish-slot-button')));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('nfc-save-button')));
    await tester.tap(find.byKey(const Key('nfc-save-button')));
    await tester.pumpAndSettle();

    expect(nfc.writeCalls, 0);
    expect(repository.byLocation('A-01-05'), isNull);
  });

  testWidgets(
    'blank, formatable, legacy, malformed, and unknown tags offer initialization',
    (tester) async {
      nfc.scans.add(_blankTag('A0'));
      nfc.scans.add(_formatableTag('A1'));
      nfc.scans.add(_legacyTag('A2', [CompBoxSnapshot.protocolHeader, 0x20]));
      nfc.scans.add(_legacyTag('A3', _legacyInitializationPayload()));
      nfc.scans.add(_corruptGridTag('A4', catalog));
      nfc.scans.add(_unrecognizedTag('A5'));
      await pumpApp(tester);
      await openNfc(tester);

      for (var index = 0; index < 6; index++) {
        expect(find.byKey(const Key('nfc-initialize-button')), findsOneWidget);
        expect(find.byKey(const Key('nfc-category-input')), findsNothing);
        if (index < 5) {
          await systemBack(tester);
          await tester.tap(find.byKey(const Key('nfc-rescan-button')));
          await tester.pumpAndSettle();
        }
      }
    },
  );

  testWidgets('failed final write keeps staged drafts out of the repository', (
    tester,
  ) async {
    nfc.scans.add(_gridTag('A1', [null], catalog));
    nfc.writeError = const NfcTagServiceException(
      NfcTagServiceError.writeFailed,
      'Write failed.',
    );
    await pumpApp(tester);
    await openNfc(tester);
    await tester.tap(find.byKey(const Key('nfc-slot-0')));
    await tester.pumpAndSettle();
    await enterResistor(tester, location: 'A-01-01');
    await tester.tap(find.byKey(const Key('nfc-finish-slot-button')));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('nfc-save-button')));
    await tester.tap(find.byKey(const Key('nfc-save-button')));
    await tester.pumpAndSettle();

    expect(nfc.writeCalls, 1);
    expect(repository.byLocation('A-01-01'), isNull);
    expect(find.byKey(const Key('nfc-grid-overview-page')), findsOneWidget);
    expect(find.text('A-01-01'), findsOneWidget);
  });

  testWidgets('return exits an invalid editor without field validation', (
    tester,
  ) async {
    nfc.scans.add(_gridTag('A1', [null], catalog));
    await pumpApp(tester);
    await openNfc(tester);
    await tester.tap(find.byKey(const Key('nfc-slot-0')));
    await tester.pumpAndSettle();

    await systemBack(tester);

    expect(find.byKey(const Key('nfc-slot-editor-page')), findsNothing);
    expect(find.byKey(const Key('nfc-grid-overview-page')), findsOneWidget);
    expect(find.byKey(const Key('nfc-location')), findsNothing);
  });

  testWidgets('editor AppBar back discards a valid draft', (tester) async {
    nfc.scans.add(_gridTag('A1', [null], catalog));
    await pumpApp(tester);
    await openNfc(tester);
    await tester.tap(find.byKey(const Key('nfc-slot-0')));
    await tester.pumpAndSettle();
    await enterResistor(tester, location: 'A-01-01');

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('nfc-grid-overview-page')), findsOneWidget);
    expect(find.text('A-01-01'), findsNothing);
    expect(nfc.writeCalls, 0);
  });

  testWidgets('finish editing keeps field validation before staging a draft', (
    tester,
  ) async {
    nfc.scans.add(_gridTag('A1', [null], catalog));
    await pumpApp(tester, surfaceSize: const Size(393, 852));
    await openNfc(tester);
    await tester.tap(find.byKey(const Key('nfc-slot-0')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nfc-finish-slot-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('nfc-slot-editor-page')), findsOneWidget);
    expect(find.byKey(const Key('nfc-location')), findsOneWidget);
  });

  testWidgets('finish editing uses the full-width primary button', (
    tester,
  ) async {
    nfc.scans.add(_gridTag('A1', [null], catalog));
    await pumpApp(tester);
    await openNfc(tester);
    await tester.tap(find.byKey(const Key('nfc-slot-0')));
    await tester.pumpAndSettle();

    final button = tester.getSize(
      find.byKey(const Key('nfc-finish-slot-button')),
    );

    expect(button.width, 361);
    expect(button.height, 52);
    expect(
      tester.widget<FilledButton>(
        find.byKey(const Key('nfc-finish-slot-button')),
      ),
      isA<FilledButton>(),
    );
  });

  testWidgets('clear tag writes an empty grid after prompting for a rescan', (
    tester,
  ) async {
    nfc.scans.add(
      _gridTag('A1', [_resistor('A-01-01'), _resistor('A-01-02')], catalog),
    );
    await pumpApp(tester);
    await openNfc(tester);

    expect(find.text('保存'), findsOneWidget);
    await reveal(tester, find.byKey(const Key('nfc-clear-tag-button')));
    await tester.tap(find.byKey(const Key('nfc-clear-tag-button')));
    await tester.pumpAndSettle();

    final written = CompBoxSnapshot.decodeGrid(
      payload: nfc.lastPayload!,
      catalog: catalog,
    );
    expect(written.columns, 2);
    expect(written.recordAt(0), isNull);
    expect(written.recordAt(1), isNull);
    expect(nfc.writeCalls, 1);
    expect(find.text('A-01-01'), findsNothing);
    expect(find.text('A-01-02'), findsNothing);
  });

  testWidgets('grid overview rescan button reads a new tag', (tester) async {
    nfc.scans.add(_gridTag('A1', [null], catalog));
    nfc.scans.add(_gridTag('B2', [null, null, null], catalog));
    await pumpApp(tester);
    await openNfc(tester);

    expect(find.byKey(const Key('nfc-slot-0')), findsOneWidget);
    expect(find.byKey(const Key('nfc-slot-2')), findsNothing);
    await tester.tap(find.byKey(const Key('nfc-rescan-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('nfc-slot-0')), findsOneWidget);
    expect(find.byKey(const Key('nfc-slot-1')), findsOneWidget);
    expect(find.byKey(const Key('nfc-slot-2')), findsOneWidget);
  });

  testWidgets('home navigation shows a label without unused shortcuts', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('主页'), findsOneWidget);
    expect(find.text('设置'), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    expect(find.byIcon(Icons.account_circle_rounded), findsNothing);
    expect(find.byKey(const Key('scan-button')), findsNothing);
  });

  testWidgets('clear tag only shows write progress in its scan dialog', (
    tester,
  ) async {
    nfc.scans.add(_gridTag('A1', [null], catalog));
    nfc.pendingWrite = Completer<void>();
    await pumpApp(tester);
    await openNfc(tester);

    await tester.tap(find.byKey(const Key('nfc-clear-tag-button')));
    await tester.pump();

    expect(find.byKey(const Key('nfc-write-dialog')), findsOneWidget);
    expect(find.byKey(const Key('nfc-write-progress')), findsOneWidget);

    nfc.pendingWrite!.complete();
    await tester.pumpAndSettle();
  });
}

ComponentRecord _resistor(String location) => ComponentRecord(
  location: location,
  categoryId: 'resistor',
  values: const {'value': 10000, 'package': 2, 'quantity': 1},
);

ComponentRecord _formResistor(String location) => ComponentRecord(
  location: location,
  categoryId: 'resistor',
  values: const {'value': 10000, 'quantity': 1},
);

ComponentRecord _capacitor(String location) => ComponentRecord(
  location: location,
  categoryId: 'capacitor',
  values: const {
    'capacitorType': 1,
    'value': 0.0000001,
    'package': 2,
    'quantity': 1,
  },
);

ScannedNfcTag _gridTag(
  String uid,
  List<ComponentRecord?> records,
  ResourceCatalog catalog,
) => _ndefTag(
  uid,
  CompBoxSnapshot.encodeGrid(grid: _grid(records), catalog: catalog),
);

CompBoxTagGrid _grid(List<ComponentRecord?> records) => CompBoxTagGrid(
  columns: records.length,
  slots: [
    for (var index = 0; index < records.length; index++)
      CompBoxTagSlot(index: index, record: records[index]),
  ],
);

ScannedNfcTag _legacyTag(String uid, List<int> payload) =>
    _ndefTag(uid, Uint8List.fromList(payload));

ScannedNfcTag _blankTag(String uid) => ScannedNfcTag(
  uid: uid,
  kind: NfcTagKind.blankNdef,
  isWritable: true,
  maxSize: 144,
);

ScannedNfcTag _formatableTag(String uid) =>
    ScannedNfcTag(uid: uid, kind: NfcTagKind.formatable);

ScannedNfcTag _corruptGridTag(String uid, ResourceCatalog catalog) {
  final payload = CompBoxSnapshot.encodeGrid(
    grid: _grid([_resistor('A-01-01')]),
    catalog: catalog,
  );
  payload[payload.length - 1] ^= 0xFF;
  return _ndefTag(uid, payload);
}

ScannedNfcTag _unrecognizedTag(String uid) => ScannedNfcTag(
  uid: uid,
  kind: NfcTagKind.ndef,
  isWritable: true,
  maxSize: 144,
  message: NdefMessage(
    records: [
      NdefRecord(
        typeNameFormat: TypeNameFormat.wellKnown,
        type: Uint8List.fromList([0x54]),
        identifier: Uint8List(0),
        payload: Uint8List.fromList([0x02, 0x65, 0x6E, 0x68, 0x69]),
      ),
    ],
  ),
);

Uint8List _legacyInitializationPayload() {
  final body = [CompBoxSnapshot.protocolHeader, 0x2F];
  final crc = CompBoxSnapshot.crc16(body);
  return Uint8List.fromList([...body, crc >> 8, crc & 0xFF]);
}

ScannedNfcTag _ndefTag(String uid, Uint8List payload) => ScannedNfcTag(
  uid: uid,
  kind: NfcTagKind.ndef,
  isWritable: true,
  maxSize: 144,
  message: NdefMessage(
    records: [
      NdefRecord(
        typeNameFormat: TypeNameFormat.unknown,
        type: Uint8List(0),
        identifier: Uint8List(0),
        payload: payload,
      ),
    ],
  ),
);

class FakeNfcTagService implements NfcTagService {
  final List<ScannedNfcTag> scans = [];
  Uint8List? lastPayload;
  String? lastWriteUid;
  int writeCalls = 0;
  NfcTagServiceException? writeError;
  Completer<void>? pendingWrite;

  @override
  Future<void> cancelSession() async {}

  @override
  Future<NfcServiceAvailability> checkAvailability() async =>
      NfcServiceAvailability.enabled;

  @override
  Future<ScannedNfcTag> readTag() async {
    if (scans.isEmpty) {
      throw const NfcTagServiceException(
        NfcTagServiceError.readFailed,
        'No fake tag.',
      );
    }
    return scans.removeAt(0);
  }

  @override
  Future<void> writeTag({
    required String expectedUid,
    required Uint8List payload,
  }) async {
    writeCalls++;
    lastWriteUid = expectedUid;
    lastPayload = payload;
    if (pendingWrite case final pending?) {
      await pending.future;
      pendingWrite = null;
    }
    if (writeError case final error?) {
      throw error;
    }
  }
}

class FakeComponentBackupFileService implements ComponentBackupFileService {
  int exportCalls = 0;
  bool exportResult = true;
  String? exportedContents;
  String? exportedFileName;
  String? importedContents;

  @override
  Future<bool> exportBackup({
    required String contents,
    required String fileName,
  }) async {
    exportCalls++;
    exportedContents = contents;
    exportedFileName = fileName;
    return exportResult;
  }

  @override
  Future<String?> importBackup() async => importedContents;
}

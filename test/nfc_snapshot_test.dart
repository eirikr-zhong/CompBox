import 'dart:typed_data';

import 'package:comp_box/data/component_repository.dart';
import 'package:comp_box/data/nfc_snapshot.dart';
import 'package:comp_box/data/nfc_tag_service.dart';
import 'package:comp_box/data/resource_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ResourceCatalog catalog;

  setUpAll(() async {
    catalog = await ResourceCatalog.loadFromAssets();
  });

  const resistor = ComponentRecord(
    location: 'A-01-03',
    categoryId: 'resistor',
    values: {
      'value': 4990,
      'tolerance': 1,
      'package': 2,
      'manufacturerModel': 'RC0603FR-074K99L',
      'quantity': 128,
    },
  );
  const capacitor = ComponentRecord(
    location: 'Z-255-255',
    categoryId: 'capacitor',
    values: {
      'capacitorType': 3,
      'value': 0.0000124,
      'tolerance': 3,
      'package': 'custom',
      'manufacturerModel': 'C-124',
      'notes': 'custom note',
      'quantity': 7,
    },
  );

  CompBoxTagGrid grid(int columns, List<ComponentRecord?> records) =>
      CompBoxTagGrid(
        columns: columns,
        slots: [
          for (var index = 0; index < columns; index++)
            CompBoxTagSlot(index: index, record: records[index]),
        ],
      );

  test('empty 1x1, 1x3, and 1x5 grids round-trip', () {
    for (final columns in [1, 3, 5]) {
      final payload = CompBoxSnapshot.initializationPayload(columns);
      final decoded = CompBoxSnapshot.decodeGrid(
        payload: payload,
        catalog: catalog,
      );

      expect(decoded.columns, columns);
      expect(decoded.slots.every((slot) => slot.isEmpty), isTrue);
      expect(CompBoxSnapshot.layoutOf(payload), CompBoxTagLayout.grid);
    }
  });

  test('mixed slots round-trip independently', () {
    final payload = CompBoxSnapshot.encodeGrid(
      grid: grid(5, [resistor, null, capacitor, null, resistor]),
      catalog: catalog,
    );
    final decoded = CompBoxSnapshot.decodeGrid(
      payload: payload,
      catalog: catalog,
    );

    expect(decoded.recordAt(0)?.values['value'], 4990);
    expect(decoded.recordAt(1), isNull);
    expect(decoded.recordAt(2)?.location, 'Z-255-255');
    expect(decoded.recordAt(2)?.values['capacitorType'], 3);
    expect(
      decoded.recordAt(2)?.values['value'],
      closeTo(0.0000124, 0.000000001),
    );
    expect(decoded.recordAt(3), isNull);
    expect(decoded.recordAt(4)?.quantity, 128);
  });

  test('replacing one slot keeps all other slot records', () {
    final initial = grid(3, [resistor, null, capacitor]);
    final replaced = initial.withRecord(1, resistor);
    final decoded = CompBoxSnapshot.decodeGrid(
      payload: CompBoxSnapshot.encodeGrid(grid: replaced, catalog: catalog),
      catalog: catalog,
    );

    expect(decoded.recordAt(0)?.location, resistor.location);
    expect(decoded.recordAt(1)?.location, resistor.location);
    expect(decoded.recordAt(2)?.location, capacitor.location);
  });

  test(
    'invalid columns, truncation, checksum errors, and oversized grids fail',
    () {
      final invalidColumns = _payload([
        CompBoxSnapshot.protocolHeader,
        0x40,
        6,
      ]);
      expect(
        () => CompBoxSnapshot.decodeGrid(
          payload: invalidColumns,
          catalog: catalog,
        ),
        throwsA(isA<SnapshotFormatException>()),
      );

      final valid = CompBoxSnapshot.initializationPayload(3);
      final truncated = Uint8List.fromList(valid.sublist(0, valid.length - 1));
      expect(
        () => CompBoxSnapshot.decodeGrid(payload: truncated, catalog: catalog),
        throwsA(isA<SnapshotFormatException>()),
      );

      final badCrc = Uint8List.fromList(valid)..[3] ^= 1;
      expect(
        () => CompBoxSnapshot.decodeGrid(payload: badCrc, catalog: catalog),
        throwsA(isA<SnapshotFormatException>()),
      );

      final oversized = _payload([
        CompBoxSnapshot.protocolHeader,
        0x40,
        1,
        0,
        ...List.filled(132, 0),
      ]);
      expect(
        () => CompBoxSnapshot.decodeGrid(payload: oversized, catalog: catalog),
        throwsA(isA<SnapshotFormatException>()),
      );
    },
  );

  test('legacy formats remain recognizable but cannot be decoded as grids', () {
    final legacyInitialization = _payload([
      CompBoxSnapshot.protocolHeader,
      0x2F,
    ]);
    final legacyRecord = Uint8List.fromList([
      CompBoxSnapshot.protocolHeader,
      0x20,
    ]);

    expect(
      CompBoxSnapshot.layoutOf(legacyInitialization),
      CompBoxTagLayout.legacyInitialization,
    );
    expect(
      CompBoxSnapshot.layoutOf(legacyRecord),
      CompBoxTagLayout.legacyRecord,
    );
    expect(
      () => CompBoxSnapshot.decodeGrid(
        payload: legacyInitialization,
        catalog: catalog,
      ),
      throwsA(isA<SnapshotFormatException>()),
    );
  });

  test('NDEF size, capacity, writability, and UID are checked', () {
    final message = NfcWriteValidator.messageFor(
      CompBoxSnapshot.initializationPayload(5),
    );
    NfcWriteValidator.validate(
      expectedUid: 'AA',
      actualUid: 'AA',
      message: message,
      isWritable: true,
      maxSize: 137,
    );
    expect(
      () => NfcWriteValidator.validate(
        expectedUid: 'AA',
        actualUid: 'BB',
        message: message,
      ),
      throwsA(isA<NfcTagServiceException>()),
    );
  });
}

Uint8List _payload(List<int> body) {
  final crc = CompBoxSnapshot.crc16(body);
  return Uint8List.fromList([...body, crc >> 8, crc & 0xFF]);
}

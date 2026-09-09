import 'dart:convert';
import 'dart:typed_data';

import 'component_repository.dart';
import 'resource_catalog.dart';

/// Compact, typed 1xN container stored in the sole NDEF record on a CompBox
/// tag. Each occupied slot holds an independently encoded component record.
class CompBoxSnapshot {
  CompBoxSnapshot._();

  static const int protocolHeader = 0xCB;

  /// The retired one-record payload version. It remains recognizable so the UI
  /// can ask the user to initialize the tag again.
  static const int schemaVersion = 2;
  static const int _gridVersion = 0x40;
  static const int _legacyInitializationMarker = 0x2F;
  static const int minColumns = 1;
  static const int maxColumns = 5;
  static const int conservativeNdefLimit = 137;

  static const int _dictionary = 0;
  static const int _preset = 1;
  static const int _unsignedInteger = 2;
  static const int _float32 = 3;
  static const int _text = 4;

  static int ndefMessageByteLength(int payloadLength) => payloadLength + 3;

  /// A newly initialized tag is an empty 1xN container, not a separate marker.
  static Uint8List initializationPayload(int columns) =>
      encodeGrid(grid: CompBoxTagGrid.empty(columns), catalog: null);

  static CompBoxTagLayout layoutOf(Uint8List payload) {
    if (payload.isEmpty || payload.first != protocolHeader) {
      return CompBoxTagLayout.unrecognized;
    }
    if (payload.length == 4 && payload[1] == _legacyInitializationMarker) {
      final expectedCrc = (payload[2] << 8) | payload[3];
      return crc16(payload.sublist(0, 2)) == expectedCrc
          ? CompBoxTagLayout.legacyInitialization
          : CompBoxTagLayout.unrecognized;
    }
    return switch (payload.length > 1 ? payload[1] : -1) {
      _gridVersion => CompBoxTagLayout.grid,
      _ when payload.length > 1 && payload[1] == schemaVersion << 4 =>
        CompBoxTagLayout.legacyRecord,
      _ => CompBoxTagLayout.unrecognized,
    };
  }

  static Uint8List encodeGrid({
    required CompBoxTagGrid grid,
    ResourceCatalog? catalog,
  }) {
    final body = <int>[protocolHeader, _gridVersion, grid.columns];
    for (final slot in grid.slots) {
      final record = slot.record;
      if (record == null) {
        body.add(0);
        continue;
      }
      if (catalog == null) {
        throw const SnapshotFormatException(
          SnapshotErrorCode.invalidGrid,
          'A resource catalog is required for occupied slots.',
        );
      }
      final encoded = _encodeRecordBody(record: record, catalog: catalog);
      body.addAll(_encodeVarInt(encoded.length));
      body.addAll(encoded);
    }
    final crc = crc16(body);
    final payload = Uint8List.fromList([...body, crc >> 8, crc & 0xFF]);
    if (ndefMessageByteLength(payload.length) > conservativeNdefLimit) {
      throw SnapshotFormatException(
        SnapshotErrorCode.containerTooLarge,
        'The CompBox grid exceeds the conservative NDEF size limit.',
        bytes: ndefMessageByteLength(payload.length),
      );
    }
    return payload;
  }

  static CompBoxTagGrid decodeGrid({
    required Uint8List payload,
    required ResourceCatalog catalog,
  }) {
    if (layoutOf(payload) != CompBoxTagLayout.grid) {
      throw SnapshotFormatException(
        SnapshotErrorCode.version,
        'Unsupported CompBox tag layout.',
      );
    }
    if (payload.length < 6) {
      throw const SnapshotFormatException(
        SnapshotErrorCode.truncated,
        'The CompBox grid is too short.',
      );
    }
    if (ndefMessageByteLength(payload.length) > conservativeNdefLimit) {
      throw SnapshotFormatException(
        SnapshotErrorCode.containerTooLarge,
        'The CompBox grid exceeds the conservative NDEF size limit.',
        bytes: ndefMessageByteLength(payload.length),
      );
    }
    final bodyLength = payload.length - 2;
    final expectedCrc = (payload[bodyLength] << 8) | payload[bodyLength + 1];
    if (crc16(payload.sublist(0, bodyLength)) != expectedCrc) {
      throw const SnapshotFormatException(
        SnapshotErrorCode.crc,
        'The CompBox grid checksum does not match.',
      );
    }
    final columns = payload[2];
    if (columns < minColumns || columns > maxColumns) {
      throw const SnapshotFormatException(
        SnapshotErrorCode.invalidGrid,
        'CompBox grids must have between 1 and 5 columns.',
      );
    }
    var offset = 3;
    final slots = <CompBoxTagSlot>[];
    for (var index = 0; index < columns; index++) {
      final length = _decodeVarInt(payload, offset, bodyLength);
      offset = length.nextOffset;
      if (length.value == 0) {
        slots.add(CompBoxTagSlot(index: index));
        continue;
      }
      final end = offset + length.value;
      if (end > bodyLength) {
        throw const SnapshotFormatException(
          SnapshotErrorCode.truncated,
          'A CompBox grid slot is truncated.',
        );
      }
      slots.add(
        CompBoxTagSlot(
          index: index,
          record: _decodeRecordBody(
            payload: Uint8List.sublistView(payload, offset, end),
            catalog: catalog,
          ),
        ),
      );
      offset = end;
    }
    if (offset != bodyLength) {
      throw const SnapshotFormatException(
        SnapshotErrorCode.invalidGrid,
        'The CompBox grid has trailing data.',
      );
    }
    return CompBoxTagGrid(columns: columns, slots: slots);
  }

  static List<int> _encodeRecordBody({
    required ComponentRecord record,
    required ResourceCatalog catalog,
  }) {
    final category = catalog.categoryById(record.categoryId);
    final attributes = <int>[];
    for (final field in catalog.fieldsFor(category)) {
      if (field.id == 'quantity') {
        continue;
      }
      final value = record.values[field.id];
      if (value == null || value is String && value.trim().isEmpty) {
        continue;
      }
      attributes.addAll(_encodeAttribute(category, field, value));
    }

    final count = record.quantity;
    if (count < 0 || count > 0xFFFFFFFF) {
      throw const SnapshotFormatException(
        SnapshotErrorCode.invalidCount,
        'Quantity must be between 0 and 4294967295.',
      );
    }
    final location = CompBoxLocation.parse(record.location);
    return <int>[
      category.nfc.code,
      ..._encodeVarInt(count),
      location.zone,
      location.rack,
      location.slot,
      ..._encodeVarInt(attributes.length),
      ...attributes,
    ];
  }

  static List<int> _encodeAttribute(
    CategoryDefinition category,
    FieldDefinition field,
    Object value,
  ) {
    final nfc = field.nfc;
    if (nfc == null) {
      throw const SnapshotFormatException(
        SnapshotErrorCode.invalidAttribute,
        'Only NFC fields may be stored on a tag.',
      );
    }
    final header = <int>[nfc.code];
    final categoryValue = category.nfc.value;
    final isNominalValue = categoryValue?.fieldId == field.id;
    final numericType = isNominalValue
        ? categoryValue!.valueType
        : field.valueType;
    if (numericType != null) {
      if (value is! num) {
        throw const SnapshotFormatException(
          SnapshotErrorCode.invalidValue,
          'Numeric fields must not be encoded as text.',
        );
      }
      final numeric = value.toDouble();
      if (!numeric.isFinite || numeric < 0) {
        throw const SnapshotFormatException(
          SnapshotErrorCode.invalidValue,
          'Numeric fields must be finite and non-negative.',
        );
      }
      if (isNominalValue) {
        final preset = categoryValue!.presetByValue(value);
        if (preset != null) {
          return [...header, _preset, ..._encodeVarInt(preset.index)];
        }
      }
      final dictionaryCode = _numericDictionaryCode(
        category: category,
        field: field,
        value: value,
      );
      if (dictionaryCode != null) {
        return [...header, _dictionary, ..._encodeVarInt(dictionaryCode)];
      }
      if (numeric == numeric.roundToDouble() && numeric <= 0xFFFFFFFF) {
        return [...header, _unsignedInteger, ..._encodeVarInt(numeric.toInt())];
      }
      final bytes = ByteData(4)..setFloat32(0, numeric, Endian.big);
      return [...header, _float32, ...bytes.buffer.asUint8List()];
    }

    if (value is int && nfc.dictionaryByCode(value) != null) {
      return [...header, _dictionary, ..._encodeVarInt(value)];
    }
    if (value is! String) {
      throw const SnapshotFormatException(
        SnapshotErrorCode.invalidAttribute,
        'An unconfigured field must use text or a dictionary index.',
      );
    }
    final bytes = utf8.encode(value.trim());
    if (bytes.length > 255) {
      throw SnapshotFormatException(
        SnapshotErrorCode.attributeTooLong,
        '${field.id} is longer than 255 UTF-8 bytes.',
      );
    }
    return [...header, _text, ..._encodeVarInt(bytes.length), ...bytes];
  }

  static int? _numericDictionaryCode({
    required CategoryDefinition category,
    required FieldDefinition field,
    required num value,
  }) {
    final categoryValue = category.nfc.value;
    final dictionary = categoryValue?.fieldId == field.id
        ? categoryValue!.dictionary
        : field.nfc!.dictionary;
    final type = categoryValue?.fieldId == field.id
        ? categoryValue!.valueType
        : field.valueType;
    if (type == null) {
      return null;
    }
    for (final entry in dictionary) {
      final candidate = parseNumericValue(
        categoryValue?.fieldId == field.id
            ? entry.label.resolve('en')
            : entry.id,
        type,
      );
      if (candidate != null && _sameNumber(candidate, value)) {
        return entry.nfcCode;
      }
    }
    return null;
  }

  static ComponentRecord _decodeRecordBody({
    required Uint8List payload,
    required ResourceCatalog catalog,
  }) {
    if (payload.length < 6) {
      throw const SnapshotFormatException(
        SnapshotErrorCode.truncated,
        'The CompBox slot record is too short.',
      );
    }
    final bodyLength = payload.length;
    final category = _categoryByCode(payload[0], catalog);
    var offset = 1;
    final count = _decodeVarInt(payload, offset, bodyLength);
    offset = count.nextOffset;
    if (offset + 3 > bodyLength) {
      throw const SnapshotFormatException(
        SnapshotErrorCode.truncated,
        'The CompBox location is truncated.',
      );
    }
    final location = CompBoxLocation(
      zone: payload[offset],
      rack: payload[offset + 1],
      slot: payload[offset + 2],
    );
    offset += 3;
    final length = _decodeVarInt(payload, offset, bodyLength);
    offset = length.nextOffset;
    final attributesEnd = offset + length.value;
    if (attributesEnd != bodyLength) {
      throw const SnapshotFormatException(
        SnapshotErrorCode.truncated,
        'The field section has an invalid length.',
      );
    }

    final values = <String, Object?>{'quantity': count.value};
    while (offset < attributesEnd) {
      if (offset + 2 > attributesEnd) {
        throw const SnapshotFormatException(
          SnapshotErrorCode.truncated,
          'A field attribute is truncated.',
        );
      }
      final field = _fieldByCode(payload[offset++], catalog);
      if (!category.fieldIds.contains(field.id) ||
          values.containsKey(field.id)) {
        throw const SnapshotFormatException(
          SnapshotErrorCode.invalidAttribute,
          'The field section contains an invalid attribute.',
        );
      }
      final type = payload[offset++];
      final decoded = _decodeAttribute(
        payload: payload,
        offset: offset,
        end: attributesEnd,
        category: category,
        field: field,
        type: type,
      );
      values[field.id] = decoded.value;
      offset = decoded.nextOffset;
    }
    return ComponentRecord(
      location: location.format(),
      categoryId: category.id,
      values: values,
    );
  }

  static _AttributeResult _decodeAttribute({
    required Uint8List payload,
    required int offset,
    required int end,
    required CategoryDefinition category,
    required FieldDefinition field,
    required int type,
  }) {
    final categoryValue = category.nfc.value;
    final isNominalValue = categoryValue?.fieldId == field.id;
    final numericType = isNominalValue
        ? categoryValue!.valueType
        : field.valueType;
    if (type == _preset) {
      if (!isNominalValue) {
        throw const SnapshotFormatException(
          SnapshotErrorCode.invalidAttribute,
          'Only nominal values may use a series preset.',
        );
      }
      final index = _decodeVarInt(payload, offset, end);
      final preset = categoryValue!.presetByIndex(index.value);
      if (preset == null) {
        throw const SnapshotFormatException(
          SnapshotErrorCode.invalidValue,
          'Unknown value preset index.',
        );
      }
      return _AttributeResult(
        _normalizeNumeric(preset.value),
        index.nextOffset,
      );
    }
    if (type == _dictionary) {
      final code = _decodeVarInt(payload, offset, end);
      final dictionary = isNominalValue
          ? categoryValue!.dictionary
          : field.nfc!.dictionary;
      final entry = dictionary
          .where((item) => item.nfcCode == code.value)
          .firstOrNull;
      if (entry == null) {
        throw const SnapshotFormatException(
          SnapshotErrorCode.invalidAttribute,
          'Unknown dictionary index.',
        );
      }
      if (numericType == null) {
        return _AttributeResult(code.value, code.nextOffset);
      }
      final numeric = parseNumericValue(
        isNominalValue ? entry.label.resolve('en') : entry.id,
        numericType,
      );
      if (numeric == null) {
        throw const SnapshotFormatException(
          SnapshotErrorCode.invalidAttribute,
          'A numeric dictionary entry cannot be decoded.',
        );
      }
      return _AttributeResult(numeric, code.nextOffset);
    }
    if (type == _unsignedInteger) {
      if (numericType == null) {
        throw const SnapshotFormatException(
          SnapshotErrorCode.invalidAttribute,
          'Only numeric fields may use numeric encoding.',
        );
      }
      final number = _decodeVarInt(payload, offset, end);
      return _AttributeResult(number.value, number.nextOffset);
    }
    if (type == _float32) {
      if (numericType == null || offset + 4 > end) {
        throw const SnapshotFormatException(
          SnapshotErrorCode.invalidAttribute,
          'A decimal attribute is invalid.',
        );
      }
      final value = ByteData.sublistView(
        payload,
        offset,
        offset + 4,
      ).getFloat32(0, Endian.big);
      if (!value.isFinite || value < 0) {
        throw const SnapshotFormatException(
          SnapshotErrorCode.invalidAttribute,
          'A decimal attribute is invalid.',
        );
      }
      return _AttributeResult(_normalizeNumeric(value), offset + 4);
    }
    if (type == _text) {
      if (numericType != null) {
        throw const SnapshotFormatException(
          SnapshotErrorCode.invalidAttribute,
          'Numeric fields may not use text encoding.',
        );
      }
      final length = _decodeVarInt(payload, offset, end);
      if (length.nextOffset + length.value > end) {
        throw const SnapshotFormatException(
          SnapshotErrorCode.truncated,
          'A text attribute is truncated.',
        );
      }
      try {
        return _AttributeResult(
          utf8.decode(
            payload.sublist(
              length.nextOffset,
              length.nextOffset + length.value,
            ),
          ),
          length.nextOffset + length.value,
        );
      } on FormatException {
        throw const SnapshotFormatException(
          SnapshotErrorCode.invalidAttribute,
          'A text attribute is not valid UTF-8.',
        );
      }
    }
    throw const SnapshotFormatException(
      SnapshotErrorCode.invalidAttribute,
      'Unknown field attribute encoding.',
    );
  }

  static int crc16(List<int> bytes) {
    var crc = 0xFFFF;
    for (final byte in bytes) {
      crc ^= byte << 8;
      for (var bit = 0; bit < 8; bit++) {
        crc = crc & 0x8000 != 0 ? (crc << 1) ^ 0x1021 : crc << 1;
        crc &= 0xFFFF;
      }
    }
    return crc;
  }

  static List<int> _encodeVarInt(int value) {
    final bytes = <int>[];
    do {
      var next = value & 0x7F;
      value >>= 7;
      if (value != 0) {
        next |= 0x80;
      }
      bytes.add(next);
    } while (value != 0);
    return bytes;
  }

  static _VarIntResult _decodeVarInt(Uint8List payload, int offset, int end) {
    var value = 0;
    for (var index = 0; index < 5; index++) {
      if (offset >= end) {
        throw const SnapshotFormatException(
          SnapshotErrorCode.truncated,
          'A variable-length integer is truncated.',
        );
      }
      final byte = payload[offset++];
      value |= (byte & 0x7F) << (index * 7);
      if (byte & 0x80 == 0) {
        return _VarIntResult(value, offset);
      }
    }
    throw const SnapshotFormatException(
      SnapshotErrorCode.invalidAttribute,
      'A variable-length integer is too long.',
    );
  }

  static CategoryDefinition _categoryByCode(int code, ResourceCatalog catalog) {
    try {
      return catalog.categoryByNfcCode(code);
    } on FormatException {
      throw const SnapshotFormatException(
        SnapshotErrorCode.unknownCategory,
        'Unknown component category code.',
      );
    }
  }

  static FieldDefinition _fieldByCode(int code, ResourceCatalog catalog) {
    try {
      return catalog.fieldByNfcCode(code);
    } on FormatException {
      throw const SnapshotFormatException(
        SnapshotErrorCode.invalidAttribute,
        'Unknown field code.',
      );
    }
  }
}

bool _sameNumber(num left, num right) =>
    (left.toDouble() - right.toDouble()).abs() <= 0.0000001;

num _normalizeNumeric(double value) =>
    value == value.roundToDouble() ? value.toInt() : value;

enum CompBoxTagLayout { grid, legacyRecord, legacyInitialization, unrecognized }

class CompBoxTagSlot {
  const CompBoxTagSlot({required this.index, this.record});

  final int index;
  final ComponentRecord? record;

  bool get isEmpty => record == null;
}

class CompBoxTagGrid {
  CompBoxTagGrid({required this.columns, required List<CompBoxTagSlot> slots})
    : slots = List.unmodifiable(slots) {
    if (columns < CompBoxSnapshot.minColumns ||
        columns > CompBoxSnapshot.maxColumns ||
        this.slots.length != columns ||
        this.slots.asMap().entries.any(
          (entry) => entry.value.index != entry.key,
        )) {
      throw const SnapshotFormatException(
        SnapshotErrorCode.invalidGrid,
        'A CompBox grid needs consecutive slots for 1 to 5 columns.',
      );
    }
  }

  factory CompBoxTagGrid.empty(int columns) => CompBoxTagGrid(
    columns: columns,
    slots: List.generate(columns, (index) => CompBoxTagSlot(index: index)),
  );

  final int columns;
  final List<CompBoxTagSlot> slots;

  ComponentRecord? recordAt(int index) => slots[index].record;

  CompBoxTagGrid withRecord(int index, ComponentRecord? record) {
    if (index < 0 || index >= columns) {
      throw RangeError.index(index, slots, 'index');
    }
    return CompBoxTagGrid(
      columns: columns,
      slots: [
        for (final slot in slots)
          slot.index == index
              ? CompBoxTagSlot(index: index, record: record)
              : slot,
      ],
    );
  }
}

class CompBoxLocation {
  const CompBoxLocation({
    required this.zone,
    required this.rack,
    required this.slot,
  });

  final int zone;
  final int rack;
  final int slot;

  factory CompBoxLocation.parse(String location) {
    final match = RegExp(r'^([A-Z])-(\d{1,3})-(\d{1,3})$').firstMatch(location);
    if (match == null) {
      throw const SnapshotFormatException(
        SnapshotErrorCode.location,
        'Location must use A-01-03 format.',
      );
    }
    final rack = int.parse(match.group(2)!);
    final slot = int.parse(match.group(3)!);
    if (rack < 1 || rack > 255 || slot < 1 || slot > 255) {
      throw const SnapshotFormatException(
        SnapshotErrorCode.location,
        'Location rack and slot must be between 1 and 255.',
      );
    }
    return CompBoxLocation(
      zone: match.group(1)!.codeUnitAt(0) - 'A'.codeUnitAt(0),
      rack: rack,
      slot: slot,
    );
  }

  String format() =>
      '${String.fromCharCode('A'.codeUnitAt(0) + zone)}-${rack.toString().padLeft(2, '0')}-${slot.toString().padLeft(2, '0')}';
}

class _VarIntResult {
  const _VarIntResult(this.value, this.nextOffset);

  final int value;
  final int nextOffset;
}

class _AttributeResult {
  const _AttributeResult(this.value, this.nextOffset);

  final Object value;
  final int nextOffset;
}

extension on Iterable<FieldOption> {
  FieldOption? get firstOrNull {
    for (final item in this) {
      return item;
    }
    return null;
  }
}

enum SnapshotErrorCode {
  protocol,
  version,
  crc,
  truncated,
  unknownCategory,
  invalidSecondary,
  invalidValue,
  invalidTolerance,
  invalidAttribute,
  location,
  invalidCount,
  missingRequiredValue,
  attributeTooLong,
  attributesTooLong,
  invalidGrid,
  containerTooLarge,
}

class SnapshotFormatException implements Exception {
  const SnapshotFormatException(this.code, this.message, {this.bytes});

  final SnapshotErrorCode code;
  final String message;
  final int? bytes;

  @override
  String toString() => 'SnapshotFormatException($code): $message';
}

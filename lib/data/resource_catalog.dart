import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';

import 'resource_models.dart';

enum FieldType { text, integer, decimal, enumValue }

enum NumericValueType { resistance, capacitance, inductance, percentage }

enum NfcFieldRole { value, tolerance, secondary, text }

class LocalizedValue {
  const LocalizedValue(this.values);

  final Map<String, String> values;

  String resolve(String languageCode) =>
      values[languageCode] ?? values['en'] ?? values.values.first;
}

class FieldOption {
  const FieldOption({required this.id, required this.label, this.nfcCode});

  final String id;
  final LocalizedValue label;
  final int? nfcCode;
}

class NfcFieldDefinition {
  const NfcFieldDefinition({
    required this.code,
    required this.role,
    required this.dictionary,
  });

  final int code;
  final NfcFieldRole role;
  final List<FieldOption> dictionary;

  FieldOption? dictionaryByCode(int code) {
    for (final entry in dictionary) {
      if (entry.nfcCode == code) {
        return entry;
      }
    }
    return null;
  }

  FieldOption? dictionaryById(String id) {
    for (final entry in dictionary) {
      if (entry.id == id) {
        return entry;
      }
    }
    return null;
  }

  FieldOption? dictionaryByText(String value) =>
      _dictionaryByText(dictionary, value);
}

class FieldDefinition {
  const FieldDefinition({
    required this.id,
    required this.type,
    required this.label,
    required this.required,
    required this.options,
    required this.valueType,
    required this.nfc,
  });

  final String id;
  final FieldType type;
  final LocalizedValue label;
  final bool required;
  final List<FieldOption> options;
  final NumericValueType? valueType;
  final NfcFieldDefinition? nfc;

  FieldOption? optionById(String id) {
    for (final option in options) {
      if (option.id == id) {
        return option;
      }
    }
    return null;
  }
}

class NfcValueDefinition {
  NfcValueDefinition({
    required this.fieldId,
    required this.unit,
    required this.valueType,
    required this.dictionary,
    required this.presetSeries,
    required this.units,
    required this.defaultUnitId,
  });

  final String fieldId;
  final String unit;
  final NumericValueType valueType;
  final List<FieldOption> dictionary;
  final List<PresetSeriesDefinition> presetSeries;
  final List<ValueUnitDefinition> units;
  final String defaultUnitId;

  late final List<ValuePreset> presets = List.unmodifiable([
    for (final series in presetSeries) ...series.expand(),
  ]);

  FieldOption? dictionaryByCode(int code) {
    for (final entry in dictionary) {
      if (entry.nfcCode == code) {
        return entry;
      }
    }
    return null;
  }

  FieldOption? dictionaryById(String id) {
    for (final entry in dictionary) {
      if (entry.id == id) {
        return entry;
      }
    }
    return null;
  }

  FieldOption? dictionaryByText(String value) =>
      _dictionaryByText(dictionary, value);

  ValueUnitDefinition get defaultUnit => unitById(defaultUnitId)!;

  ValueUnitDefinition? unitById(String id) {
    for (final unit in units) {
      if (unit.id == id) {
        return unit;
      }
    }
    return null;
  }

  ValueUnitDefinition preferredUnitFor(num value) {
    if (value == 0) {
      return defaultUnit;
    }
    final ordered = [...units]
      ..sort((left, right) => right.multiplier.compareTo(left.multiplier));
    for (final unit in ordered) {
      if (value.abs() >= unit.multiplier) {
        return unit;
      }
    }
    return ordered.last;
  }

  num? parseInput(String text, String unitId) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    if (RegExp(r'[a-zA-ZΩµ%]').hasMatch(trimmed)) {
      return parseNumericValue(trimmed, valueType);
    }
    final numeric = double.tryParse(trimmed);
    final selectedUnit = unitById(unitId);
    if (numeric == null || selectedUnit == null) {
      return null;
    }
    return _normalizeNumber(numeric * selectedUnit.multiplier);
  }

  String inputValue(num value, String unitId) {
    final selectedUnit = unitById(unitId) ?? defaultUnit;
    return _formatNumeric(value.toDouble() / selectedUnit.multiplier);
  }

  String displayValue(num value, String unitId) {
    final selectedUnit = unitById(unitId) ?? defaultUnit;
    return '${inputValue(value, selectedUnit.id)} ${selectedUnit.symbol}';
  }

  ValuePreset? presetByIndex(int index) {
    for (final preset in presets) {
      if (preset.index == index) {
        return preset;
      }
    }
    return null;
  }

  ValuePreset? presetByValue(num value) {
    for (final preset in presets) {
      if (_numericMatch(preset.value, value)) {
        return preset;
      }
    }
    return null;
  }

  /// Limits UI search results so an expanded resource series never becomes a
  /// large, eagerly-built menu.
  List<ValuePreset> matchingPresets(
    String query, {
    String? unitId,
    int limit = 48,
  }) {
    final normalizedQuery = _normalizeNumericSearch(query);
    final queriedValue = unitId == null
        ? parseNumericValue(query, valueType)
        : parseInput(query, unitId);
    final selectedUnit = unitId == null ? null : unitById(unitId);
    final orderedPresets = selectedUnit == null || query.trim().isNotEmpty
        ? presets
        : [
            for (final preset in presets)
              if (preset.value / selectedUnit.multiplier >= 1 &&
                  preset.value / selectedUnit.multiplier < 1000)
                preset,
            for (final preset in presets)
              if (preset.value / selectedUnit.multiplier < 1 ||
                  preset.value / selectedUnit.multiplier >= 1000)
                preset,
          ];
    final matches = <ValuePreset>[];
    for (final preset in orderedPresets) {
      final unitDisplay = unitId == null
          ? null
          : _normalizeNumericSearch(displayValue(preset.value, unitId));
      if (preset.matchesPrepared(normalizedQuery, queriedValue) ||
          (unitDisplay != null && unitDisplay.contains(normalizedQuery))) {
        matches.add(preset);
        if (matches.length == limit) {
          break;
        }
      }
    }
    return matches;
  }
}

class ValueUnitDefinition {
  const ValueUnitDefinition({
    required this.id,
    required this.symbol,
    required this.multiplier,
    required this.label,
  });

  final String id;
  final String symbol;
  final double multiplier;
  final LocalizedValue label;
}

class PresetSeriesDefinition {
  const PresetSeriesDefinition({
    required this.id,
    required this.label,
    required this.values,
    required this.minExponent,
    required this.maxExponent,
    required this.maximum,
    required this.startIndex,
    required this.valueType,
  });

  final String id;
  final LocalizedValue label;
  final List<num> values;
  final int minExponent;
  final int maxExponent;
  final num maximum;
  final int startIndex;
  final NumericValueType valueType;

  List<ValuePreset> expand() {
    final presets = <ValuePreset>[];
    for (var exponent = minExponent; exponent <= maxExponent; exponent++) {
      final multiplier = math.pow(10, exponent).toDouble();
      for (final significant in values) {
        final value = significant * multiplier;
        if (value <= maximum) {
          presets.add(
            ValuePreset(
              index: startIndex + presets.length,
              seriesId: id,
              seriesLabel: label,
              value: value.toDouble(),
              valueType: valueType,
            ),
          );
        }
      }
    }
    return presets;
  }
}

class ValuePreset {
  ValuePreset({
    required this.index,
    required this.seriesId,
    required this.seriesLabel,
    required this.value,
    required this.valueType,
  });

  final int index;
  final String seriesId;
  final LocalizedValue seriesLabel;
  final double value;
  final NumericValueType valueType;

  late final String _display = formatNumericValue(value, valueType);
  late final String _normalizedDisplay = _normalizeNumericSearch(_display);

  String display([String? languageCode]) => _display;

  bool matches(String query, String languageCode) {
    final normalized = _normalizeNumericSearch(query);
    final queriedValue = parseNumericValue(query, valueType);
    return matchesPrepared(normalized, queriedValue);
  }

  bool matchesPrepared(String normalizedQuery, num? queriedValue) {
    return normalizedQuery.isEmpty ||
        (queriedValue != null && _numericMatch(value, queriedValue)) ||
        _normalizedDisplay.contains(normalizedQuery) ||
        _normalizeNumericSearch(value.toString()).contains(normalizedQuery);
  }
}

bool _numericMatch(num left, num right) =>
    (left.toDouble() - right.toDouble()).abs() <=
    math.max(
      1e-18,
      math.max(left.toDouble().abs(), right.toDouble().abs()) * 0.0000001,
    );

class NfcCategoryDefinition {
  const NfcCategoryDefinition({
    required this.code,
    required this.secondaryFieldId,
    required this.value,
  });

  final int code;
  final String? secondaryFieldId;
  final NfcValueDefinition? value;
}

class CategoryDefinition {
  const CategoryDefinition({
    required this.id,
    required this.name,
    required this.iconPath,
    required this.fieldIds,
    required this.nfc,
  });

  final String id;
  final LocalizedValue name;
  final String iconPath;
  final List<String> fieldIds;
  final NfcCategoryDefinition nfc;
}

class ResourceCatalog {
  const ResourceCatalog({required this.categories, required this.fields});

  static const assetPath = 'assets/resource/config/resources.json';

  final List<CategoryDefinition> categories;
  final Map<String, FieldDefinition> fields;

  static Future<ResourceCatalog> loadFromAssets() async {
    return ResourceCatalog.fromJsonString(
      await rootBundle.loadString(assetPath),
    );
  }

  factory ResourceCatalog.fromJsonString(String resourcesJson) {
    final Object? decoded;
    try {
      decoded = jsonDecode(resourcesJson);
    } on FormatException catch (error) {
      throw FormatException(
        'resources.json is not valid JSON: ${error.message}',
      );
    }
    if (decoded is! Map) {
      throw const FormatException('resources.json must be an object.');
    }
    try {
      return ResourceCatalog.fromPackage(
        ResourcePackage.fromJson(Map<String, dynamic>.from(decoded)),
      );
    } on FormatException {
      rethrow;
    } catch (error) {
      throw FormatException('resources.json has an invalid structure: $error');
    }
  }

  factory ResourceCatalog.fromPackage(ResourcePackage resourcePackage) {
    final fields = <String, FieldDefinition>{};
    for (var index = 0; index < resourcePackage.fields.length; index++) {
      final source = resourcePackage.fields[index];
      final path = 'fields[$index]';
      final field = _fieldDefinition(
        source,
        resourcePackage.translations,
        path,
      );
      if (fields.containsKey(field.id)) {
        throw FormatException('$path.id duplicates field id ${field.id}.');
      }
      fields[field.id] = field;
    }
    if (fields.isEmpty) {
      throw const FormatException('resources.json.fields must not be empty.');
    }

    final categories = <CategoryDefinition>[];
    final categoryIds = <String>{};
    final categoryCodes = <int>{};
    for (var index = 0; index < resourcePackage.categories.length; index++) {
      final source = resourcePackage.categories[index];
      final path = 'categories[$index]';
      final category = _categoryDefinition(
        source,
        resourcePackage.translations,
        path,
      );
      if (!categoryIds.add(category.id)) {
        throw FormatException(
          '$path.id duplicates category id ${category.id}.',
        );
      }
      if (!categoryCodes.add(category.nfc.code)) {
        throw FormatException(
          '$path.nfc.code duplicates NFC category code ${category.nfc.code}.',
        );
      }
      categories.add(category);
    }
    if (categories.isEmpty) {
      throw const FormatException(
        'resources.json.categories must not be empty.',
      );
    }

    _validateCatalog(categories, fields);
    return ResourceCatalog(categories: categories, fields: fields);
  }

  CategoryDefinition categoryById(String id) {
    for (final category in categories) {
      if (category.id == id) {
        return category;
      }
    }
    throw FormatException('Unknown category id: $id.');
  }

  CategoryDefinition categoryByNfcCode(int code) {
    for (final category in categories) {
      if (category.nfc.code == code) {
        return category;
      }
    }
    throw FormatException('Unknown NFC category code: $code.');
  }

  FieldDefinition fieldByNfcCode(int code) {
    for (final field in fields.values) {
      if (field.nfc?.code == code) {
        return field;
      }
    }
    throw FormatException('Unknown NFC field code: $code.');
  }

  List<FieldDefinition> fieldsFor(CategoryDefinition category) => [
    for (final id in category.fieldIds) fields[id]!,
  ];

  String displayValue({
    required CategoryDefinition category,
    required FieldDefinition field,
    required Object? value,
    required String languageCode,
  }) {
    final categoryValue = category.nfc.value;
    if (categoryValue?.fieldId == field.id) {
      if (value is num) {
        return formatNumericValue(value, categoryValue!.valueType);
      }
      return value?.toString() ?? '';
    }
    if (field.valueType != null && value is num) {
      return formatNumericValue(value, field.valueType!);
    }
    if (value is! String && value is! int) {
      return value?.toString() ?? '';
    }
    if (value is int) {
      return field.nfc?.dictionaryByCode(value)?.label.resolve(languageCode) ??
          value.toString();
    }
    final text = value as String;
    return field.nfc?.dictionaryById(text)?.label.resolve(languageCode) ?? text;
  }

  Object? canonicalValue({
    required CategoryDefinition category,
    required FieldDefinition field,
    required String text,
  }) {
    final categoryValue = category.nfc.value;
    if (categoryValue?.fieldId == field.id) {
      return parseNumericValue(text, categoryValue!.valueType);
    }
    if (field.valueType != null) {
      return parseNumericValue(text, field.valueType!);
    }
    return field.nfc?.dictionaryByText(text)?.nfcCode ?? text.trim();
  }
}

num? parseNumericValue(String text, NumericValueType type) {
  var normalized = text.trim().replaceAll(' ', '');
  if (type == NumericValueType.percentage) {
    normalized = normalized.replaceAll('\u00b1', '').replaceAll('%', '');
    return _normalizeNumber(double.tryParse(normalized));
  }
  final unit = switch (type) {
    NumericValueType.resistance => '(?:ohm|\\u03a9|r)?',
    NumericValueType.capacitance => 'f?',
    NumericValueType.inductance => 'h?',
    NumericValueType.percentage => '',
  };
  final match = RegExp(
    '^([0-9]+(?:\\.[0-9]+)?|\\.[0-9]+)(p|n|u|\\u00b5|m|k|K|M|meg)?$unit\$',
  ).firstMatch(normalized);
  if (match == null) {
    return null;
  }
  final base = double.parse(match.group(1)!);
  final prefix = match.group(2) ?? '';
  final multiplier = switch (prefix) {
    'p' => 1e-12,
    'n' => 1e-9,
    'u' || '\u00b5' => 1e-6,
    'm' => 1e-3,
    'k' || 'K' => 1e3,
    'M' || 'meg' => 1e6,
    _ => 1.0,
  };
  return _normalizeNumber(base * multiplier);
}

String formatNumericValue(num value, NumericValueType type) {
  if (type == NumericValueType.percentage) {
    return '${_formatNumeric(value.toDouble())}%';
  }
  final unit = switch (type) {
    NumericValueType.resistance => '\u03a9',
    NumericValueType.capacitance => 'F',
    NumericValueType.inductance => 'H',
    NumericValueType.percentage => '',
  };
  final prefixes = switch (type) {
    NumericValueType.resistance => const [
      (1e6, 'M'),
      (1e3, 'k'),
      (1.0, ''),
      (1e-3, 'm'),
    ],
    NumericValueType.capacitance => const [
      (1.0, ''),
      (1e-3, 'm'),
      (1e-6, '\u00b5'),
      (1e-9, 'n'),
      (1e-12, 'p'),
    ],
    NumericValueType.inductance => const [
      (1.0, ''),
      (1e-3, 'm'),
      (1e-6, '\u00b5'),
      (1e-9, 'n'),
    ],
    NumericValueType.percentage => const <(double, String)>[],
  };
  final numeric = value.toDouble();
  for (final prefix in prefixes) {
    if (numeric >= prefix.$1 || prefix.$1 == prefixes.last.$1) {
      return '${_formatNumeric(numeric / prefix.$1)} ${prefix.$2}$unit';
    }
  }
  return '$numeric $unit';
}

num? _normalizeNumber(double? value) {
  if (value == null || !value.isFinite || value < 0) {
    return null;
  }
  return value == value.roundToDouble() ? value.toInt() : value;
}

String _formatNumeric(double value) {
  final text = value.toStringAsFixed(8);
  if (RegExp(r'\.0+$').hasMatch(text)) {
    return text.replaceFirst(RegExp(r'\.0+$'), '');
  }
  return text.replaceFirstMapped(
    RegExp(r'(\.\d*?)0+$'),
    (match) => match.group(1)!,
  );
}

String _normalizeNumericSearch(String value) => value
    .toLowerCase()
    .replaceAll('\u03a9', 'ohm')
    .replaceAll(RegExp(r'[^a-z0-9.]'), '');

FieldDefinition _fieldDefinition(
  ResourceField source,
  Map<String, ResourceTranslation> translations,
  String path,
) {
  final id = _requiredString(source.id, '$path.id');
  final options = [
    for (var index = 0; index < source.options.length; index++)
      _dictionaryEntry(
        source.options[index],
        translations,
        '$path.options[$index]',
      ),
  ];
  final type = switch (source.type) {
    ResourceFieldType.text => FieldType.text,
    ResourceFieldType.integer => FieldType.integer,
    ResourceFieldType.decimal => FieldType.decimal,
    ResourceFieldType.enumValue => FieldType.enumValue,
  };
  if (type == FieldType.enumValue && options.isEmpty) {
    throw FormatException(
      '$path.options must not be empty for enum field $id.',
    );
  }
  if (type != FieldType.enumValue && options.isNotEmpty) {
    throw FormatException('$path.options is only supported by enum fields.');
  }
  return FieldDefinition(
    id: id,
    type: type,
    label: _localized(source.label, translations, '$path.label'),
    required: source.required,
    options: options,
    valueType: source.valueType == null
        ? null
        : _numericValueType(source.valueType!),
    nfc: source.nfc == null
        ? null
        : _fieldNfc(source.nfc!, translations, '$path.nfc'),
  );
}

CategoryDefinition _categoryDefinition(
  ResourceCategory source,
  Map<String, ResourceTranslation> translations,
  String path,
) {
  final id = _requiredString(source.id, '$path.id');
  final fieldIds = <String>[
    for (var index = 0; index < source.fieldIds.length; index++)
      _requiredString(source.fieldIds[index], '$path.fieldIds[$index]'),
  ];
  if (fieldIds.isEmpty || fieldIds.toSet().length != fieldIds.length) {
    throw FormatException(
      '$path.fieldIds must be a non-empty list of unique ids.',
    );
  }
  final nfcValue = source.nfc.value;
  return CategoryDefinition(
    id: id,
    name: _localized(source.name, translations, '$path.name'),
    iconPath: _requiredString(source.icon, '$path.icon'),
    fieldIds: fieldIds,
    nfc: NfcCategoryDefinition(
      code: _nfcCode(source.nfc.code, '$path.nfc.code'),
      secondaryFieldId: source.nfc.secondaryFieldId == null
          ? null
          : _requiredString(
              source.nfc.secondaryFieldId!,
              '$path.nfc.secondaryFieldId',
            ),
      value: nfcValue == null
          ? null
          : NfcValueDefinition(
              fieldId: _requiredString(
                nfcValue.fieldId,
                '$path.nfc.value.fieldId',
              ),
              unit: _requiredString(nfcValue.unit, '$path.nfc.value.unit'),
              valueType: _numericValueType(nfcValue.valueType),
              dictionary: [
                for (var index = 0; index < nfcValue.dictionary.length; index++)
                  _dictionaryEntry(
                    nfcValue.dictionary[index],
                    translations,
                    '$path.nfc.value.dictionary[$index]',
                  ),
              ],
              presetSeries: _presetSeries(
                nfcValue.presets,
                translations,
                '$path.nfc.value.presets',
                _numericValueType(nfcValue.valueType),
              ),
              units: [
                for (var index = 0; index < nfcValue.units.length; index++)
                  ValueUnitDefinition(
                    id: _requiredString(
                      nfcValue.units[index].id,
                      '$path.nfc.value.units[$index].id',
                    ),
                    symbol: _requiredString(
                      nfcValue.units[index].symbol,
                      '$path.nfc.value.units[$index].symbol',
                    ),
                    multiplier: nfcValue.units[index].multiplier.toDouble(),
                    label: _localized(
                      nfcValue.units[index].label,
                      translations,
                      '$path.nfc.value.units[$index].label',
                    ),
                  ),
              ],
              defaultUnitId: _requiredString(
                nfcValue.defaultUnitId ?? '',
                '$path.nfc.value.defaultUnitId',
              ),
            ),
    ),
  );
}

List<PresetSeriesDefinition> _presetSeries(
  List<ResourcePresetSeries> source,
  Map<String, ResourceTranslation> translations,
  String path,
  NumericValueType valueType,
) {
  var nextIndex = 1;
  final result = <PresetSeriesDefinition>[];
  for (var index = 0; index < source.length; index++) {
    final item = source[index];
    final series = PresetSeriesDefinition(
      id: _requiredString(item.id, '$path[$index].id'),
      label: _localized(item.label, translations, '$path[$index].label'),
      values: List.unmodifiable(item.values),
      minExponent: item.minExponent,
      maxExponent: item.maxExponent,
      maximum: item.maximum,
      startIndex: nextIndex,
      valueType: valueType,
    );
    result.add(series);
    nextIndex += series.expand().length;
  }
  return List.unmodifiable(result);
}

NumericValueType _numericValueType(ResourceValueType valueType) =>
    switch (valueType) {
      ResourceValueType.resistance => NumericValueType.resistance,
      ResourceValueType.capacitance => NumericValueType.capacitance,
      ResourceValueType.inductance => NumericValueType.inductance,
      ResourceValueType.percentage => NumericValueType.percentage,
    };

NfcFieldDefinition _fieldNfc(
  ResourceFieldNfc source,
  Map<String, ResourceTranslation> translations,
  String path,
) {
  return NfcFieldDefinition(
    code: _nfcCode(source.code, '$path.code'),
    role: switch (source.role) {
      ResourceNfcFieldRole.value => NfcFieldRole.value,
      ResourceNfcFieldRole.tolerance => NfcFieldRole.tolerance,
      ResourceNfcFieldRole.secondary => NfcFieldRole.secondary,
      ResourceNfcFieldRole.text => NfcFieldRole.text,
    },
    dictionary: [
      for (var index = 0; index < source.dictionary.length; index++)
        _dictionaryEntry(
          source.dictionary[index],
          translations,
          '$path.dictionary[$index]',
        ),
    ],
  );
}

FieldOption _dictionaryEntry(
  ResourceDictionaryEntry source,
  Map<String, ResourceTranslation> translations,
  String path,
) {
  return FieldOption(
    id: _requiredString(source.id, '$path.id'),
    label: _localized(source.label, translations, '$path.label'),
    nfcCode: source.code == null ? null : _nfcCode(source.code!, '$path.code'),
  );
}

LocalizedValue _localized(
  I18nReference reference,
  Map<String, ResourceTranslation> translations,
  String path,
) {
  final translation = translations[reference.key];
  if (translation == null) {
    throw FormatException(
      '$path references missing translation ${reference.key}.',
    );
  }
  final zh = translation.zh;
  if (zh == null || zh.isEmpty) {
    throw FormatException('$path translation ${reference.key}.zh is missing.');
  }
  final en = translation.en;
  if (en == null || en.isEmpty) {
    throw FormatException('$path translation ${reference.key}.en is missing.');
  }
  return LocalizedValue({'zh': zh, 'en': en});
}

void _validateCatalog(
  List<CategoryDefinition> categories,
  Map<String, FieldDefinition> fields,
) {
  final nfcFieldCodes = <int>{};
  for (final field in fields.values) {
    final nfc = field.nfc;
    if (nfc == null) {
      continue;
    }
    if (!nfcFieldCodes.add(nfc.code)) {
      throw FormatException('NFC field code ${nfc.code} must be unique.');
    }
    _validateDictionary(nfc.dictionary, 'field ${field.id}.nfc.dictionary');
    if (nfc.role == NfcFieldRole.tolerance) {
      final codes = nfc.dictionary.map((entry) => entry.nfcCode).toSet();
      if (codes.length != 10 ||
          !codes.containsAll(
            Iterable<int>.generate(10, (index) => index + 1),
          )) {
        throw FormatException(
          'Tolerance field ${field.id} must use dictionary codes 1 through 10.',
        );
      }
    }
  }
  for (final category in categories) {
    for (final fieldId in category.fieldIds) {
      final field = fields[fieldId];
      if (field == null) {
        throw FormatException(
          'Category ${category.id} references missing field $fieldId.',
        );
      }
      if (fieldId != 'quantity' && field.nfc == null) {
        throw FormatException(
          'NFC category ${category.id} field $fieldId requires nfc metadata.',
        );
      }
    }
    final secondaryId = category.nfc.secondaryFieldId;
    if (secondaryId != null && !category.fieldIds.contains(secondaryId)) {
      throw FormatException(
        'Category ${category.id} secondary field $secondaryId is not present.',
      );
    }
    if (secondaryId != null &&
        fields[secondaryId]?.nfc?.role != NfcFieldRole.secondary) {
      throw FormatException(
        'Category ${category.id} secondary field $secondaryId has the wrong role.',
      );
    }
    final value = category.nfc.value;
    if (value != null) {
      if (!category.fieldIds.contains(value.fieldId) ||
          fields[value.fieldId]?.nfc?.role != NfcFieldRole.value) {
        throw FormatException(
          'Category ${category.id} has an invalid value field.',
        );
      }
      if (value.dictionary.isEmpty) {
        throw FormatException(
          'Category ${category.id} NFC value dictionary is empty.',
        );
      }
      _validateDictionary(
        value.dictionary,
        'category ${category.id}.nfc.value.dictionary',
      );
    }
  }
}

void _validateDictionary(List<FieldOption> dictionary, String context) {
  final codes = <int>{};
  final ids = <String>{};
  for (final entry in dictionary) {
    final code = entry.nfcCode;
    if (code == null) {
      throw FormatException('$context entry ${entry.id} needs a code.');
    }
    if (!codes.add(code) || !ids.add(entry.id)) {
      throw FormatException('$context codes and ids must be unique.');
    }
  }
}

FieldOption? _dictionaryByText(List<FieldOption> dictionary, String value) {
  final normalized = _normalize(value);
  for (final entry in dictionary) {
    if (_normalize(entry.id) == normalized ||
        entry.label.values.values.any(
          (label) => _normalize(label) == normalized,
        )) {
      return entry;
    }
  }
  return null;
}

String _requiredString(String value, String context) {
  if (value.isEmpty) {
    throw FormatException('$context must be a non-empty string.');
  }
  return value;
}

int _nfcCode(int value, String context) {
  if (value < 1 || value > 255) {
    throw FormatException('$context must be an integer from 1 through 255.');
  }
  return value;
}

String _normalize(String value) => value.trim().toLowerCase();

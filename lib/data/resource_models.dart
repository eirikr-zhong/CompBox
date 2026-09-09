import 'package:json_annotation/json_annotation.dart';

part 'resource_models.g.dart';

class I18nReference {
  const I18nReference(this.key);

  final String key;
}

class I18nReferenceConverter implements JsonConverter<I18nReference, String> {
  const I18nReferenceConverter();

  static const _prefix = '@i18n.';

  @override
  I18nReference fromJson(String json) {
    if (!json.startsWith(_prefix) || json.length == _prefix.length) {
      throw FormatException(
        'Expected an i18n reference beginning with $_prefix, got "$json".',
      );
    }
    return I18nReference(json.substring(_prefix.length));
  }

  @override
  String toJson(I18nReference object) => '$_prefix${object.key}';
}

enum ResourceFieldType {
  text,
  integer,
  decimal,
  @JsonValue('enum')
  enumValue,
}

enum ResourceNfcFieldRole { value, tolerance, secondary, text }

enum ResourceValueType { resistance, capacitance, inductance, percentage }

@JsonSerializable(explicitToJson: true)
class ResourcePackage {
  const ResourcePackage({
    required this.categories,
    required this.fields,
    required this.translations,
  });

  @JsonKey(required: true, disallowNullValue: true)
  final List<ResourceCategory> categories;
  @JsonKey(required: true, disallowNullValue: true)
  final List<ResourceField> fields;
  @JsonKey(required: true, disallowNullValue: true)
  final Map<String, ResourceTranslation> translations;

  factory ResourcePackage.fromJson(Map<String, dynamic> json) =>
      _$ResourcePackageFromJson(json);

  Map<String, dynamic> toJson() => _$ResourcePackageToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ResourceCategory {
  const ResourceCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.fieldIds,
    required this.nfc,
  });

  @JsonKey(required: true, disallowNullValue: true)
  final String id;
  @I18nReferenceConverter()
  @JsonKey(required: true, disallowNullValue: true)
  final I18nReference name;
  @JsonKey(required: true, disallowNullValue: true)
  final String icon;
  @JsonKey(required: true, disallowNullValue: true)
  final List<String> fieldIds;
  @JsonKey(required: true, disallowNullValue: true)
  final ResourceCategoryNfc nfc;

  factory ResourceCategory.fromJson(Map<String, dynamic> json) =>
      _$ResourceCategoryFromJson(json);

  Map<String, dynamic> toJson() => _$ResourceCategoryToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ResourceField {
  const ResourceField({
    required this.id,
    required this.type,
    required this.label,
    required this.required,
    required this.options,
    this.valueType,
    this.nfc,
  });

  @JsonKey(required: true, disallowNullValue: true)
  final String id;
  @JsonKey(required: true, disallowNullValue: true)
  final ResourceFieldType type;
  @I18nReferenceConverter()
  @JsonKey(required: true, disallowNullValue: true)
  final I18nReference label;
  @JsonKey(required: true, disallowNullValue: true)
  final bool required;
  @JsonKey(defaultValue: <ResourceDictionaryEntry>[])
  final List<ResourceDictionaryEntry> options;
  final ResourceValueType? valueType;
  final ResourceFieldNfc? nfc;

  factory ResourceField.fromJson(Map<String, dynamic> json) =>
      _$ResourceFieldFromJson(json);

  Map<String, dynamic> toJson() => _$ResourceFieldToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ResourceDictionaryEntry {
  const ResourceDictionaryEntry({
    required this.id,
    required this.label,
    this.code,
  });

  @JsonKey(required: true, disallowNullValue: true)
  final String id;
  @I18nReferenceConverter()
  @JsonKey(required: true, disallowNullValue: true)
  final I18nReference label;
  final int? code;

  factory ResourceDictionaryEntry.fromJson(Map<String, dynamic> json) =>
      _$ResourceDictionaryEntryFromJson(json);

  Map<String, dynamic> toJson() => _$ResourceDictionaryEntryToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ResourceFieldNfc {
  const ResourceFieldNfc({
    required this.code,
    required this.role,
    required this.dictionary,
  });

  @JsonKey(required: true, disallowNullValue: true)
  final int code;
  @JsonKey(required: true, disallowNullValue: true)
  final ResourceNfcFieldRole role;
  @JsonKey(defaultValue: <ResourceDictionaryEntry>[])
  final List<ResourceDictionaryEntry> dictionary;

  factory ResourceFieldNfc.fromJson(Map<String, dynamic> json) =>
      _$ResourceFieldNfcFromJson(json);

  Map<String, dynamic> toJson() => _$ResourceFieldNfcToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ResourceCategoryNfc {
  const ResourceCategoryNfc({
    required this.code,
    this.secondaryFieldId,
    this.value,
  });

  @JsonKey(required: true, disallowNullValue: true)
  final int code;
  final String? secondaryFieldId;
  final ResourceNfcValue? value;

  factory ResourceCategoryNfc.fromJson(Map<String, dynamic> json) =>
      _$ResourceCategoryNfcFromJson(json);

  Map<String, dynamic> toJson() => _$ResourceCategoryNfcToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ResourceNfcValue {
  const ResourceNfcValue({
    required this.fieldId,
    required this.unit,
    required this.valueType,
    required this.dictionary,
    required this.presets,
    required this.units,
    required this.defaultUnitId,
  });

  @JsonKey(required: true, disallowNullValue: true)
  final String fieldId;
  @JsonKey(required: true, disallowNullValue: true)
  final String unit;
  @JsonKey(required: true, disallowNullValue: true)
  final ResourceValueType valueType;
  @JsonKey(required: true, disallowNullValue: true)
  final List<ResourceDictionaryEntry> dictionary;
  @JsonKey(defaultValue: <ResourcePresetSeries>[])
  final List<ResourcePresetSeries> presets;
  @JsonKey(defaultValue: <ResourceValueUnit>[])
  final List<ResourceValueUnit> units;
  final String? defaultUnitId;

  factory ResourceNfcValue.fromJson(Map<String, dynamic> json) =>
      _$ResourceNfcValueFromJson(json);

  Map<String, dynamic> toJson() => _$ResourceNfcValueToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ResourceValueUnit {
  const ResourceValueUnit({
    required this.id,
    required this.symbol,
    required this.multiplier,
    required this.label,
  });

  @JsonKey(required: true, disallowNullValue: true)
  final String id;
  @JsonKey(required: true, disallowNullValue: true)
  final String symbol;
  @JsonKey(required: true, disallowNullValue: true)
  final num multiplier;
  @I18nReferenceConverter()
  @JsonKey(required: true, disallowNullValue: true)
  final I18nReference label;

  factory ResourceValueUnit.fromJson(Map<String, dynamic> json) =>
      _$ResourceValueUnitFromJson(json);

  Map<String, dynamic> toJson() => _$ResourceValueUnitToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ResourcePresetSeries {
  const ResourcePresetSeries({
    required this.id,
    required this.label,
    required this.values,
    required this.minExponent,
    required this.maxExponent,
    required this.maximum,
  });

  @JsonKey(required: true, disallowNullValue: true)
  final String id;
  @I18nReferenceConverter()
  @JsonKey(required: true, disallowNullValue: true)
  final I18nReference label;
  @JsonKey(required: true, disallowNullValue: true)
  final List<num> values;
  @JsonKey(required: true, disallowNullValue: true)
  final int minExponent;
  @JsonKey(required: true, disallowNullValue: true)
  final int maxExponent;
  @JsonKey(required: true, disallowNullValue: true)
  final num maximum;

  factory ResourcePresetSeries.fromJson(Map<String, dynamic> json) =>
      _$ResourcePresetSeriesFromJson(json);

  Map<String, dynamic> toJson() => _$ResourcePresetSeriesToJson(this);
}

@JsonSerializable()
class ResourceTranslation {
  const ResourceTranslation({this.zh, this.en});

  final String? zh;
  final String? en;

  factory ResourceTranslation.fromJson(Map<String, dynamic> json) =>
      _$ResourceTranslationFromJson(json);

  Map<String, dynamic> toJson() => _$ResourceTranslationToJson(this);
}

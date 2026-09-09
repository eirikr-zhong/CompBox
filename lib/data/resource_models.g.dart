// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resource_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ResourcePackage _$ResourcePackageFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['categories', 'fields', 'translations'],
    disallowNullValues: const ['categories', 'fields', 'translations'],
  );
  return ResourcePackage(
    categories: (json['categories'] as List<dynamic>)
        .map((e) => ResourceCategory.fromJson(e as Map<String, dynamic>))
        .toList(),
    fields: (json['fields'] as List<dynamic>)
        .map((e) => ResourceField.fromJson(e as Map<String, dynamic>))
        .toList(),
    translations: (json['translations'] as Map<String, dynamic>).map(
      (k, e) =>
          MapEntry(k, ResourceTranslation.fromJson(e as Map<String, dynamic>)),
    ),
  );
}

Map<String, dynamic> _$ResourcePackageToJson(
  ResourcePackage instance,
) => <String, dynamic>{
  'categories': instance.categories.map((e) => e.toJson()).toList(),
  'fields': instance.fields.map((e) => e.toJson()).toList(),
  'translations': instance.translations.map((k, e) => MapEntry(k, e.toJson())),
};

ResourceCategory _$ResourceCategoryFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['id', 'name', 'icon', 'fieldIds', 'nfc'],
    disallowNullValues: const ['id', 'name', 'icon', 'fieldIds', 'nfc'],
  );
  return ResourceCategory(
    id: json['id'] as String,
    name: const I18nReferenceConverter().fromJson(json['name'] as String),
    icon: json['icon'] as String,
    fieldIds: (json['fieldIds'] as List<dynamic>)
        .map((e) => e as String)
        .toList(),
    nfc: ResourceCategoryNfc.fromJson(json['nfc'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$ResourceCategoryToJson(ResourceCategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': const I18nReferenceConverter().toJson(instance.name),
      'icon': instance.icon,
      'fieldIds': instance.fieldIds,
      'nfc': instance.nfc.toJson(),
    };

ResourceField _$ResourceFieldFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['id', 'type', 'label', 'required'],
    disallowNullValues: const ['id', 'type', 'label', 'required'],
  );
  return ResourceField(
    id: json['id'] as String,
    type: $enumDecode(_$ResourceFieldTypeEnumMap, json['type']),
    label: const I18nReferenceConverter().fromJson(json['label'] as String),
    required: json['required'] as bool,
    options:
        (json['options'] as List<dynamic>?)
            ?.map(
              (e) =>
                  ResourceDictionaryEntry.fromJson(e as Map<String, dynamic>),
            )
            .toList() ??
        [],
    valueType: $enumDecodeNullable(
      _$ResourceValueTypeEnumMap,
      json['valueType'],
    ),
    nfc: json['nfc'] == null
        ? null
        : ResourceFieldNfc.fromJson(json['nfc'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$ResourceFieldToJson(ResourceField instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$ResourceFieldTypeEnumMap[instance.type]!,
      'label': const I18nReferenceConverter().toJson(instance.label),
      'required': instance.required,
      'options': instance.options.map((e) => e.toJson()).toList(),
      'valueType': _$ResourceValueTypeEnumMap[instance.valueType],
      'nfc': instance.nfc?.toJson(),
    };

const _$ResourceFieldTypeEnumMap = {
  ResourceFieldType.text: 'text',
  ResourceFieldType.integer: 'integer',
  ResourceFieldType.decimal: 'decimal',
  ResourceFieldType.enumValue: 'enum',
};

const _$ResourceValueTypeEnumMap = {
  ResourceValueType.resistance: 'resistance',
  ResourceValueType.capacitance: 'capacitance',
  ResourceValueType.inductance: 'inductance',
  ResourceValueType.percentage: 'percentage',
};

ResourceDictionaryEntry _$ResourceDictionaryEntryFromJson(
  Map<String, dynamic> json,
) {
  $checkKeys(
    json,
    requiredKeys: const ['id', 'label'],
    disallowNullValues: const ['id', 'label'],
  );
  return ResourceDictionaryEntry(
    id: json['id'] as String,
    label: const I18nReferenceConverter().fromJson(json['label'] as String),
    code: (json['code'] as num?)?.toInt(),
  );
}

Map<String, dynamic> _$ResourceDictionaryEntryToJson(
  ResourceDictionaryEntry instance,
) => <String, dynamic>{
  'id': instance.id,
  'label': const I18nReferenceConverter().toJson(instance.label),
  'code': instance.code,
};

ResourceFieldNfc _$ResourceFieldNfcFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['code', 'role'],
    disallowNullValues: const ['code', 'role'],
  );
  return ResourceFieldNfc(
    code: (json['code'] as num).toInt(),
    role: $enumDecode(_$ResourceNfcFieldRoleEnumMap, json['role']),
    dictionary:
        (json['dictionary'] as List<dynamic>?)
            ?.map(
              (e) =>
                  ResourceDictionaryEntry.fromJson(e as Map<String, dynamic>),
            )
            .toList() ??
        [],
  );
}

Map<String, dynamic> _$ResourceFieldNfcToJson(ResourceFieldNfc instance) =>
    <String, dynamic>{
      'code': instance.code,
      'role': _$ResourceNfcFieldRoleEnumMap[instance.role]!,
      'dictionary': instance.dictionary.map((e) => e.toJson()).toList(),
    };

const _$ResourceNfcFieldRoleEnumMap = {
  ResourceNfcFieldRole.value: 'value',
  ResourceNfcFieldRole.tolerance: 'tolerance',
  ResourceNfcFieldRole.secondary: 'secondary',
  ResourceNfcFieldRole.text: 'text',
};

ResourceCategoryNfc _$ResourceCategoryNfcFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['code'],
    disallowNullValues: const ['code'],
  );
  return ResourceCategoryNfc(
    code: (json['code'] as num).toInt(),
    secondaryFieldId: json['secondaryFieldId'] as String?,
    value: json['value'] == null
        ? null
        : ResourceNfcValue.fromJson(json['value'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$ResourceCategoryNfcToJson(
  ResourceCategoryNfc instance,
) => <String, dynamic>{
  'code': instance.code,
  'secondaryFieldId': instance.secondaryFieldId,
  'value': instance.value?.toJson(),
};

ResourceNfcValue _$ResourceNfcValueFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['fieldId', 'unit', 'valueType', 'dictionary'],
    disallowNullValues: const ['fieldId', 'unit', 'valueType', 'dictionary'],
  );
  return ResourceNfcValue(
    fieldId: json['fieldId'] as String,
    unit: json['unit'] as String,
    valueType: $enumDecode(_$ResourceValueTypeEnumMap, json['valueType']),
    dictionary: (json['dictionary'] as List<dynamic>)
        .map((e) => ResourceDictionaryEntry.fromJson(e as Map<String, dynamic>))
        .toList(),
    presets:
        (json['presets'] as List<dynamic>?)
            ?.map(
              (e) => ResourcePresetSeries.fromJson(e as Map<String, dynamic>),
            )
            .toList() ??
        [],
    units:
        (json['units'] as List<dynamic>?)
            ?.map((e) => ResourceValueUnit.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    defaultUnitId: json['defaultUnitId'] as String?,
  );
}

Map<String, dynamic> _$ResourceNfcValueToJson(ResourceNfcValue instance) =>
    <String, dynamic>{
      'fieldId': instance.fieldId,
      'unit': instance.unit,
      'valueType': _$ResourceValueTypeEnumMap[instance.valueType]!,
      'dictionary': instance.dictionary.map((e) => e.toJson()).toList(),
      'presets': instance.presets.map((e) => e.toJson()).toList(),
      'units': instance.units.map((e) => e.toJson()).toList(),
      'defaultUnitId': instance.defaultUnitId,
    };

ResourceValueUnit _$ResourceValueUnitFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['id', 'symbol', 'multiplier', 'label'],
    disallowNullValues: const ['id', 'symbol', 'multiplier', 'label'],
  );
  return ResourceValueUnit(
    id: json['id'] as String,
    symbol: json['symbol'] as String,
    multiplier: json['multiplier'] as num,
    label: const I18nReferenceConverter().fromJson(json['label'] as String),
  );
}

Map<String, dynamic> _$ResourceValueUnitToJson(ResourceValueUnit instance) =>
    <String, dynamic>{
      'id': instance.id,
      'symbol': instance.symbol,
      'multiplier': instance.multiplier,
      'label': const I18nReferenceConverter().toJson(instance.label),
    };

ResourcePresetSeries _$ResourcePresetSeriesFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'id',
      'label',
      'values',
      'minExponent',
      'maxExponent',
      'maximum',
    ],
    disallowNullValues: const [
      'id',
      'label',
      'values',
      'minExponent',
      'maxExponent',
      'maximum',
    ],
  );
  return ResourcePresetSeries(
    id: json['id'] as String,
    label: const I18nReferenceConverter().fromJson(json['label'] as String),
    values: (json['values'] as List<dynamic>).map((e) => e as num).toList(),
    minExponent: (json['minExponent'] as num).toInt(),
    maxExponent: (json['maxExponent'] as num).toInt(),
    maximum: json['maximum'] as num,
  );
}

Map<String, dynamic> _$ResourcePresetSeriesToJson(
  ResourcePresetSeries instance,
) => <String, dynamic>{
  'id': instance.id,
  'label': const I18nReferenceConverter().toJson(instance.label),
  'values': instance.values,
  'minExponent': instance.minExponent,
  'maxExponent': instance.maxExponent,
  'maximum': instance.maximum,
};

ResourceTranslation _$ResourceTranslationFromJson(Map<String, dynamic> json) =>
    ResourceTranslation(zh: json['zh'] as String?, en: json['en'] as String?);

Map<String, dynamic> _$ResourceTranslationToJson(
  ResourceTranslation instance,
) => <String, dynamic>{'zh': instance.zh, 'en': instance.en};

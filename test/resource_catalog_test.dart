import 'dart:convert';

import 'package:comp_box/data/resource_catalog.dart';
import 'package:comp_box/data/resource_models.dart';
import 'package:flutter_test/flutter_test.dart';

const _minimalPackage = '''
{
  "categories": [
    {
      "id": "part",
      "name": "@i18n.category.part.name",
      "icon": "icons/part.svg",
      "fieldIds": ["quantity"],
      "nfc": {"code": 1}
    }
  ],
  "fields": [
    {
      "id": "quantity",
      "type": "integer",
      "label": "@i18n.field.quantity.label",
      "required": true
    }
  ],
  "translations": {
    "category.part.name": {"zh": "元件", "en": "Part"},
    "field.quantity.label": {"zh": "数量", "en": "Quantity"}
  }
}
''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('json_serializable deserializes a resource package', () {
    final resourcePackage = ResourcePackage.fromJson(
      Map<String, dynamic>.from(jsonDecode(_minimalPackage) as Map),
    );

    expect(resourcePackage.categories.single.name.key, 'category.part.name');
    expect(resourcePackage.fields.single.type, ResourceFieldType.integer);
    expect(resourcePackage.translations['field.quantity.label']?.zh, '数量');
  });

  test(
    'model decoding rejects missing required values, wrong types, and enums',
    () {
      expect(
        () => ResourceCatalog.fromJsonString(
          _minimalPackage.replaceFirst('"id": "quantity",', ''),
        ),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => ResourceCatalog.fromJsonString(
          _minimalPackage.replaceFirst('"required": true', '"required": "yes"'),
        ),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => ResourceCatalog.fromJsonString(
          _minimalPackage.replaceFirst('"integer"', '"not-a-type"'),
        ),
        throwsA(isA<FormatException>()),
      );
    },
  );

  test('catalog reports i18n reference and language paths', () {
    expect(
      () => ResourceCatalog.fromJsonString(
        _minimalPackage.replaceFirst(
          '@i18n.field.quantity.label',
          '@i18n.field.missing',
        ),
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('fields[0].label'),
        ),
      ),
    );
    expect(
      () => ResourceCatalog.fromJsonString(
        _minimalPackage.replaceFirst(', "en": "Quantity"', ''),
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('fields[0].label translation field.quantity.label.en'),
        ),
      ),
    );
  });

  test('catalog resolves categories, dictionaries, and NFC metadata in both languages', () async {
    final catalog = await ResourceCatalog.loadFromAssets();
    final resistor = catalog.categoryById('resistor');
    final capacitor = catalog.categoryById('capacitor');
    final inductor = catalog.categoryById('inductor');
    final package = catalog.fields['package']!;
    final capacitorType = catalog.fields['capacitorType']!;

    expect(catalog.categories, hasLength(25));
    expect(resistor.name.resolve('zh'), '电阻');
    expect(resistor.name.resolve('en'), 'Resistor');
    expect(package.label.resolve('zh'), '封装');
    expect(package.nfc?.dictionaryByCode(2)?.label.resolve('en'), '0603');
    expect(
      catalog.fields['connectorType']?.label.resolve('en'),
      'Connector type',
    );
    expect(
      catalog.fields['ledColor']?.nfc
          ?.dictionaryById('red')
          ?.label
          .resolve('zh'),
      '红色',
    );
    expect(resistor.nfc.code, 1);
    expect(catalog.categoryById('other').nfc.code, 25);
    expect(resistor.nfc.secondaryFieldId, 'package');
    expect(package.nfc?.code, 3);
    expect(capacitor.fieldIds.first, 'capacitorType');
    expect(capacitorType.optionById('ceramic')?.label.resolve('zh'), '陶瓷电容');
    expect(capacitorType.nfc?.dictionaryByCode(3)?.id, 'tantalum');
    expect(capacitor.nfc.value?.defaultUnitId, 'nanofarad');
    expect(capacitor.nfc.value?.unitById('microfarad')?.symbol, 'µF');
    expect(
      capacitor.nfc.value?.parseInput('100', 'nanofarad'),
      closeTo(0.0000001, 0.000000000001),
    );
    expect(capacitor.nfc.value?.inputValue(0.0000001, 'microfarad'), '0.1');
    expect(
      capacitor.nfc.value?.presetByValue(0.0000001)?.value,
      closeTo(0.0000001, 0.000000000001),
    );
    expect(inductor.nfc.value?.presetByValue(0.000022), isNotNull);
    expect(
      capacitor.nfc.value?.matchingPresets('', unitId: 'nanofarad').first.value,
      closeTo(0.000000001, 0.0000000000001),
    );
    expect(resistor.nfc.value?.dictionaryByCode(4)?.id, '10k');
    final resistorValue = resistor.nfc.value!;
    expect(resistorValue.presetByValue(4990)?.seriesId, 'e96');
    expect(
      resistorValue
          .presetByIndex(resistorValue.presetByValue(4990)!.index)
          ?.value,
      4990,
    );
    expect(
      resistorValue.presets.any((preset) => preset.matches('4.99k', 'en')),
      isTrue,
    );
    expect(resistorValue.matchingPresets('').length, 48);
    expect(resistorValue.matchingPresets('4.99k').single.value, 4990);
  });
}

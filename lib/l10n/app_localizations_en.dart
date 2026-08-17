// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'CompBox';

  @override
  String get homeTitle => 'CompBox';

  @override
  String get searchHint => 'Search components, model, location...';

  @override
  String get scanTooltip => 'Scan code';

  @override
  String get scanInProgress => 'Scanner is under design';

  @override
  String get myComponents => 'My components';

  @override
  String get location => 'Location';

  @override
  String get quantity => 'Qty';

  @override
  String quantityValue(String quantity) {
    return '$quantity pcs';
  }

  @override
  String get home => 'Home';

  @override
  String get profile => 'Profile';

  @override
  String get nfcScan => 'NFC scan';

  @override
  String get nfcPreparing => 'Preparing NFC scan';

  @override
  String get componentDetail => 'Component details';

  @override
  String get inventoryInformation => 'Inventory information';

  @override
  String get specificationInformation => 'Specification';

  @override
  String get manufacturerModel => 'Manufacturer / model';

  @override
  String get currentQuantity => 'Current quantity';

  @override
  String get category => 'Category';

  @override
  String get categoryResistor => 'Resistor';

  @override
  String get categoryCapacitor => 'Capacitor';

  @override
  String get categoryDiode => 'Diode';

  @override
  String get categoryInductor => 'Inductor';

  @override
  String get categoryTimer => 'Integrated circuit';

  @override
  String get categoryConnector => 'Connector';

  @override
  String get categoryLed => 'Light-emitting diode';

  @override
  String get nameResistor => '10 kΩ resistor';

  @override
  String get nameCapacitor => '100 nF capacitor';

  @override
  String get nameDiode => '1N4148 diode';

  @override
  String get nameInductor => '22 µH inductor';

  @override
  String get nameTimer => 'NE555 timer';

  @override
  String get nameConnector => 'USB-C connector';

  @override
  String get nameLed => 'Blue 5 mm LED';

  @override
  String get specResistor => '1/4W · ±1%';

  @override
  String get specCapacitor => '50V · X7R · 0603';

  @override
  String get specDiode => 'Switching diode · SOD-123';

  @override
  String get specInductor => 'Power inductor · 3.0A';

  @override
  String get specTimer => 'SOP-8';

  @override
  String get specConnector => 'Type-C 16P · board mount';

  @override
  String get specLed => 'Through-hole LED';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileMonogram => 'P';

  @override
  String get prototypeAccount => 'CompBox Design Account';

  @override
  String get prototypeOnly => 'Prototype data for design only';

  @override
  String get inventoryOverview => 'Inventory overview';

  @override
  String get componentStat => 'Components';

  @override
  String get stockTotal => 'Total stock';

  @override
  String get locationStat => 'Locations';

  @override
  String get settings => 'Settings';

  @override
  String get preferences => 'Preferences';

  @override
  String get settingsInProgress => 'Settings are under design';
}

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
  String get allCategories => 'All categories';

  @override
  String get emptyInventoryTitle => 'No component records yet';

  @override
  String get emptyInventoryDescription =>
      'Scan an NFC tag to create the first record.';

  @override
  String get noMatchingComponents => 'No matching components';

  @override
  String get noMatchingComponentsDescription =>
      'Adjust the search or category filter.';

  @override
  String get resourceLoadError =>
      'Local resource configuration could not be loaded.';

  @override
  String get location => 'Location';

  @override
  String get quantity => 'Qty';

  @override
  String get inventory => 'Inventory';

  @override
  String quantityValue(String quantity) {
    return '$quantity pcs';
  }

  @override
  String get home => 'Home';

  @override
  String get profile => 'Settings';

  @override
  String get nfcScan => 'NFC scan';

  @override
  String get nfcPreparing => 'Preparing NFC scan';

  @override
  String get nfcTitle => 'NFC';

  @override
  String get nfcScanningTitle => 'NFC scanning';

  @override
  String get nfcScanning => 'Scanning';

  @override
  String get nfcScanInstruction =>
      'Hold the back of your phone near the NFC tag';

  @override
  String get nfcReadyToScan => 'Ready to scan an NFC tag';

  @override
  String get nfcScanTag => 'Scan tag';

  @override
  String get nfcRescan => 'Rescan tag';

  @override
  String get nfcWriteTag => 'Rescan and write tag';

  @override
  String get nfcError => 'NFC operation failed';

  @override
  String get nfcUnavailable => 'This device does not support NFC.';

  @override
  String get nfcDisabled => 'NFC is off. Turn it on in system settings.';

  @override
  String get nfcUnsupportedTag => 'This tag does not support NDEF.';

  @override
  String get nfcReadOnly => 'This NFC tag is read-only and cannot be written.';

  @override
  String get nfcCapacityError =>
      'This tag does not have enough capacity for the snapshot.';

  @override
  String nfcPayloadTooLarge(String bytes, String limit) {
    return 'The snapshot is $bytes bytes and exceeds the conservative tag limit of $limit bytes.';
  }

  @override
  String get nfcUidMismatch =>
      'The rescanned tag is not the tag currently being edited.';

  @override
  String get nfcCrcError =>
      'The tag snapshot checksum failed; its data may be damaged.';

  @override
  String get nfcUnknownProtocol =>
      'The tag does not contain a recognizable CompBox snapshot.';

  @override
  String get nfcUnsupportedVersion =>
      'This tag uses an unsupported CompBox snapshot version.';

  @override
  String get nfcInvalidSnapshot => 'The tag snapshot is invalid.';

  @override
  String get nfcNeedsInitialization =>
      'This tag needs to be initialized before it can be used with CompBox.';

  @override
  String get nfcReinitializeTag =>
      'This tag uses an older CompBox format. Reinitialize it before use.';

  @override
  String get nfcSlotSelectionTitle => 'Choose a compartment';

  @override
  String get nfcFinishEditing => 'Done editing';

  @override
  String get nfcSaveAll => 'Save all compartments';

  @override
  String get nfcClearTag => 'Clear tag';

  @override
  String get nfcClearTagDialogDescription =>
      'Hold the back of your phone near the NFC tag to clear it.';

  @override
  String get nfcClearTagSuccess => 'NFC tag cleared';

  @override
  String get nfcSlotEmpty => 'Empty';

  @override
  String nfcSlotLabel(String index) {
    return 'Compartment $index';
  }

  @override
  String get nfcCustomTextTooLong =>
      'The custom text is too long to write to this tag.';

  @override
  String get nfcReadFailed => 'This NFC tag could not be read. Try again.';

  @override
  String get nfcWriteFailed => 'This NFC tag could not be written. Try again.';

  @override
  String get nfcTagOverridesLocalTitle =>
      'Replace the local record with the tag?';

  @override
  String nfcTagOverridesLocalDescription(String location) {
    return 'The local copy at $location differs from the tag. Confirm to replace the local copy with the tag contents.';
  }

  @override
  String get nfcTagRead => 'NFC tag read';

  @override
  String get nfcRead => 'Read';

  @override
  String get nfcTagReadDescription => 'Tag information is ready to edit';

  @override
  String get componentName => 'Component name';

  @override
  String get componentNameHint => 'Enter component name';

  @override
  String get modelSpecification => 'Model / specification';

  @override
  String get modelSpecificationHint => 'Enter model or specification';

  @override
  String get decreaseQuantity => 'Decrease quantity';

  @override
  String get increaseQuantity => 'Increase quantity';

  @override
  String get save => 'Save';

  @override
  String get nfcSaveDialogTitle => 'Save scanned tag';

  @override
  String get nfcSaveDialogDescription =>
      'Hold the back of your phone near the NFC tag to save.';

  @override
  String get cancel => 'Cancel';

  @override
  String requiredField(String field) {
    return 'Enter $field';
  }

  @override
  String get invalidInteger => 'Enter a whole number';

  @override
  String get invalidNumber => 'Enter a valid number';

  @override
  String get invalidLocation => 'Enter a location like A-01-03 (numbers 1–255)';

  @override
  String get insufficientStock => 'Stock out cannot exceed current stock';

  @override
  String currentQuantityValue(String quantity) {
    return 'Current stock: $quantity';
  }

  @override
  String get recordSaved => 'Record saved';

  @override
  String get overwriteRecordTitle => 'Overwrite existing record?';

  @override
  String overwriteRecordDescription(String location) {
    return '$location already has a record. Confirm to replace it with the complete form data.';
  }

  @override
  String get overwrite => 'Overwrite';

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
  String get profileTitle => 'Settings';

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
  String get initializeTagSection => 'NFC tags';

  @override
  String get initializeTagTitle => 'Initialize NFC tag';

  @override
  String get initializeTagDescription =>
      'Create a 1×N CompBox container on an NFC tag.';

  @override
  String get initializeTagColumns => 'Compartments';

  @override
  String initializeTagLayout(String columns) {
    return '1×$columns';
  }

  @override
  String get initializeTagAction => 'Initialize';

  @override
  String get initializeTagConfirmation =>
      'Initialization clears all existing tag content, including older CompBox records and unrecognized NDEF data.';

  @override
  String get initializeTagFirstScan =>
      'Hold the tag near your phone to check it.';

  @override
  String get initializeTagSecondScan =>
      'Hold the same tag near your phone again to initialize it.';

  @override
  String get initializeTagSuccess => 'NFC tag initialized';

  @override
  String get settings => 'Settings';

  @override
  String get preferences => 'Preferences';

  @override
  String get settingsInProgress => 'Settings are under design';

  @override
  String get exportDatabase => 'Export database';

  @override
  String exportDatabaseSuccess(String count) {
    return 'Exported $count component records';
  }

  @override
  String get exportDatabaseFailed =>
      'The database could not be exported. Try again.';

  @override
  String get importDatabase => 'Import database';

  @override
  String importDatabaseConfirmation(String count) {
    return 'This backup contains $count records. Continuing will replace the current local database and cannot be undone. NFC tag contents will not be changed.';
  }

  @override
  String get confirmImportDatabase => 'Import backup';

  @override
  String importDatabaseSuccess(String count) {
    return 'Imported $count component records';
  }

  @override
  String get invalidBackupFile =>
      'The selected file is not a valid CompBox backup';

  @override
  String get importDatabaseFailed =>
      'The database could not be imported. Try again.';

  @override
  String get clearDatabase => 'Clear database';

  @override
  String get clearDatabaseConfirmation =>
      'This cannot be undone. All locally stored component records will be permanently deleted. NFC tag contents will not be changed.';

  @override
  String get confirmClearDatabase => 'Clear database';

  @override
  String get clearDatabaseSuccess => 'Local database cleared';

  @override
  String get delete => 'Delete';

  @override
  String get recordDeleted => 'Record deleted';
}

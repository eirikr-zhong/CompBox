import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('zh'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'CompBox'**
  String get appTitle;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'CompBox'**
  String get homeTitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search components, model, location...'**
  String get searchHint;

  /// No description provided for @scanTooltip.
  ///
  /// In en, this message translates to:
  /// **'Scan code'**
  String get scanTooltip;

  /// No description provided for @scanInProgress.
  ///
  /// In en, this message translates to:
  /// **'Scanner is under design'**
  String get scanInProgress;

  /// No description provided for @myComponents.
  ///
  /// In en, this message translates to:
  /// **'My components'**
  String get myComponents;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get allCategories;

  /// No description provided for @emptyInventoryTitle.
  ///
  /// In en, this message translates to:
  /// **'No component records yet'**
  String get emptyInventoryTitle;

  /// No description provided for @emptyInventoryDescription.
  ///
  /// In en, this message translates to:
  /// **'Scan an NFC tag to create the first record.'**
  String get emptyInventoryDescription;

  /// No description provided for @noMatchingComponents.
  ///
  /// In en, this message translates to:
  /// **'No matching components'**
  String get noMatchingComponents;

  /// No description provided for @noMatchingComponentsDescription.
  ///
  /// In en, this message translates to:
  /// **'Adjust the search or category filter.'**
  String get noMatchingComponentsDescription;

  /// No description provided for @resourceLoadError.
  ///
  /// In en, this message translates to:
  /// **'Local resource configuration could not be loaded.'**
  String get resourceLoadError;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get quantity;

  /// No description provided for @inventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventory;

  /// No description provided for @quantityValue.
  ///
  /// In en, this message translates to:
  /// **'{quantity} pcs'**
  String quantityValue(String quantity);

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get profile;

  /// No description provided for @nfcScan.
  ///
  /// In en, this message translates to:
  /// **'NFC scan'**
  String get nfcScan;

  /// No description provided for @nfcPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing NFC scan'**
  String get nfcPreparing;

  /// No description provided for @nfcTitle.
  ///
  /// In en, this message translates to:
  /// **'NFC'**
  String get nfcTitle;

  /// No description provided for @nfcScanningTitle.
  ///
  /// In en, this message translates to:
  /// **'NFC scanning'**
  String get nfcScanningTitle;

  /// No description provided for @nfcScanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning'**
  String get nfcScanning;

  /// No description provided for @nfcScanInstruction.
  ///
  /// In en, this message translates to:
  /// **'Hold the back of your phone near the NFC tag'**
  String get nfcScanInstruction;

  /// No description provided for @nfcReadyToScan.
  ///
  /// In en, this message translates to:
  /// **'Ready to scan an NFC tag'**
  String get nfcReadyToScan;

  /// No description provided for @nfcScanTag.
  ///
  /// In en, this message translates to:
  /// **'Scan tag'**
  String get nfcScanTag;

  /// No description provided for @nfcRescan.
  ///
  /// In en, this message translates to:
  /// **'Rescan tag'**
  String get nfcRescan;

  /// No description provided for @nfcWriteTag.
  ///
  /// In en, this message translates to:
  /// **'Rescan and write tag'**
  String get nfcWriteTag;

  /// No description provided for @nfcError.
  ///
  /// In en, this message translates to:
  /// **'NFC operation failed'**
  String get nfcError;

  /// No description provided for @nfcUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This device does not support NFC.'**
  String get nfcUnavailable;

  /// No description provided for @nfcDisabled.
  ///
  /// In en, this message translates to:
  /// **'NFC is off. Turn it on in system settings.'**
  String get nfcDisabled;

  /// No description provided for @nfcUnsupportedTag.
  ///
  /// In en, this message translates to:
  /// **'This tag does not support NDEF.'**
  String get nfcUnsupportedTag;

  /// No description provided for @nfcReadOnly.
  ///
  /// In en, this message translates to:
  /// **'This NFC tag is read-only and cannot be written.'**
  String get nfcReadOnly;

  /// No description provided for @nfcCapacityError.
  ///
  /// In en, this message translates to:
  /// **'This tag does not have enough capacity for the snapshot.'**
  String get nfcCapacityError;

  /// No description provided for @nfcPayloadTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The snapshot is {bytes} bytes and exceeds the conservative tag limit of {limit} bytes.'**
  String nfcPayloadTooLarge(String bytes, String limit);

  /// No description provided for @nfcUidMismatch.
  ///
  /// In en, this message translates to:
  /// **'The rescanned tag is not the tag currently being edited.'**
  String get nfcUidMismatch;

  /// No description provided for @nfcCrcError.
  ///
  /// In en, this message translates to:
  /// **'The tag snapshot checksum failed; its data may be damaged.'**
  String get nfcCrcError;

  /// No description provided for @nfcUnknownProtocol.
  ///
  /// In en, this message translates to:
  /// **'The tag does not contain a recognizable CompBox snapshot.'**
  String get nfcUnknownProtocol;

  /// No description provided for @nfcUnsupportedVersion.
  ///
  /// In en, this message translates to:
  /// **'This tag uses an unsupported CompBox snapshot version.'**
  String get nfcUnsupportedVersion;

  /// No description provided for @nfcInvalidSnapshot.
  ///
  /// In en, this message translates to:
  /// **'The tag snapshot is invalid.'**
  String get nfcInvalidSnapshot;

  /// No description provided for @nfcNeedsInitialization.
  ///
  /// In en, this message translates to:
  /// **'This tag needs to be initialized before it can be used with CompBox.'**
  String get nfcNeedsInitialization;

  /// No description provided for @nfcReinitializeTag.
  ///
  /// In en, this message translates to:
  /// **'This tag uses an older CompBox format. Reinitialize it before use.'**
  String get nfcReinitializeTag;

  /// No description provided for @nfcSlotSelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a compartment'**
  String get nfcSlotSelectionTitle;

  /// No description provided for @nfcFinishEditing.
  ///
  /// In en, this message translates to:
  /// **'Done editing'**
  String get nfcFinishEditing;

  /// No description provided for @nfcSaveAll.
  ///
  /// In en, this message translates to:
  /// **'Save all compartments'**
  String get nfcSaveAll;

  /// No description provided for @nfcClearTag.
  ///
  /// In en, this message translates to:
  /// **'Clear tag'**
  String get nfcClearTag;

  /// No description provided for @nfcClearTagDialogDescription.
  ///
  /// In en, this message translates to:
  /// **'Hold the back of your phone near the NFC tag to clear it.'**
  String get nfcClearTagDialogDescription;

  /// No description provided for @nfcClearTagSuccess.
  ///
  /// In en, this message translates to:
  /// **'NFC tag cleared'**
  String get nfcClearTagSuccess;

  /// No description provided for @nfcSlotEmpty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get nfcSlotEmpty;

  /// No description provided for @nfcSlotLabel.
  ///
  /// In en, this message translates to:
  /// **'Compartment {index}'**
  String nfcSlotLabel(String index);

  /// No description provided for @nfcCustomTextTooLong.
  ///
  /// In en, this message translates to:
  /// **'The custom text is too long to write to this tag.'**
  String get nfcCustomTextTooLong;

  /// No description provided for @nfcReadFailed.
  ///
  /// In en, this message translates to:
  /// **'This NFC tag could not be read. Try again.'**
  String get nfcReadFailed;

  /// No description provided for @nfcWriteFailed.
  ///
  /// In en, this message translates to:
  /// **'This NFC tag could not be written. Try again.'**
  String get nfcWriteFailed;

  /// No description provided for @nfcTagOverridesLocalTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace the local record with the tag?'**
  String get nfcTagOverridesLocalTitle;

  /// No description provided for @nfcTagOverridesLocalDescription.
  ///
  /// In en, this message translates to:
  /// **'The local copy at {location} differs from the tag. Confirm to replace the local copy with the tag contents.'**
  String nfcTagOverridesLocalDescription(String location);

  /// No description provided for @nfcTagRead.
  ///
  /// In en, this message translates to:
  /// **'NFC tag read'**
  String get nfcTagRead;

  /// No description provided for @nfcRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get nfcRead;

  /// No description provided for @nfcTagReadDescription.
  ///
  /// In en, this message translates to:
  /// **'Tag information is ready to edit'**
  String get nfcTagReadDescription;

  /// No description provided for @componentName.
  ///
  /// In en, this message translates to:
  /// **'Component name'**
  String get componentName;

  /// No description provided for @componentNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter component name'**
  String get componentNameHint;

  /// No description provided for @modelSpecification.
  ///
  /// In en, this message translates to:
  /// **'Model / specification'**
  String get modelSpecification;

  /// No description provided for @modelSpecificationHint.
  ///
  /// In en, this message translates to:
  /// **'Enter model or specification'**
  String get modelSpecificationHint;

  /// No description provided for @decreaseQuantity.
  ///
  /// In en, this message translates to:
  /// **'Decrease quantity'**
  String get decreaseQuantity;

  /// No description provided for @increaseQuantity.
  ///
  /// In en, this message translates to:
  /// **'Increase quantity'**
  String get increaseQuantity;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @nfcSaveDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Save scanned tag'**
  String get nfcSaveDialogTitle;

  /// No description provided for @nfcSaveDialogDescription.
  ///
  /// In en, this message translates to:
  /// **'Hold the back of your phone near the NFC tag to save.'**
  String get nfcSaveDialogDescription;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Enter {field}'**
  String requiredField(String field);

  /// No description provided for @invalidInteger.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number'**
  String get invalidInteger;

  /// No description provided for @invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get invalidNumber;

  /// No description provided for @invalidLocation.
  ///
  /// In en, this message translates to:
  /// **'Enter a location like A-01-03 (numbers 1–255)'**
  String get invalidLocation;

  /// No description provided for @insufficientStock.
  ///
  /// In en, this message translates to:
  /// **'Stock out cannot exceed current stock'**
  String get insufficientStock;

  /// No description provided for @currentQuantityValue.
  ///
  /// In en, this message translates to:
  /// **'Current stock: {quantity}'**
  String currentQuantityValue(String quantity);

  /// No description provided for @recordSaved.
  ///
  /// In en, this message translates to:
  /// **'Record saved'**
  String get recordSaved;

  /// No description provided for @overwriteRecordTitle.
  ///
  /// In en, this message translates to:
  /// **'Overwrite existing record?'**
  String get overwriteRecordTitle;

  /// No description provided for @overwriteRecordDescription.
  ///
  /// In en, this message translates to:
  /// **'{location} already has a record. Confirm to replace it with the complete form data.'**
  String overwriteRecordDescription(String location);

  /// No description provided for @overwrite.
  ///
  /// In en, this message translates to:
  /// **'Overwrite'**
  String get overwrite;

  /// No description provided for @componentDetail.
  ///
  /// In en, this message translates to:
  /// **'Component details'**
  String get componentDetail;

  /// No description provided for @inventoryInformation.
  ///
  /// In en, this message translates to:
  /// **'Inventory information'**
  String get inventoryInformation;

  /// No description provided for @specificationInformation.
  ///
  /// In en, this message translates to:
  /// **'Specification'**
  String get specificationInformation;

  /// No description provided for @manufacturerModel.
  ///
  /// In en, this message translates to:
  /// **'Manufacturer / model'**
  String get manufacturerModel;

  /// No description provided for @currentQuantity.
  ///
  /// In en, this message translates to:
  /// **'Current quantity'**
  String get currentQuantity;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @categoryResistor.
  ///
  /// In en, this message translates to:
  /// **'Resistor'**
  String get categoryResistor;

  /// No description provided for @categoryCapacitor.
  ///
  /// In en, this message translates to:
  /// **'Capacitor'**
  String get categoryCapacitor;

  /// No description provided for @categoryDiode.
  ///
  /// In en, this message translates to:
  /// **'Diode'**
  String get categoryDiode;

  /// No description provided for @categoryInductor.
  ///
  /// In en, this message translates to:
  /// **'Inductor'**
  String get categoryInductor;

  /// No description provided for @categoryTimer.
  ///
  /// In en, this message translates to:
  /// **'Integrated circuit'**
  String get categoryTimer;

  /// No description provided for @categoryConnector.
  ///
  /// In en, this message translates to:
  /// **'Connector'**
  String get categoryConnector;

  /// No description provided for @categoryLed.
  ///
  /// In en, this message translates to:
  /// **'Light-emitting diode'**
  String get categoryLed;

  /// No description provided for @nameResistor.
  ///
  /// In en, this message translates to:
  /// **'10 kΩ resistor'**
  String get nameResistor;

  /// No description provided for @nameCapacitor.
  ///
  /// In en, this message translates to:
  /// **'100 nF capacitor'**
  String get nameCapacitor;

  /// No description provided for @nameDiode.
  ///
  /// In en, this message translates to:
  /// **'1N4148 diode'**
  String get nameDiode;

  /// No description provided for @nameInductor.
  ///
  /// In en, this message translates to:
  /// **'22 µH inductor'**
  String get nameInductor;

  /// No description provided for @nameTimer.
  ///
  /// In en, this message translates to:
  /// **'NE555 timer'**
  String get nameTimer;

  /// No description provided for @nameConnector.
  ///
  /// In en, this message translates to:
  /// **'USB-C connector'**
  String get nameConnector;

  /// No description provided for @nameLed.
  ///
  /// In en, this message translates to:
  /// **'Blue 5 mm LED'**
  String get nameLed;

  /// No description provided for @specResistor.
  ///
  /// In en, this message translates to:
  /// **'1/4W · ±1%'**
  String get specResistor;

  /// No description provided for @specCapacitor.
  ///
  /// In en, this message translates to:
  /// **'50V · X7R · 0603'**
  String get specCapacitor;

  /// No description provided for @specDiode.
  ///
  /// In en, this message translates to:
  /// **'Switching diode · SOD-123'**
  String get specDiode;

  /// No description provided for @specInductor.
  ///
  /// In en, this message translates to:
  /// **'Power inductor · 3.0A'**
  String get specInductor;

  /// No description provided for @specTimer.
  ///
  /// In en, this message translates to:
  /// **'SOP-8'**
  String get specTimer;

  /// No description provided for @specConnector.
  ///
  /// In en, this message translates to:
  /// **'Type-C 16P · board mount'**
  String get specConnector;

  /// No description provided for @specLed.
  ///
  /// In en, this message translates to:
  /// **'Through-hole LED'**
  String get specLed;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get profileTitle;

  /// No description provided for @profileMonogram.
  ///
  /// In en, this message translates to:
  /// **'P'**
  String get profileMonogram;

  /// No description provided for @prototypeAccount.
  ///
  /// In en, this message translates to:
  /// **'CompBox Design Account'**
  String get prototypeAccount;

  /// No description provided for @prototypeOnly.
  ///
  /// In en, this message translates to:
  /// **'Prototype data for design only'**
  String get prototypeOnly;

  /// No description provided for @inventoryOverview.
  ///
  /// In en, this message translates to:
  /// **'Inventory overview'**
  String get inventoryOverview;

  /// No description provided for @componentStat.
  ///
  /// In en, this message translates to:
  /// **'Components'**
  String get componentStat;

  /// No description provided for @stockTotal.
  ///
  /// In en, this message translates to:
  /// **'Total stock'**
  String get stockTotal;

  /// No description provided for @locationStat.
  ///
  /// In en, this message translates to:
  /// **'Locations'**
  String get locationStat;

  /// No description provided for @initializeTagSection.
  ///
  /// In en, this message translates to:
  /// **'NFC tags'**
  String get initializeTagSection;

  /// No description provided for @initializeTagTitle.
  ///
  /// In en, this message translates to:
  /// **'Initialize NFC tag'**
  String get initializeTagTitle;

  /// No description provided for @initializeTagDescription.
  ///
  /// In en, this message translates to:
  /// **'Create a 1×N CompBox container on an NFC tag.'**
  String get initializeTagDescription;

  /// No description provided for @initializeTagColumns.
  ///
  /// In en, this message translates to:
  /// **'Compartments'**
  String get initializeTagColumns;

  /// No description provided for @initializeTagLayout.
  ///
  /// In en, this message translates to:
  /// **'1×{columns}'**
  String initializeTagLayout(String columns);

  /// No description provided for @initializeTagAction.
  ///
  /// In en, this message translates to:
  /// **'Initialize'**
  String get initializeTagAction;

  /// No description provided for @initializeTagConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Initialization clears all existing tag content, including older CompBox records and unrecognized NDEF data.'**
  String get initializeTagConfirmation;

  /// No description provided for @initializeTagFirstScan.
  ///
  /// In en, this message translates to:
  /// **'Hold the tag near your phone to check it.'**
  String get initializeTagFirstScan;

  /// No description provided for @initializeTagSecondScan.
  ///
  /// In en, this message translates to:
  /// **'Hold the same tag near your phone again to initialize it.'**
  String get initializeTagSecondScan;

  /// No description provided for @initializeTagSuccess.
  ///
  /// In en, this message translates to:
  /// **'NFC tag initialized'**
  String get initializeTagSuccess;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @settingsInProgress.
  ///
  /// In en, this message translates to:
  /// **'Settings are under design'**
  String get settingsInProgress;

  /// No description provided for @exportDatabase.
  ///
  /// In en, this message translates to:
  /// **'Export database'**
  String get exportDatabase;

  /// No description provided for @exportDatabaseSuccess.
  ///
  /// In en, this message translates to:
  /// **'Exported {count} component records'**
  String exportDatabaseSuccess(String count);

  /// No description provided for @exportDatabaseFailed.
  ///
  /// In en, this message translates to:
  /// **'The database could not be exported. Try again.'**
  String get exportDatabaseFailed;

  /// No description provided for @importDatabase.
  ///
  /// In en, this message translates to:
  /// **'Import database'**
  String get importDatabase;

  /// No description provided for @importDatabaseConfirmation.
  ///
  /// In en, this message translates to:
  /// **'This backup contains {count} records. Continuing will replace the current local database and cannot be undone. NFC tag contents will not be changed.'**
  String importDatabaseConfirmation(String count);

  /// No description provided for @confirmImportDatabase.
  ///
  /// In en, this message translates to:
  /// **'Import backup'**
  String get confirmImportDatabase;

  /// No description provided for @importDatabaseSuccess.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} component records'**
  String importDatabaseSuccess(String count);

  /// No description provided for @invalidBackupFile.
  ///
  /// In en, this message translates to:
  /// **'The selected file is not a valid CompBox backup'**
  String get invalidBackupFile;

  /// No description provided for @importDatabaseFailed.
  ///
  /// In en, this message translates to:
  /// **'The database could not be imported. Try again.'**
  String get importDatabaseFailed;

  /// No description provided for @clearDatabase.
  ///
  /// In en, this message translates to:
  /// **'Clear database'**
  String get clearDatabase;

  /// No description provided for @clearDatabaseConfirmation.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone. All locally stored component records will be permanently deleted. NFC tag contents will not be changed.'**
  String get clearDatabaseConfirmation;

  /// No description provided for @confirmClearDatabase.
  ///
  /// In en, this message translates to:
  /// **'Clear database'**
  String get confirmClearDatabase;

  /// No description provided for @clearDatabaseSuccess.
  ///
  /// In en, this message translates to:
  /// **'Local database cleared'**
  String get clearDatabaseSuccess;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @recordDeleted.
  ///
  /// In en, this message translates to:
  /// **'Record deleted'**
  String get recordDeleted;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

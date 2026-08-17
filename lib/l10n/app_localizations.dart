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
  /// **'Profile'**
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
  /// **'Profile'**
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

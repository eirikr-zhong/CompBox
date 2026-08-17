// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '芯盒';

  @override
  String get homeTitle => '芯盒';

  @override
  String get searchHint => '搜索元器件、型号、位置…';

  @override
  String get scanTooltip => '扫码';

  @override
  String get scanInProgress => '扫码功能设计中';

  @override
  String get myComponents => '我的元器件';

  @override
  String get location => '位置';

  @override
  String get quantity => '数量';

  @override
  String quantityValue(String quantity) {
    return '$quantity 个';
  }

  @override
  String get home => '首页';

  @override
  String get profile => '我的';

  @override
  String get nfcScan => 'NFC 扫描';

  @override
  String get nfcPreparing => '正在准备 NFC 扫描';

  @override
  String get componentDetail => '元器件详情';

  @override
  String get inventoryInformation => '库存信息';

  @override
  String get specificationInformation => '规格信息';

  @override
  String get manufacturerModel => '厂商 / 型号';

  @override
  String get currentQuantity => '当前数量';

  @override
  String get category => '类别';

  @override
  String get categoryResistor => '电阻';

  @override
  String get categoryCapacitor => '电容';

  @override
  String get categoryDiode => '二极管';

  @override
  String get categoryInductor => '电感';

  @override
  String get categoryTimer => '集成电路';

  @override
  String get categoryConnector => '连接器';

  @override
  String get categoryLed => '发光二极管';

  @override
  String get nameResistor => '10kΩ 电阻';

  @override
  String get nameCapacitor => '100nF 电容';

  @override
  String get nameDiode => '1N4148 二极管';

  @override
  String get nameInductor => '22uH 电感';

  @override
  String get nameTimer => 'NE555 定时器';

  @override
  String get nameConnector => 'USB-C 连接器';

  @override
  String get nameLed => 'LED 5mm 蓝色';

  @override
  String get specResistor => '1/4W  ±1%';

  @override
  String get specCapacitor => '50V  X7R  0603';

  @override
  String get specDiode => '开关二极管  SOD-123';

  @override
  String get specInductor => '功率电感  3.0A';

  @override
  String get specTimer => 'SOP-8';

  @override
  String get specConnector => 'Type-C 16P 板上型';

  @override
  String get specLed => '直插 LED';

  @override
  String get profileTitle => '我的';

  @override
  String get profileMonogram => '芯';

  @override
  String get prototypeAccount => '芯盒 设计账号';

  @override
  String get prototypeOnly => '设计期数据，仅作原型演示';

  @override
  String get inventoryOverview => '库存概览';

  @override
  String get componentStat => '元器件';

  @override
  String get stockTotal => '库存总数';

  @override
  String get locationStat => '库位';

  @override
  String get settings => '设置';

  @override
  String get preferences => '偏好设置';

  @override
  String get settingsInProgress => '设置功能设计中';
}

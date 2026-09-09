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
  String get allCategories => '全部类别';

  @override
  String get emptyInventoryTitle => '还没有元器件记录';

  @override
  String get emptyInventoryDescription => '扫描 NFC 标签后可新建第一条记录。';

  @override
  String get noMatchingComponents => '没有匹配的元器件';

  @override
  String get noMatchingComponentsDescription => '请调整搜索内容或类别筛选。';

  @override
  String get resourceLoadError => '无法加载本地资源配置。';

  @override
  String get location => '位置';

  @override
  String get quantity => '数量';

  @override
  String get inventory => '库存';

  @override
  String quantityValue(String quantity) {
    return '$quantity 个';
  }

  @override
  String get home => '主页';

  @override
  String get profile => '设置';

  @override
  String get nfcScan => 'NFC 扫描';

  @override
  String get nfcPreparing => '正在准备 NFC 扫描';

  @override
  String get nfcTitle => 'NFC';

  @override
  String get nfcScanningTitle => 'NFC 扫描中';

  @override
  String get nfcScanning => '扫描中';

  @override
  String get nfcScanInstruction => '请将手机背面靠近 NFC 标签';

  @override
  String get nfcReadyToScan => '准备扫描 NFC 标签';

  @override
  String get nfcScanTag => '扫描标签';

  @override
  String get nfcRescan => '重新扫描标签';

  @override
  String get nfcWriteTag => '重新扫描并写入标签';

  @override
  String get nfcError => 'NFC 操作失败';

  @override
  String get nfcUnavailable => '此设备不支持 NFC。';

  @override
  String get nfcDisabled => 'NFC 已关闭，请先在系统设置中开启。';

  @override
  String get nfcUnsupportedTag => '此标签不支持 NDEF。';

  @override
  String get nfcReadOnly => '此 NFC 标签为只读，无法写入。';

  @override
  String get nfcCapacityError => '标签容量不足，无法写入此快照。';

  @override
  String nfcPayloadTooLarge(String bytes, String limit) {
    return '快照共 $bytes 字节，超过标签保守上限 $limit 字节。';
  }

  @override
  String get nfcUidMismatch => '重新扫描的标签与当前编辑的标签不一致。';

  @override
  String get nfcCrcError => '标签快照校验失败，数据可能已损坏。';

  @override
  String get nfcUnknownProtocol => '标签不包含可识别的 CompBox 快照。';

  @override
  String get nfcUnsupportedVersion => '此标签使用了不支持的 CompBox 快照版本。';

  @override
  String get nfcInvalidSnapshot => '标签快照格式无效。';

  @override
  String get nfcNeedsInitialization => '请先初始化此标签，再用于芯盒。';

  @override
  String get nfcReinitializeTag => '此标签使用旧版芯盒格式，请重新初始化后再使用。';

  @override
  String get nfcSlotSelectionTitle => '选择格子';

  @override
  String get nfcFinishEditing => '完成编辑';

  @override
  String get nfcSaveAll => '保存全部格子';

  @override
  String get nfcClearTag => '清空标签';

  @override
  String get nfcClearTagDialogDescription => '请将手机背面靠近 NFC 标签，完成清空。';

  @override
  String get nfcClearTagSuccess => 'NFC 标签已清空';

  @override
  String get nfcSlotEmpty => '空';

  @override
  String nfcSlotLabel(String index) {
    return '第 $index 格';
  }

  @override
  String get nfcCustomTextTooLong => '自定义文本过长，无法写入标签。';

  @override
  String get nfcReadFailed => '无法读取此 NFC 标签，请重试。';

  @override
  String get nfcWriteFailed => '无法写入此 NFC 标签，请重试。';

  @override
  String get nfcTagOverridesLocalTitle => '以标签记录覆盖本地记录？';

  @override
  String nfcTagOverridesLocalDescription(String location) {
    return '库位 $location 的本地副本与标签不一致。确认后将以标签内容覆盖本地副本。';
  }

  @override
  String get nfcTagRead => 'NFC 标签已读取';

  @override
  String get nfcRead => '已读取';

  @override
  String get nfcTagReadDescription => '标签信息已读取，可编辑入库信息';

  @override
  String get componentName => '元器件名称';

  @override
  String get componentNameHint => '请输入元器件名称';

  @override
  String get modelSpecification => '型号 / 规格';

  @override
  String get modelSpecificationHint => '请输入型号或规格';

  @override
  String get decreaseQuantity => '减少数量';

  @override
  String get increaseQuantity => '增加数量';

  @override
  String get save => '保存';

  @override
  String get nfcSaveDialogTitle => '扫描标签保存';

  @override
  String get nfcSaveDialogDescription => '请将手机背面靠近 NFC 标签，完成保存。';

  @override
  String get cancel => '取消';

  @override
  String requiredField(String field) {
    return '请填写 $field';
  }

  @override
  String get invalidInteger => '请输入整数';

  @override
  String get invalidNumber => '请输入有效数值';

  @override
  String get invalidLocation => '请输入 A-01-03 格式的库位（编号 1–255）';

  @override
  String get insufficientStock => '出库数量不能超过当前库存';

  @override
  String currentQuantityValue(String quantity) {
    return '当前库存：$quantity';
  }

  @override
  String get recordSaved => '记录已保存';

  @override
  String get overwriteRecordTitle => '覆盖已有记录？';

  @override
  String overwriteRecordDescription(String location) {
    return '位置 $location 已有记录。确认后将使用表单中的完整数据覆盖它。';
  }

  @override
  String get overwrite => '覆盖';

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
  String get profileTitle => '设置';

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
  String get initializeTagSection => 'NFC 标签';

  @override
  String get initializeTagTitle => '初始化 NFC 标签';

  @override
  String get initializeTagDescription => '在 NFC 标签上创建 1×N 芯盒容器。';

  @override
  String get initializeTagColumns => '格数';

  @override
  String initializeTagLayout(String columns) {
    return '1×$columns';
  }

  @override
  String get initializeTagAction => '初始化';

  @override
  String get initializeTagConfirmation =>
      '初始化会清空标签中的所有原有内容，包括旧版芯盒记录和无法识别的 NDEF 数据。';

  @override
  String get initializeTagFirstScan => '请将标签靠近手机，检查标签状态。';

  @override
  String get initializeTagSecondScan => '请再次将同一标签靠近手机，完成初始化。';

  @override
  String get initializeTagSuccess => 'NFC 标签已初始化';

  @override
  String get settings => '设置';

  @override
  String get preferences => '偏好设置';

  @override
  String get settingsInProgress => '设置功能设计中';

  @override
  String get exportDatabase => '导出数据库';

  @override
  String exportDatabaseSuccess(String count) {
    return '已导出 $count 条元器件记录';
  }

  @override
  String get exportDatabaseFailed => '无法导出数据库，请重试';

  @override
  String get importDatabase => '导入数据库';

  @override
  String importDatabaseConfirmation(String count) {
    return '备份中包含 $count 条记录。继续后将覆盖当前本地数据库，此操作无法撤销。NFC 标签内容不会受到影响。';
  }

  @override
  String get confirmImportDatabase => '确认导入';

  @override
  String importDatabaseSuccess(String count) {
    return '已导入 $count 条元器件记录';
  }

  @override
  String get invalidBackupFile => '所选文件不是有效的芯盒备份';

  @override
  String get importDatabaseFailed => '无法导入数据库，请重试';

  @override
  String get clearDatabase => '清空数据库';

  @override
  String get clearDatabaseConfirmation =>
      '此操作无法恢复。本地保存的全部元器件记录将被永久删除，NFC 标签内容不会受到影响。';

  @override
  String get confirmClearDatabase => '确认清空';

  @override
  String get clearDatabaseSuccess => '本地数据库已清空';

  @override
  String get delete => '删除';

  @override
  String get recordDeleted => '记录已删除';
}

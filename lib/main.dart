import 'dart:async' show Timer, unawaited;

import 'package:flutter/foundation.dart' show ChangeNotifier, ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart' as intl;
import 'package:nfc_manager/ndef_record.dart';
import 'package:rive_animated_icon/rive_animated_icon.dart';

import 'data/component_backup.dart';
import 'data/component_repository.dart';
import 'data/nfc_snapshot.dart';
import 'data/nfc_tag_service.dart';
import 'data/resource_catalog.dart';
import 'l10n/app_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CompBoxApp());
}

class CompBoxApp extends StatefulWidget {
  const CompBoxApp({
    super.key,
    this.locale,
    this.catalog,
    this.repository,
    this.nfcTagService,
    this.backupFileService,
  });

  final Locale? locale;
  final ResourceCatalog? catalog;
  final ComponentRepository? repository;
  final NfcTagService? nfcTagService;
  final ComponentBackupFileService? backupFileService;

  @override
  State<CompBoxApp> createState() => _CompBoxAppState();
}

class _CompBoxAppState extends State<CompBoxApp> {
  ResourceCatalog? _catalog;
  ComponentRepository? _repository;
  Object? _initializationError;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final catalog = widget.catalog ?? await ResourceCatalog.loadFromAssets();
      final repository =
          widget.repository ?? await ComponentRepository.openDefault();
      if (!mounted) {
        if (widget.repository == null) {
          repository.close();
        }
        return;
      }
      setState(() {
        _catalog = catalog;
        _repository = repository;
      });
    } catch (error) {
      if (mounted) {
        setState(() => _initializationError = error);
      }
    }
  }

  @override
  void dispose() {
    if (widget.repository == null) {
      _repository?.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const colorScheme = ColorScheme.light(
      primary: Color(0xFF0878F8),
      onPrimary: Colors.white,
      surface: Colors.white,
      onSurface: Color(0xFF16181D),
    );
    return ScreenUtilInit(
      designSize: const Size(393, 852),
      minTextAdapt: true,
      splitScreenMode: true,
      useInheritedMediaQuery: false,
      builder: (context, child) => MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
        locale: widget.locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: colorScheme,
          scaffoldBackgroundColor: const Color(0xFFF8F9FB),
          fontFamily: 'sans-serif',
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFF8F9FB),
            foregroundColor: Color(0xFF16181D),
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            systemOverlayStyle: SystemUiOverlayStyle.dark,
          ),
        ),
        home: _catalog != null && _repository != null
            ? CompBoxHome(
                catalog: _catalog!,
                repository: _repository!,
                nfcTagService: widget.nfcTagService ?? PlatformNfcTagService(),
                backupFileService:
                    widget.backupFileService ??
                    const PlatformComponentBackupFileService(),
              )
            : _StartupPage(error: _initializationError),
      ),
    );
  }
}

class _StartupPage extends StatelessWidget {
  const _StartupPage({this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: error == null
              ? const CircularProgressIndicator(key: Key('app-loading'))
              : Text(
                  l10n.resourceLoadError,
                  key: const Key('resource-load-error'),
                  textAlign: TextAlign.center,
                ),
        ),
      ),
    );
  }
}

class CompBoxHome extends StatefulWidget {
  const CompBoxHome({
    super.key,
    required this.catalog,
    required this.repository,
    required this.nfcTagService,
    required this.backupFileService,
  });

  final ResourceCatalog catalog;
  final ComponentRepository repository;
  final NfcTagService nfcTagService;
  final ComponentBackupFileService backupFileService;

  @override
  State<CompBoxHome> createState() => _CompBoxHomeState();
}

class _CompBoxHomeState extends State<CompBoxHome> {
  final _searchController = TextEditingController();
  late List<ComponentRecord> _records;
  int _selectedTab = 0;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _records = widget.repository.all();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reloadRecords() {
    setState(() => _records = widget.repository.all());
  }

  List<ComponentRecord> get _filteredRecords {
    final query = _searchController.text.trim().toLowerCase();
    return _records
        .where((record) {
          if (_selectedCategoryId != null &&
              record.categoryId != _selectedCategoryId) {
            return false;
          }
          if (query.isEmpty) {
            return true;
          }
          final category = widget.catalog.categoryById(record.categoryId);
          return [
            record.location,
            record.categoryId,
            category.name.resolve('en'),
            category.name.resolve('zh'),
            ...record.values.values.map((value) => value.toString()),
          ].any((value) => value.toLowerCase().contains(query));
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('home-scaffold'),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxContentWidth = constraints.maxWidth >= 700
                ? 680.0
                : double.infinity;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: IndexedStack(
                  index: _selectedTab,
                  children: [
                    _InventoryPage(
                      catalog: widget.catalog,
                      records: _filteredRecords,
                      allRecordsEmpty: _records.isEmpty,
                      searchController: _searchController,
                      selectedCategoryId: _selectedCategoryId,
                      onSearchChanged: (_) => setState(() {}),
                      onCategoryChanged: (categoryId) {
                        setState(() => _selectedCategoryId = categoryId);
                      },
                      onRecordPressed: (record) async {
                        final deleted = await Navigator.of(context).push<bool>(
                          MaterialPageRoute<bool>(
                            builder: (_) => ComponentDetailPage(
                              catalog: widget.catalog,
                              record: record,
                            ),
                          ),
                        );
                        if (deleted == true && context.mounted) {
                          widget.repository.delete(record.location);
                          _reloadRecords();
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFF1B7F3B),
                                content: Text(
                                  AppLocalizations.of(context)!.recordDeleted,
                                ),
                              ),
                            );
                        }
                      },
                    ),
                    _NfcScanPage(
                      catalog: widget.catalog,
                      repository: widget.repository,
                      nfcTagService: widget.nfcTagService,
                      active: _selectedTab == 1,
                      onSaved: _reloadRecords,
                    ),
                    _ProfilePage(
                      catalog: widget.catalog,
                      records: _records,
                      backupFileService: widget.backupFileService,
                      onImportDatabase: (records) {
                        widget.repository.replaceAll(records);
                        _reloadRecords();
                      },
                      onClearDatabase: () {
                        widget.repository.clear();
                        _reloadRecords();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        child: SafeArea(
          top: false,
          child: _BottomNavigation(
            selectedIndex: _selectedTab,
            onHomePressed: () => setState(() => _selectedTab = 0),
            onProfilePressed: () => setState(() => _selectedTab = 2),
            onNfcPressed: () => setState(() => _selectedTab = 1),
          ),
        ),
      ),
    );
  }
}

class _InventoryPage extends StatelessWidget {
  const _InventoryPage({
    required this.catalog,
    required this.records,
    required this.allRecordsEmpty,
    required this.searchController,
    required this.selectedCategoryId,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onRecordPressed,
  });

  final ResourceCatalog catalog;
  final List<ComponentRecord> records;
  final bool allRecordsEmpty;
  final TextEditingController searchController;
  final String? selectedCategoryId;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<ComponentRecord> onRecordPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      key: const Key('inventory-list'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        const _HomeHeading(),
        _SearchField(controller: searchController, onChanged: onSearchChanged),
        const SizedBox(height: 12),
        _CategoryFilter(
          catalog: catalog,
          selectedCategoryId: selectedCategoryId,
          onCategoryChanged: onCategoryChanged,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 22, 0, 12),
          child: Text(
            l10n.myComponents,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ),
        if (records.isEmpty)
          _EmptyInventory(allRecordsEmpty: allRecordsEmpty)
        else
          for (final record in records)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: ComponentCard(
                catalog: catalog,
                record: record,
                onPressed: () => onRecordPressed(record),
              ),
            ),
      ],
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({
    required this.catalog,
    required this.selectedCategoryId,
    required this.onCategoryChanged,
  });

  final ResourceCatalog catalog;
  final String? selectedCategoryId;
  final ValueChanged<String?> onCategoryChanged;

  Future<void> _showPicker(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _CategoryPickerSheet(
        catalog: catalog,
        selectedCategoryId: selectedCategoryId,
        onCategorySelected: (categoryId) {
          onCategoryChanged(categoryId);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    final selectedLabel = selectedCategoryId == null
        ? l10n.allCategories
        : catalog.categoryById(selectedCategoryId!).name.resolve(languageCode);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        key: const Key('category-filter'),
        borderRadius: BorderRadius.circular(8),
        onTap: () => _showPicker(context),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E8EE)),
          ),
          child: Row(
            children: [
              const Icon(Icons.tune_rounded, color: Color(0xFF687487)),
              const SizedBox(width: 10),
              Text(
                l10n.category,
                style: const TextStyle(color: Color(0xFF687487)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  selectedLabel,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.expand_more_rounded, color: Color(0xFF687487)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryPickerSheet extends StatelessWidget {
  const _CategoryPickerSheet({
    required this.catalog,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    this.includeAllCategories = true,
    this.sheetKey = const Key('category-picker-sheet'),
    this.optionKeyPrefix = 'category-filter-option',
  });

  final ResourceCatalog catalog;
  final String? selectedCategoryId;
  final ValueChanged<String?> onCategorySelected;
  final bool includeAllCategories;
  final Key sheetKey;
  final String optionKeyPrefix;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    return SafeArea(
      top: false,
      child: Container(
        key: sheetKey,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .72,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFD6DAE1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.category,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFEDF0F4)),
            Flexible(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shrinkWrap: true,
                children: [
                  if (includeAllCategories)
                    _CategoryPickerOption(
                      key: Key('$optionKeyPrefix-all'),
                      label: l10n.allCategories,
                      selected: selectedCategoryId == null,
                      icon: const _CategoryPickerAllIcon(),
                      onPressed: () => onCategorySelected(null),
                    ),
                  for (final category in catalog.categories)
                    _CategoryPickerOption(
                      key: Key('$optionKeyPrefix-${category.id}'),
                      label: category.name.resolve(languageCode),
                      selected: selectedCategoryId == category.id,
                      icon: ComponentThumbnail(category: category, size: 42),
                      onPressed: () => onCategorySelected(category.id),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryPickerOption extends StatelessWidget {
  const _CategoryPickerOption({
    super.key,
    required this.label,
    required this.selected,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final Widget icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              icon,
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (selected)
                const Icon(Icons.check_rounded, color: Color(0xFF0878F8)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryPickerAllIcon extends StatelessWidget {
  const _CategoryPickerAllIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.apps_rounded, color: Color(0xFF0878F8)),
    );
  }
}

class _EmptyInventory extends StatelessWidget {
  const _EmptyInventory({required this.allRecordsEmpty});

  final bool allRecordsEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 44, 8, 0),
      child: Column(
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 46,
            color: Color(0xFF8A96A8),
          ),
          const SizedBox(height: 14),
          Text(
            allRecordsEmpty
                ? l10n.emptyInventoryTitle
                : l10n.noMatchingComponents,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            allRecordsEmpty
                ? l10n.emptyInventoryDescription
                : l10n.noMatchingComponentsDescription,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF738095), height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _HomeHeading extends StatelessWidget {
  const _HomeHeading();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        AppLocalizations.of(context)!.homeTitle,
        style: const TextStyle(
          color: Color(0xFF121419),
          fontSize: 28,
          fontWeight: FontWeight.w800,
          height: 1.1,
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: TextField(
        key: const Key('component-search'),
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 15, color: Color(0xFF24272D)),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.searchHint,
          hintStyle: const TextStyle(color: Color(0xFF8B95A7), fontSize: 15),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF8993A5),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: Color(0xFFE5E8EE)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: Color(0xFF0878F8), width: 1.4),
          ),
        ),
      ),
    );
  }
}

class ComponentCard extends StatelessWidget {
  const ComponentCard({
    super.key,
    required this.catalog,
    required this.record,
    required this.onPressed,
  });

  final ResourceCatalog catalog;
  final ComponentRecord record;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final category = catalog.categoryById(record.categoryId);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        key: Key('component-${record.location}'),
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Container(
          height: 82,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFEFF1F4)),
          ),
          child: Row(
            children: [
              ComponentThumbnail(category: category, size: 54),
              const SizedBox(width: 9),
              Expanded(
                child: _ComponentOverview(record: record, category: category),
              ),
              const SizedBox(width: 5),
              _InventorySummary(record: record),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF9AA4B5)),
            ],
          ),
        ),
      ),
    );
  }
}

class ComponentThumbnail extends StatelessWidget {
  const ComponentThumbnail({super.key, required this.category, this.size = 70});

  final CategoryDefinition category;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * .18),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8EBEF)),
      ),
      child: SvgPicture.asset('assets/resource/${category.iconPath}'),
    );
  }
}

class _ComponentOverview extends StatelessWidget {
  const _ComponentOverview({required this.record, required this.category});

  final ComponentRecord record;
  final CategoryDefinition category;

  @override
  Widget build(BuildContext context) {
    const secondary = TextStyle(
      color: Color(0xFF717B8D),
      fontSize: 11.5,
      height: 1.2,
    );
    final languageCode = Localizations.localeOf(context).languageCode;
    final specification = _stringValue(record, 'tolerance');
    final model = _stringValue(record, 'manufacturerModel');
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _recordName(record, category, languageCode),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          specification.isEmpty
              ? category.name.resolve(languageCode)
              : specification,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: secondary,
        ),
        if (model.isNotEmpty)
          Text(
            model,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: secondary,
          ),
      ],
    );
  }
}

class _InventorySummary extends StatelessWidget {
  const _InventorySummary({required this.record});

  final ComponentRecord record;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: 68,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.location, style: _inventoryCaption),
          const SizedBox(height: 1),
          Text(
            record.location,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, height: 1),
          ),
          const SizedBox(height: 3),
          Text(l10n.quantity, style: _inventoryCaption),
          const SizedBox(height: 1),
          Text(
            _quantityLabel(context, record.quantity),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, height: 1),
          ),
        ],
      ),
    );
  }
}

const _inventoryCaption = TextStyle(
  color: Color(0xFF8D96A5),
  fontSize: 9.5,
  height: 1,
);

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({
    required this.selectedIndex,
    required this.onHomePressed,
    required this.onProfilePressed,
    required this.onNfcPressed,
  });

  final int selectedIndex;
  final VoidCallback onHomePressed;
  final VoidCallback onProfilePressed;
  final VoidCallback onNfcPressed;

  @override
  Widget build(BuildContext context) {
    final selectedColor = Theme.of(context).colorScheme.primary;
    return SizedBox(
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFEDF0F4))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _NavigationItem(
                    key: const Key('home-tab'),
                    icon: Icons.home_rounded,
                    label: AppLocalizations.of(context)!.home,
                    selected: selectedIndex == 0,
                    selectedColor: selectedColor,
                    onPressed: onHomePressed,
                  ),
                ),
                const SizedBox(width: 80),
                Expanded(
                  child: _NavigationItem(
                    key: const Key('profile-tab'),
                    icon: Icons.settings_outlined,
                    label: AppLocalizations.of(context)!.profile,
                    selected: selectedIndex == 2,
                    selectedColor: selectedColor,
                    onPressed: onProfilePressed,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 5,
            child: Material(
              color: selectedColor,
              elevation: 6,
              shadowColor: const Color(0x450878F8),
              shape: const CircleBorder(),
              child: InkWell(
                key: const Key('nfc-button'),
                customBorder: const CircleBorder(),
                onTap: onNfcPressed,
                child: const SizedBox(
                  width: 70,
                  height: 70,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.nfc_rounded, color: Colors.white, size: 28),
                      SizedBox(height: 1),
                      Text(
                        'NFC',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = selected ? selectedColor : const Color(0xFF7B8596);
    return InkWell(
      onTap: onPressed,
      child: Semantics(
        label: label,
        button: true,
        selected: selected,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 23),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _NfcWriteStatus { writing, failure }

enum _NfcWriteAction { save, clear }

/// Keeps a scanned tag and its editable grid alive while NFC routes are open.
class _NfcDraftSession extends ChangeNotifier {
  ScannedNfcTag? tag;
  CompBoxTagGrid? grid;
  String? status;
  bool writing = false;
  _NfcWriteStatus? writeStatus;

  void start({required ScannedNfcTag scannedTag, CompBoxTagGrid? scannedGrid}) {
    tag = scannedTag;
    grid = scannedGrid;
    status = null;
    writing = false;
    writeStatus = null;
    notifyListeners();
  }

  void clear() {
    tag = null;
    grid = null;
    status = null;
    writing = false;
    writeStatus = null;
    notifyListeners();
  }

  void updateGrid(CompBoxTagGrid value) {
    grid = value;
    notifyListeners();
  }

  void updateStatus(String? value, {_NfcWriteStatus? outcome}) {
    status = value;
    writeStatus = outcome;
    notifyListeners();
  }

  void updateWriting(bool value, {_NfcWriteStatus? outcome}) {
    writing = value;
    writeStatus = outcome;
    notifyListeners();
  }
}

class _NfcScanPage extends StatefulWidget {
  const _NfcScanPage({
    required this.catalog,
    required this.repository,
    required this.nfcTagService,
    required this.active,
    required this.onSaved,
  });

  final ResourceCatalog catalog;
  final ComponentRepository repository;
  final NfcTagService nfcTagService;
  final bool active;
  final VoidCallback onSaved;

  @override
  State<_NfcScanPage> createState() => _NfcScanPageState();
}

class _NfcScanPageState extends State<_NfcScanPage> {
  final _session = _NfcDraftSession();
  bool _scanning = false;
  String? _nfcStatus;

  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  @override
  void didUpdateWidget(covariant _NfcScanPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_scanning && !_session.writing) {
          _readTag();
        }
      });
    } else if (!widget.active && oldWidget.active) {
      widget.nfcTagService.cancelSession();
      // The platform callback can be delayed after cancellation. Reset locally
      // so the next visit always starts a fresh NFC session.
      _scanning = false;
    }
  }

  @override
  void dispose() {
    widget.nfcTagService.cancelSession();
    _session.dispose();
    super.dispose();
  }

  Future<void> _checkAvailability() async {
    final availability = await widget.nfcTagService.checkAvailability();
    if (!mounted) {
      return;
    }
    setState(() {
      _nfcStatus = switch (availability) {
        NfcServiceAvailability.enabled => null,
        NfcServiceAvailability.disabled => AppLocalizations.of(
          context,
        )!.nfcDisabled,
        NfcServiceAvailability.unsupported => AppLocalizations.of(
          context,
        )!.nfcUnavailable,
      };
    });
  }

  Future<void> _readTag() async {
    if (_scanning || _session.writing) {
      return;
    }
    setState(() {
      _scanning = true;
      _nfcStatus = null;
    });
    _session.clear();
    ScannedNfcTag? scannedTag;
    try {
      final tag = scannedTag = await widget.nfcTagService.readTag();
      if (!mounted) {
        return;
      }
      switch (tag.kind) {
        case NfcTagKind.ndef:
          final message = tag.message;
          if (message == null ||
              message.records.length != 1 ||
              message.records.single.typeNameFormat != TypeNameFormat.unknown ||
              message.records.single.type.isNotEmpty ||
              message.records.single.identifier.isNotEmpty) {
            _openInitialization(tag, reinitialize: true);
            return;
          }
          final payload = message.records.single.payload;
          final layout = CompBoxSnapshot.layoutOf(payload);
          if (layout == CompBoxTagLayout.legacyRecord ||
              layout == CompBoxTagLayout.legacyInitialization) {
            _openInitialization(tag, reinitialize: true);
            return;
          }
          if (layout != CompBoxTagLayout.grid) {
            _openInitialization(tag, reinitialize: true);
            return;
          }
          final grid = CompBoxSnapshot.decodeGrid(
            payload: message.records.single.payload,
            catalog: widget.catalog,
          );
          _openGrid(tag: tag, grid: grid);
        case NfcTagKind.blankNdef:
        case NfcTagKind.formatable:
          _openInitialization(tag, reinitialize: false);
        case NfcTagKind.unsupported:
          throw const NfcTagServiceException(
            NfcTagServiceError.unsupportedTag,
            'This tag is not NDEF compatible.',
          );
      }
    } on SnapshotFormatException catch (error) {
      if (mounted && scannedTag != null) {
        _openInitialization(scannedTag, reinitialize: true);
      } else if (mounted) {
        setState(() => _nfcStatus = _snapshotErrorMessage(error));
      }
    } on NfcTagServiceException catch (error) {
      if (mounted) {
        setState(() => _nfcStatus = _serviceErrorMessage(error));
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _nfcStatus = AppLocalizations.of(context)!.nfcReadFailed,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _scanning = false);
      }
    }
  }

  void _openGrid({required ScannedNfcTag tag, required CompBoxTagGrid grid}) {
    _session.start(scannedTag: tag, scannedGrid: grid);
  }

  void _openInitialization(ScannedNfcTag tag, {required bool reinitialize}) {
    final status = reinitialize
        ? AppLocalizations.of(context)!.nfcReinitializeTag
        : AppLocalizations.of(context)!.nfcNeedsInitialization;
    _session.start(scannedTag: tag, scannedGrid: null);
    _session.updateStatus(status);
    setState(() {
      _nfcStatus = status;
    });
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _NfcInitializationPage(
          catalog: widget.catalog,
          repository: widget.repository,
          nfcTagService: widget.nfcTagService,
          session: _session,
          onSaved: widget.onSaved,
        ),
      ),
    );
  }

  String _snapshotErrorMessage(SnapshotFormatException error) {
    final l10n = AppLocalizations.of(context)!;
    return switch (error.code) {
      SnapshotErrorCode.crc => l10n.nfcCrcError,
      SnapshotErrorCode.protocol => l10n.nfcUnknownProtocol,
      SnapshotErrorCode.version => l10n.nfcUnsupportedVersion,
      SnapshotErrorCode.location => l10n.invalidLocation,
      SnapshotErrorCode.attributeTooLong ||
      SnapshotErrorCode.attributesTooLong => l10n.nfcCustomTextTooLong,
      SnapshotErrorCode.containerTooLarge => l10n.nfcPayloadTooLarge(
        '${error.bytes ?? CompBoxSnapshot.conservativeNdefLimit + 1}',
        '${CompBoxSnapshot.conservativeNdefLimit}',
      ),
      _ => l10n.nfcInvalidSnapshot,
    };
  }

  String _serviceErrorMessage(NfcTagServiceException error) {
    final l10n = AppLocalizations.of(context)!;
    return switch (error.code) {
      NfcTagServiceError.disabled => l10n.nfcDisabled,
      NfcTagServiceError.unsupported => l10n.nfcUnavailable,
      NfcTagServiceError.unsupportedTag => l10n.nfcUnsupportedTag,
      NfcTagServiceError.readOnly => l10n.nfcReadOnly,
      NfcTagServiceError.capacity => l10n.nfcCapacityError,
      NfcTagServiceError.uidMismatch => l10n.nfcUidMismatch,
      NfcTagServiceError.malformedMessage => l10n.nfcUnknownProtocol,
      NfcTagServiceError.readFailed => l10n.nfcReadFailed,
      NfcTagServiceError.writeFailed => l10n.nfcWriteFailed,
    };
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _session,
      builder: (context, _) {
        if (_session.grid != null) {
          return _NfcGridOverviewPage(
            catalog: widget.catalog,
            repository: widget.repository,
            nfcTagService: widget.nfcTagService,
            session: _session,
            onSaved: widget.onSaved,
            onRescan: _readTag,
          );
        }
        return ListView(
          key: const Key('nfc-page'),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            const _NfcPageHeading(),
            const SizedBox(height: 18),
            _NfcStatusCard(
              tagRead: false,
              scanning: _scanning,
              writeStatus: null,
              status: _nfcStatus,
              onRescan: _scanning ? null : _readTag,
            ),
          ],
        );
      },
    );
  }
}

class _NfcInitializationPage extends StatefulWidget {
  const _NfcInitializationPage({
    required this.catalog,
    required this.repository,
    required this.nfcTagService,
    required this.session,
    required this.onSaved,
  });

  final ResourceCatalog catalog;
  final ComponentRepository repository;
  final NfcTagService nfcTagService;
  final _NfcDraftSession session;
  final VoidCallback onSaved;

  @override
  State<_NfcInitializationPage> createState() => _NfcInitializationPageState();
}

class _NfcInitializationPageState extends State<_NfcInitializationPage> {
  bool _confirmed = false;

  Future<void> _confirm() async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('nfc-initialize-confirmation'),
        title: Text(AppLocalizations.of(context)!.initializeTagTitle),
        content: Text(AppLocalizations.of(context)!.initializeTagConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            key: const Key('nfc-initialize-confirm-button'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context)!.initializeTagAction),
          ),
        ],
      ),
    );
    if (proceed == true && mounted) {
      setState(() => _confirmed = true);
    }
  }

  void _chooseLayout(int columns) {
    final tag = widget.session.tag;
    if (tag == null) {
      return;
    }
    widget.session.start(
      scannedTag: tag,
      scannedGrid: CompBoxTagGrid.empty(columns),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.initializeTagTitle)),
      body: ListView(
        key: const Key('nfc-initialization-page'),
        padding: const EdgeInsets.all(16),
        children: [
          _NfcStatusCard(
            tagRead: true,
            scanning: false,
            writeStatus: null,
            status: widget.session.status,
            title: l10n.initializeTagTitle,
          ),
          const SizedBox(height: 20),
          Text(l10n.initializeTagDescription),
          const SizedBox(height: 20),
          if (!_confirmed)
            SizedBox(
              height: 48,
              child: FilledButton(
                key: const Key('nfc-initialize-button'),
                onPressed: _confirm,
                child: Text(l10n.initializeTagAction),
              ),
            )
          else ...[
            Text(l10n.initializeTagColumns, style: _sectionTitle),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (
                  var columns = CompBoxSnapshot.minColumns;
                  columns <= CompBoxSnapshot.maxColumns;
                  columns++
                )
                  ChoiceChip(
                    key: Key('nfc-initialize-columns-$columns'),
                    label: Text(l10n.initializeTagLayout('$columns')),
                    selected: false,
                    onSelected: (_) => _chooseLayout(columns),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _NfcGridOverviewPage extends StatefulWidget {
  const _NfcGridOverviewPage({
    required this.catalog,
    required this.repository,
    required this.nfcTagService,
    required this.session,
    required this.onSaved,
    required this.onRescan,
  });

  final ResourceCatalog catalog;
  final ComponentRepository repository;
  final NfcTagService nfcTagService;
  final _NfcDraftSession session;
  final VoidCallback onSaved;
  final Future<void> Function() onRescan;

  @override
  State<_NfcGridOverviewPage> createState() => _NfcGridOverviewPageState();
}

class _NfcGridOverviewPageState extends State<_NfcGridOverviewPage> {
  final _scrollController = ScrollController();
  final _writeDialogCanPop = ValueNotifier<bool>(false);
  int _writeOperation = 0;
  _NfcWriteAction? _activeWriteAction;

  @override
  void dispose() {
    _scrollController.dispose();
    _writeDialogCanPop.dispose();
    super.dispose();
  }

  void _openSlot(int index) {
    if (widget.session.writing) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _NfcSlotEditorPage(
          catalog: widget.catalog,
          session: widget.session,
          slotIndex: index,
        ),
      ),
    );
  }

  Future<void> _saveAll() async {
    final tag = widget.session.tag;
    final grid = widget.session.grid;
    if (tag == null || grid == null || widget.session.writing) {
      return;
    }
    Uint8List payload;
    try {
      payload = CompBoxSnapshot.encodeGrid(grid: grid, catalog: widget.catalog);
    } on SnapshotFormatException catch (error) {
      widget.session.updateStatus(_snapshotErrorMessage(error));
      return;
    }
    if (CompBoxSnapshot.ndefMessageByteLength(payload.length) >
        CompBoxSnapshot.conservativeNdefLimit) {
      widget.session.updateStatus(
        AppLocalizations.of(context)!.nfcPayloadTooLarge(
          '${CompBoxSnapshot.ndefMessageByteLength(payload.length)}',
          '${CompBoxSnapshot.conservativeNdefLimit}',
        ),
      );
      return;
    }
    _beginWrite(
      grid: grid,
      expectedUid: tag.uid,
      payload: payload,
      dialogTitle: AppLocalizations.of(context)!.save,
      dialogDescription: AppLocalizations.of(context)!.nfcSaveDialogDescription,
      successLabel: AppLocalizations.of(context)!.recordSaved,
      action: _NfcWriteAction.save,
    );
  }

  Future<void> _clearTag() async {
    final tag = widget.session.tag;
    final grid = widget.session.grid;
    if (tag == null || grid == null || widget.session.writing) {
      return;
    }
    final clearedGrid = CompBoxTagGrid.empty(grid.columns);
    final payload = CompBoxSnapshot.encodeGrid(
      grid: clearedGrid,
      catalog: null,
    );
    final l10n = AppLocalizations.of(context)!;
    _beginWrite(
      grid: clearedGrid,
      expectedUid: tag.uid,
      payload: payload,
      dialogTitle: l10n.nfcClearTag,
      dialogDescription: l10n.nfcClearTagDialogDescription,
      successLabel: l10n.nfcClearTagSuccess,
      action: _NfcWriteAction.clear,
    );
  }

  void _beginWrite({
    required CompBoxTagGrid grid,
    required String expectedUid,
    required Uint8List payload,
    required String dialogTitle,
    required String dialogDescription,
    required String successLabel,
    required _NfcWriteAction action,
  }) {
    final operation = ++_writeOperation;
    _writeDialogCanPop.value = false;
    setState(() => _activeWriteAction = action);
    widget.session.updateWriting(true, outcome: _NfcWriteStatus.writing);
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _NfcWriteDialog(
          canPop: _writeDialogCanPop,
          onCancel: () => _cancelWrite(operation),
          title: dialogTitle,
          description: dialogDescription,
        ),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && operation == _writeOperation) {
        unawaited(
          _writeTag(
            operation: operation,
            grid: grid,
            expectedUid: expectedUid,
            payload: payload,
            successLabel: successLabel,
            action: action,
          ),
        );
      }
    });
  }

  Future<void> _writeTag({
    required int operation,
    required CompBoxTagGrid grid,
    required String expectedUid,
    required Uint8List payload,
    required String successLabel,
    required _NfcWriteAction action,
  }) async {
    try {
      await widget.nfcTagService.writeTag(
        expectedUid: expectedUid,
        payload: payload,
      );
      if (!mounted || operation != _writeOperation) {
        return;
      }
      for (final slot in grid.slots) {
        if (slot.record case final record?) {
          widget.repository.save(record);
        }
      }
      widget.session
        ..updateGrid(grid)
        ..updateWriting(false);
      setState(() => _activeWriteAction = null);
      _closeWriteDialog();
      widget.onSaved();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1B7F3B),
            duration: const Duration(seconds: 2),
            content: _NfcSavedToastContent(label: successLabel),
          ),
        );
    } on NfcTagServiceException catch (error) {
      if (mounted && operation == _writeOperation) {
        final outcome = action == _NfcWriteAction.save
            ? _NfcWriteStatus.failure
            : null;
        widget.session.updateWriting(false, outcome: outcome);
        widget.session.updateStatus(
          _serviceErrorMessage(error),
          outcome: outcome,
        );
        _closeWriteDialog();
        _scrollToStatus();
        if (action == _NfcWriteAction.save) {
          await _clearWriteFailureIndicator(operation);
        } else {
          setState(() => _activeWriteAction = null);
        }
      }
    } catch (_) {
      if (mounted && operation == _writeOperation) {
        final outcome = action == _NfcWriteAction.save
            ? _NfcWriteStatus.failure
            : null;
        widget.session.updateWriting(false, outcome: outcome);
        widget.session.updateStatus(
          AppLocalizations.of(context)!.nfcWriteFailed,
          outcome: outcome,
        );
        _closeWriteDialog();
        _scrollToStatus();
        if (action == _NfcWriteAction.save) {
          await _clearWriteFailureIndicator(operation);
        } else {
          setState(() => _activeWriteAction = null);
        }
      }
    }
  }

  Future<void> _clearWriteFailureIndicator(int operation) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted && operation == _writeOperation) {
      widget.session.updateStatus(widget.session.status);
      setState(() => _activeWriteAction = null);
    }
  }

  Future<void> _cancelWrite(int operation) async {
    if (operation != _writeOperation || !widget.session.writing) {
      return;
    }
    _writeOperation++;
    widget.session.updateWriting(false);
    setState(() => _activeWriteAction = null);
    await widget.nfcTagService.cancelSession();
    if (mounted) {
      _closeWriteDialog();
    }
  }

  void _closeWriteDialog() {
    _writeDialogCanPop.value = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    });
  }

  void _scrollToStatus() {
    if (_scrollController.hasClients) {
      unawaited(
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        ),
      );
    }
  }

  String _snapshotErrorMessage(SnapshotFormatException error) {
    final l10n = AppLocalizations.of(context)!;
    return switch (error.code) {
      SnapshotErrorCode.crc => l10n.nfcCrcError,
      SnapshotErrorCode.protocol => l10n.nfcUnknownProtocol,
      SnapshotErrorCode.version => l10n.nfcUnsupportedVersion,
      SnapshotErrorCode.location => l10n.invalidLocation,
      SnapshotErrorCode.attributeTooLong ||
      SnapshotErrorCode.attributesTooLong => l10n.nfcCustomTextTooLong,
      SnapshotErrorCode.containerTooLarge => l10n.nfcPayloadTooLarge(
        '${error.bytes ?? CompBoxSnapshot.conservativeNdefLimit + 1}',
        '${CompBoxSnapshot.conservativeNdefLimit}',
      ),
      _ => l10n.nfcInvalidSnapshot,
    };
  }

  String _serviceErrorMessage(NfcTagServiceException error) {
    final l10n = AppLocalizations.of(context)!;
    return switch (error.code) {
      NfcTagServiceError.disabled => l10n.nfcDisabled,
      NfcTagServiceError.unsupported => l10n.nfcUnavailable,
      NfcTagServiceError.unsupportedTag => l10n.nfcUnsupportedTag,
      NfcTagServiceError.readOnly => l10n.nfcReadOnly,
      NfcTagServiceError.capacity => l10n.nfcCapacityError,
      NfcTagServiceError.uidMismatch => l10n.nfcUidMismatch,
      NfcTagServiceError.malformedMessage => l10n.nfcUnknownProtocol,
      NfcTagServiceError.readFailed => l10n.nfcReadFailed,
      NfcTagServiceError.writeFailed => l10n.nfcWriteFailed,
    };
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.session,
    builder: (context, _) {
      final grid = widget.session.grid;
      if (grid == null) {
        return const SizedBox.shrink();
      }
      return ListView(
        key: const Key('nfc-grid-overview-page'),
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          const _NfcPageHeading(),
          const SizedBox(height: 18),
          _NfcStatusCard(
            tagRead: true,
            scanning: false,
            writeStatus: _activeWriteAction == _NfcWriteAction.save
                ? widget.session.writeStatus
                : null,
            status: widget.session.status,
            onRescan: widget.session.writing ? null : widget.onRescan,
          ),
          const SizedBox(height: 20),
          _NfcSlotPicker(
            grid: grid,
            catalog: widget.catalog,
            languageCode: Localizations.localeOf(context).languageCode,
            enabled: !widget.session.writing,
            onSlotSelected: _openSlot,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: FilledButton(
              key: const Key('nfc-save-button'),
              onPressed: widget.session.writing ? null : _saveAll,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0878F8),
                disabledBackgroundColor: const Color(0xFFD7E1EF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Text(AppLocalizations.of(context)!.save),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: OutlinedButton(
              key: const Key('nfc-clear-tag-button'),
              onPressed: widget.session.writing ? null : _clearTag,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFB3261E),
                side: const BorderSide(color: Color(0xFFF0B8B5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Text(AppLocalizations.of(context)!.nfcClearTag),
            ),
          ),
        ],
      );
    },
  );
}

class _NfcSlotEditorPage extends StatefulWidget {
  const _NfcSlotEditorPage({
    required this.catalog,
    required this.session,
    required this.slotIndex,
  });

  final ResourceCatalog catalog;
  final _NfcDraftSession session;
  final int slotIndex;

  @override
  State<_NfcSlotEditorPage> createState() => _NfcSlotEditorPageState();
}

class _NfcSlotEditorPageState extends State<_NfcSlotEditorPage> {
  static const int _maxQuantity = 0xFFFFFFFF;
  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, String?> _enumValues = {};
  final Map<String, String> _valueUnitIds = {};
  final Map<String, String> _errors = {};
  final _locationController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  late String _categoryId;
  int _inventoryQuantity = 1;
  bool _allowPop = false;

  CategoryDefinition get _category => widget.catalog.categoryById(_categoryId);

  @override
  void initState() {
    super.initState();
    for (final category in widget.catalog.categories) {
      final categoryValue = category.nfc.value;
      if (categoryValue != null) {
        _valueUnitIds[category.id] = categoryValue.defaultUnitId;
      }
    }
    for (final field in widget.catalog.fields.values) {
      if (field.id != 'quantity' && field.type != FieldType.enumValue) {
        _textControllers[field.id] = TextEditingController();
      }
    }
    final record = widget.session.grid?.recordAt(widget.slotIndex);
    final category = record == null
        ? widget.catalog.categories.first
        : widget.catalog.categoryById(record.categoryId);
    _categoryId = category.id;
    _inventoryQuantity = record?.quantity ?? 1;
    _quantityController.text = '$_inventoryQuantity';
    _locationController.text = record?.location ?? '';
    for (final entry in _textControllers.entries) {
      final field = widget.catalog.fields[entry.key]!;
      final storedValue = record?.values[entry.key];
      final categoryValue = category.nfc.value;
      if (storedValue is num && categoryValue?.fieldId == field.id) {
        final unit = categoryValue!.preferredUnitFor(storedValue);
        _valueUnitIds[category.id] = unit.id;
        entry.value.text = categoryValue.inputValue(storedValue, unit.id);
      } else {
        entry.value.text = record == null
            ? ''
            : widget.catalog.displayValue(
                category: category,
                field: field,
                value: storedValue,
                languageCode: WidgetsBinding
                    .instance
                    .platformDispatcher
                    .locale
                    .languageCode,
              );
      }
    }
    for (final field in widget.catalog.fields.values) {
      if (field.type == FieldType.enumValue) {
        final value = record?.values[field.id];
        _enumValues[field.id] = switch (value) {
          final String id when field.optionById(id) != null => id,
          final int code => field.nfc?.dictionaryByCode(code)?.id,
          _ => null,
        };
      }
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _quantityController.dispose();
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool _stashDraft() {
    final grid = widget.session.grid;
    if (grid == null) {
      return true;
    }
    final draft = _draftRecord();
    if (draft == null) {
      return false;
    }
    widget.session.updateGrid(grid.withRecord(widget.slotIndex, draft));
    return true;
  }

  void _discardAndPop() {
    if (_allowPop) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _allowPop = true);
    Navigator.of(context).pop();
  }

  void _saveAndPop() {
    if (!_stashDraft()) {
      return;
    }
    setState(() => _allowPop = true);
    Navigator.of(context).pop();
  }

  void _changeCategory(String? categoryId) {
    if (categoryId != null) {
      setState(() {
        _categoryId = categoryId;
        _errors.clear();
      });
    }
  }

  void _changeQuantity(int change) {
    final current = int.tryParse(_quantityController.text) ?? 0;
    setState(() {
      _inventoryQuantity = (current + change).clamp(0, _maxQuantity);
      _quantityController.text = '$_inventoryQuantity';
      _errors.remove('quantity');
    });
  }

  void _changeQuantityText(String value) {
    final quantity = int.tryParse(value);
    setState(() {
      if (quantity != null && quantity >= 0 && quantity <= _maxQuantity) {
        _inventoryQuantity = quantity;
      }
      _errors.remove('quantity');
    });
  }

  ComponentRecord? _draftRecord() {
    final l10n = AppLocalizations.of(context)!;
    final errors = <String, String>{};
    final values = <String, Object?>{};
    for (final field in widget.catalog.fieldsFor(_category)) {
      if (field.id == 'quantity') {
        continue;
      }
      final value = switch (field.type) {
        FieldType.enumValue => _enumValues[field.id]?.trim() ?? '',
        FieldType.integer => int.tryParse(
          _textControllers[field.id]?.text.trim() ?? '',
        ),
        FieldType.decimal => _textControllers[field.id]?.text.trim() ?? '',
        FieldType.text => _textControllers[field.id]?.text.trim() ?? '',
      };
      final empty = value == null || (value is String && value.isEmpty);
      if (field.required && empty) {
        errors[field.id] = l10n.requiredField(
          field.label.resolve(Localizations.localeOf(context).languageCode),
        );
      } else if (field.type == FieldType.integer && !empty && value is! int) {
        errors[field.id] = l10n.invalidInteger;
      } else if (!empty) {
        final categoryValue = _category.nfc.value;
        final canonical = value is String
            ? categoryValue?.fieldId == field.id
                  ? categoryValue!.parseInput(
                      value,
                      _valueUnitIds[_category.id] ??
                          categoryValue.defaultUnitId,
                    )
                  : widget.catalog.canonicalValue(
                      category: _category,
                      field: field,
                      text: value,
                    )
            : value;
        if (canonical == null) {
          errors[field.id] = l10n.invalidNumber;
        } else {
          values[field.id] = canonical;
        }
      }
    }
    final quantity = int.tryParse(_quantityController.text.trim());
    if (quantity == null || quantity < 0 || quantity > _maxQuantity) {
      errors['quantity'] = l10n.invalidInteger;
    }
    final location = _locationController.text.trim();
    try {
      CompBoxLocation.parse(location);
    } on SnapshotFormatException {
      errors['location'] = l10n.invalidLocation;
    }
    if (errors.isNotEmpty) {
      setState(() {
        _errors
          ..clear()
          ..addAll(errors);
      });
      return null;
    }
    values['quantity'] = quantity!;
    return ComponentRecord(
      location: location,
      categoryId: _categoryId,
      values: values,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _discardAndPop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.nfcSlotLabel('${widget.slotIndex + 1}')),
        ),
        body: ListView(
          key: const Key('nfc-slot-editor-page'),
          padding: const EdgeInsets.all(16),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            _NfcEntryForm(
              enabled: true,
              catalog: widget.catalog,
              category: _category,
              categoryId: _categoryId,
              textControllers: _textControllers,
              enumValues: _enumValues,
              valueUnitId: _valueUnitIds[_category.id],
              errors: _errors,
              locationController: _locationController,
              quantityController: _quantityController,
              inventoryQuantity: _inventoryQuantity,
              onCategoryChanged: _changeCategory,
              onEnumChanged: (id, value) =>
                  setState(() => _enumValues[id] = value),
              onValueUnitChanged: (unitId) =>
                  setState(() => _valueUnitIds[_category.id] = unitId),
              onQuantityChanged: _changeQuantityText,
              onDecrease: _inventoryQuantity > 0
                  ? () => _changeQuantity(-1)
                  : null,
              onIncrease: _inventoryQuantity < _maxQuantity
                  ? () => _changeQuantity(1)
                  : null,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: FilledButton(
                key: const Key('nfc-finish-slot-button'),
                onPressed: _saveAndPop,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0878F8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text(l10n.nfcFinishEditing),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NfcSavedToastContent extends StatefulWidget {
  const _NfcSavedToastContent({required this.label});

  final String label;

  @override
  State<_NfcSavedToastContent> createState() => _NfcSavedToastContentState();
}

class _NfcSavedToastContentState extends State<_NfcSavedToastContent> {
  Timer? _animationTimer;
  bool _animating = true;

  @override
  void initState() {
    super.initState();
    _animationTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _animating = false);
      }
    });
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(widget.label)),
        const SizedBox(width: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 100),
          child: _animating
              ? RiveAnimatedIcon(
                  key: const Key('nfc-write-success-icon'),
                  riveIcon: RiveIcon.check,
                  color: Colors.white,
                  width: 28,
                  height: 28,
                  strokeWidth: 3,
                  loopAnimation: true,
                  enableAbsorbPointer: true,
                  semanticLabel: widget.label,
                )
              : const Icon(
                  key: Key('nfc-write-success-static-icon'),
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 28,
                ),
        ),
      ],
    );
  }
}

class _NfcWriteDialog extends StatelessWidget {
  const _NfcWriteDialog({
    required this.canPop,
    required this.onCancel,
    required this.title,
    required this.description,
  });

  final ValueListenable<bool> canPop;
  final VoidCallback onCancel;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ValueListenableBuilder<bool>(
      valueListenable: canPop,
      builder: (context, allowPop, _) => PopScope(
        canPop: allowPop,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            onCancel();
          }
        },
        child: Dialog(
          key: const Key('nfc-write-dialog'),
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: _NfcWriteOutcomeIndicator(
                    state: _NfcWriteStatus.writing,
                    size: 96,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    key: const Key('nfc-write-cancel-button'),
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF475467),
                      side: const BorderSide(color: Color(0xFFD0D5DD)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: Text(l10n.cancel),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NfcWriteOutcomeIndicator extends StatelessWidget {
  const _NfcWriteOutcomeIndicator({required this.state, this.size = 48});

  final _NfcWriteStatus state;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final background = switch (state) {
      _NfcWriteStatus.writing => const Color(0xFFEAF2FF),
      _NfcWriteStatus.failure => const Color(0xFFFDECEC),
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: switch (state) {
            _NfcWriteStatus.writing => RiveAnimatedIcon(
              key: Key('nfc-write-progress'),
              riveIcon: RiveIcon.reload,
              color: Color(0xFF0878F8),
              width: size >= 96 ? 54 : 30,
              height: size >= 96 ? 54 : 30,
              strokeWidth: size >= 96 ? 4 : 3,
              loopAnimation: true,
              enableAbsorbPointer: true,
              semanticLabel: l10n.nfcSaveDialogTitle,
            ),
            _NfcWriteStatus.failure => RiveAnimatedIcon(
              key: Key('nfc-write-failure-icon'),
              riveIcon: RiveIcon.cross,
              color: Color(0xFFB3261E),
              width: size >= 96 ? 54 : 30,
              height: size >= 96 ? 54 : 30,
              strokeWidth: size >= 96 ? 4 : 3,
              loopAnimation: true,
              enableAbsorbPointer: true,
              semanticLabel: l10n.nfcWriteFailed,
            ),
          },
        ),
      ),
    );
  }
}

class _NfcSlotPicker extends StatelessWidget {
  const _NfcSlotPicker({
    required this.grid,
    required this.catalog,
    required this.languageCode,
    required this.enabled,
    required this.onSlotSelected,
  });

  final CompBoxTagGrid grid;
  final ResourceCatalog catalog;
  final String languageCode;
  final bool enabled;
  final ValueChanged<int> onSlotSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.nfcSlotSelectionTitle, style: _sectionTitle),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final gap = grid.columns > 1 ? 8.0 : 0.0;
            final tileWidth =
                (constraints.maxWidth - gap * (grid.columns - 1)) /
                grid.columns;
            return Row(
              children: [
                for (final slot in grid.slots) ...[
                  if (slot.index > 0) SizedBox(width: gap),
                  SizedBox(
                    width: tileWidth,
                    height: 116,
                    child: _NfcSlotTile(
                      slot: slot,
                      catalog: catalog,
                      languageCode: languageCode,
                      enabled: enabled,
                      onPressed: () => onSlotSelected(slot.index),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _NfcSlotTile extends StatelessWidget {
  const _NfcSlotTile({
    required this.slot,
    required this.catalog,
    required this.languageCode,
    required this.enabled,
    required this.onPressed,
  });

  final CompBoxTagSlot slot;
  final ResourceCatalog catalog;
  final String languageCode;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final record = slot.record;
    final category = record == null
        ? null
        : catalog.categoryById(record.categoryId);
    final empty = record == null;
    return Semantics(
      button: true,
      label: l10n.nfcSlotLabel('${slot.index + 1}'),
      child: Material(
        color: empty ? const Color(0xFFF4F7FB) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          key: Key('nfc-slot-${slot.index}'),
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: empty
                    ? const Color(0xFFD5DFEA)
                    : const Color(0xFFB8D8FC),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.nfcSlotLabel('${slot.index + 1}'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF536176),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  empty
                      ? l10n.nfcSlotEmpty
                      : category!.name.resolve(languageCode),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: empty
                        ? const Color(0xFF748095)
                        : const Color(0xFF16181D),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (!empty) ...[
                  const SizedBox(height: 3),
                  Text(
                    record.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NfcPageHeading extends StatelessWidget {
  const _NfcPageHeading();

  @override
  Widget build(BuildContext context) {
    return Text(
      AppLocalizations.of(context)!.nfcTitle,
      key: const Key('nfc-page-title'),
      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
    );
  }
}

class _NfcStatusCard extends StatelessWidget {
  const _NfcStatusCard({
    required this.tagRead,
    required this.scanning,
    required this.writeStatus,
    required this.status,
    this.title,
    this.onRescan,
  });

  final bool tagRead;
  final bool scanning;
  final _NfcWriteStatus? writeStatus;
  final String? status;
  final String? title;
  final VoidCallback? onRescan;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final error = status != null && title == null;
    final writing = writeStatus == _NfcWriteStatus.writing;
    return Container(
      key: const Key('nfc-scan-status-card'),
      constraints: const BoxConstraints(minHeight: 118),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: error ? const Color(0xFFF0B8B5) : const Color(0xFFE7EBF1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title ??
                      (error
                          ? l10n.nfcError
                          : writing
                          ? l10n.nfcSaveDialogTitle
                          : tagRead
                          ? l10n.nfcTagRead
                          : scanning
                          ? l10n.nfcScanningTitle
                          : l10n.nfcReadyToScan),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  status ??
                      (writing
                          ? l10n.nfcSaveDialogDescription
                          : tagRead
                          ? l10n.nfcTagReadDescription
                          : l10n.nfcScanInstruction),
                  style: TextStyle(
                    color: error
                        ? const Color(0xFFB3261E)
                        : const Color(0xFF748095),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          if (writeStatus != null)
            _NfcWriteOutcomeIndicator(state: writeStatus!)
          else if (scanning)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          else if (error)
            onRescan == null
                ? const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFB3261E),
                  )
                : IconButton(
                    key: const Key('nfc-rescan-button'),
                    onPressed: onRescan,
                    tooltip: l10n.nfcRescan,
                    icon: const Icon(Icons.refresh_rounded),
                    color: const Color(0xFF0878F8),
                  )
          else if (tagRead)
            IconButton(
              key: const Key('nfc-rescan-button'),
              onPressed: onRescan,
              tooltip: l10n.nfcRescan,
              icon: const Icon(Icons.refresh_rounded),
              color: const Color(0xFF0878F8),
            )
          else
            const SizedBox(width: 20),
        ],
      ),
    );
  }
}

class _NfcEntryForm extends StatelessWidget {
  const _NfcEntryForm({
    required this.enabled,
    required this.catalog,
    required this.category,
    required this.categoryId,
    required this.textControllers,
    required this.enumValues,
    required this.valueUnitId,
    required this.errors,
    required this.locationController,
    required this.quantityController,
    required this.inventoryQuantity,
    required this.onCategoryChanged,
    required this.onEnumChanged,
    required this.onValueUnitChanged,
    required this.onQuantityChanged,
    required this.onDecrease,
    required this.onIncrease,
  });

  final bool enabled;
  final ResourceCatalog catalog;
  final CategoryDefinition category;
  final String categoryId;
  final Map<String, TextEditingController> textControllers;
  final Map<String, String?> enumValues;
  final String? valueUnitId;
  final Map<String, String> errors;
  final TextEditingController locationController;
  final TextEditingController quantityController;
  final int inventoryQuantity;
  final ValueChanged<String?> onCategoryChanged;
  final void Function(String id, String? value) onEnumChanged;
  final ValueChanged<String> onValueUnitChanged;
  final ValueChanged<String> onQuantityChanged;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE7EBF1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _NfcCategorySelector(
            enabled: enabled,
            catalog: catalog,
            categoryId: categoryId,
            onCategoryChanged: onCategoryChanged,
          ),
          for (final field in catalog.fieldsFor(category)) ...[
            if (field.id != 'quantity') const SizedBox(height: 14),
            if (field.id != 'quantity')
              _DynamicField(
                category: category,
                field: field,
                enabled: enabled,
                controller: textControllers[field.id],
                selectedOption: enumValues[field.id],
                selectedUnitId: valueUnitId,
                errorText: errors[field.id],
                onOptionChanged: (value) => onEnumChanged(field.id, value),
                onUnitChanged: onValueUnitChanged,
              ),
          ],
          const SizedBox(height: 18),
          _NfcQuantityEditor(
            enabled: enabled,
            quantity: inventoryQuantity,
            controller: quantityController,
            errorText: errors['quantity'],
            onChanged: onQuantityChanged,
            onDecrease: onDecrease,
            onIncrease: onIncrease,
          ),
          const SizedBox(height: 18),
          _NfcLocationRow(
            enabled: enabled,
            controller: locationController,
            errorText: errors['location'],
          ),
        ],
      ),
    );
  }
}

class _NfcCategorySelector extends StatelessWidget {
  const _NfcCategorySelector({
    required this.enabled,
    required this.catalog,
    required this.categoryId,
    required this.onCategoryChanged,
  });

  final bool enabled;
  final ResourceCatalog catalog;
  final String categoryId;
  final ValueChanged<String?> onCategoryChanged;

  Future<void> _showPicker(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _CategoryPickerSheet(
        catalog: catalog,
        selectedCategoryId: categoryId,
        includeAllCategories: false,
        sheetKey: const Key('nfc-category-picker-sheet'),
        optionKeyPrefix: 'nfc-category-option',
        onCategorySelected: (selectedCategoryId) {
          onCategoryChanged(selectedCategoryId);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    final selectedCategory = catalog.categoryById(categoryId);
    final borderColor = enabled
        ? const Color(0xFFB8C0CC)
        : const Color(0xFFE0E3E8);
    return Material(
      color: enabled ? Colors.white : const Color(0xFFF5F6F8),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        key: const Key('nfc-category-input'),
        borderRadius: BorderRadius.circular(8),
        onTap: enabled ? () => _showPicker(context) : null,
        child: Container(
          height: 64,
          padding: const EdgeInsets.fromLTRB(12, 7, 10, 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              ComponentThumbnail(category: selectedCategory, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.category,
                      style: const TextStyle(
                        color: Color(0xFF687487),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selectedCategory.name.resolve(languageCode),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.expand_more_rounded, color: Color(0xFF687487)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DynamicField extends StatelessWidget {
  const _DynamicField({
    required this.category,
    required this.field,
    required this.enabled,
    required this.controller,
    required this.selectedOption,
    required this.selectedUnitId,
    required this.errorText,
    required this.onOptionChanged,
    required this.onUnitChanged,
  });

  final CategoryDefinition category;
  final FieldDefinition field;
  final bool enabled;
  final TextEditingController? controller;
  final String? selectedOption;
  final String? selectedUnitId;
  final String? errorText;
  final ValueChanged<String?> onOptionChanged;
  final ValueChanged<String> onUnitChanged;

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final label = field.label.resolve(languageCode);
    final configuredValue = category.nfc.value;
    if (configuredValue?.fieldId == field.id &&
        configuredValue!.presets.isNotEmpty) {
      return _PresetValueMenu(
        categoryValue: configuredValue,
        languageCode: languageCode,
        enabled: enabled,
        controller: controller!,
        label: label,
        errorText: errorText,
        selectedUnitId: selectedUnitId ?? configuredValue.defaultUnitId,
        onUnitChanged: onUnitChanged,
      );
    }
    if (field.type == FieldType.enumValue) {
      return _EnumOptionField(
        field: field,
        languageCode: languageCode,
        label: label,
        enabled: enabled,
        selectedOption: selectedOption,
        errorText: errorText,
        onChanged: onOptionChanged,
      );
    }
    return TextFormField(
      key: Key('nfc-field-${field.id}'),
      controller: controller,
      enabled: enabled,
      keyboardType: field.type == FieldType.integer
          ? TextInputType.number
          : field.type == FieldType.decimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : null,
      inputFormatters: field.type == FieldType.integer
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      decoration: _formDecoration(label, errorText),
    );
  }
}

class _EnumOptionField extends StatelessWidget {
  const _EnumOptionField({
    required this.field,
    required this.languageCode,
    required this.label,
    required this.enabled,
    required this.selectedOption,
    required this.errorText,
    required this.onChanged,
  });

  final FieldDefinition field;
  final String languageCode;
  final String label;
  final bool enabled;
  final String? selectedOption;
  final String? errorText;
  final ValueChanged<String?> onChanged;

  Future<void> _showPicker(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _EnumOptionPickerSheet(
        field: field,
        languageCode: languageCode,
        selectedOption: selectedOption,
        onSelected: (optionId) {
          onChanged(optionId);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedLabel = selectedOption == null
        ? ''
        : field.optionById(selectedOption!)?.label.resolve(languageCode) ?? '';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('nfc-field-${field.id}'),
        borderRadius: BorderRadius.circular(8),
        onTap: enabled ? () => _showPicker(context) : null,
        child: InputDecorator(
          isEmpty: selectedLabel.isEmpty,
          decoration: _formDecoration(label, errorText).copyWith(
            enabled: enabled,
            filled: !enabled,
            fillColor: enabled ? null : const Color(0xFFF5F6F8),
            suffixIcon: const Icon(
              Icons.expand_more_rounded,
              color: Color(0xFF687487),
            ),
          ),
          child: Text(
            selectedLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}

class _EnumOptionPickerSheet extends StatelessWidget {
  const _EnumOptionPickerSheet({
    required this.field,
    required this.languageCode,
    required this.selectedOption,
    required this.onSelected,
  });

  final FieldDefinition field;
  final String languageCode;
  final String? selectedOption;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        key: Key('nfc-field-${field.id}-picker-sheet'),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .72,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFD6DAE1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  field.label.resolve(languageCode),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFEDF0F4)),
            Flexible(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shrinkWrap: true,
                children: [
                  for (final option in field.options)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: Key('nfc-field-${field.id}-option-${option.id}'),
                        onTap: () => onSelected(option.id),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  option.label.resolve(languageCode),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: selectedOption == option.id
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (selectedOption == option.id)
                                const Icon(
                                  Icons.check_rounded,
                                  color: Color(0xFF0878F8),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetValueMenu extends StatefulWidget {
  const _PresetValueMenu({
    required this.categoryValue,
    required this.languageCode,
    required this.enabled,
    required this.controller,
    required this.label,
    required this.errorText,
    required this.selectedUnitId,
    required this.onUnitChanged,
  });

  final NfcValueDefinition categoryValue;
  final String languageCode;
  final bool enabled;
  final TextEditingController controller;
  final String label;
  final String? errorText;
  final String selectedUnitId;
  final ValueChanged<String> onUnitChanged;

  @override
  State<_PresetValueMenu> createState() => _PresetValueMenuState();
}

class _PresetValueMenuState extends State<_PresetValueMenu> {
  final _focusNode = FocusNode();

  void _changeUnit(String unitId) {
    final value = widget.categoryValue.parseInput(
      widget.controller.text,
      widget.selectedUnitId,
    );
    if (value != null) {
      final text = widget.categoryValue.inputValue(value, unitId);
      widget.controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
    widget.onUnitChanged(unitId);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<ValuePreset>(
      textEditingController: widget.controller,
      focusNode: _focusNode,
      displayStringForOption: (preset) =>
          widget.categoryValue.inputValue(preset.value, widget.selectedUnitId),
      optionsBuilder: (editingValue) => widget.categoryValue.matchingPresets(
        editingValue.text,
        unitId: widget.selectedUnitId,
      ),
      onSelected: (preset) {
        final text = widget.categoryValue.inputValue(
          preset.value,
          widget.selectedUnitId,
        );
        widget.controller.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) =>
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  key: const Key('nfc-field-value'),
                  controller: controller,
                  focusNode: focusNode,
                  enabled: widget.enabled,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onFieldSubmitted: (_) => onFieldSubmitted(),
                  decoration: _formDecoration(widget.label, widget.errorText),
                ),
              ),
              const SizedBox(width: 10),
              _ValueUnitSelector(
                categoryValue: widget.categoryValue,
                languageCode: widget.languageCode,
                enabled: widget.enabled,
                selectedUnitId: widget.selectedUnitId,
                onChanged: _changeUnit,
              ),
            ],
          ),
      optionsViewBuilder: (context, onSelected, options) {
        final matches = options.toList(growable: false);
        final menuHeight = matches.length >= 7 ? 320.0 : matches.length * 48.0;
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: menuHeight,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: matches.length,
                itemExtent: 48,
                itemBuilder: (context, index) {
                  final preset = matches[index];
                  return ListTile(
                    dense: true,
                    title: Text(
                      widget.categoryValue.displayValue(
                        preset.value,
                        widget.selectedUnitId,
                      ),
                    ),
                    onTap: () => onSelected(preset),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ValueUnitSelector extends StatelessWidget {
  const _ValueUnitSelector({
    required this.categoryValue,
    required this.languageCode,
    required this.enabled,
    required this.selectedUnitId,
    required this.onChanged,
  });

  final NfcValueDefinition categoryValue;
  final String languageCode;
  final bool enabled;
  final String selectedUnitId;
  final ValueChanged<String> onChanged;

  Future<void> _showPicker(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ValueUnitPickerSheet(
        categoryValue: categoryValue,
        languageCode: languageCode,
        selectedUnitId: selectedUnitId,
        onSelected: (unitId) {
          onChanged(unitId);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedUnit =
        categoryValue.unitById(selectedUnitId) ?? categoryValue.defaultUnit;
    return SizedBox(
      width: 88,
      height: 56,
      child: OutlinedButton(
        key: Key('nfc-field-${categoryValue.fieldId}-unit'),
        onPressed: enabled ? () => _showPicker(context) : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF24272D),
          side: const BorderSide(color: Color(0xFFB8C0CC)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                selectedUnit.symbol,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.expand_more_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

class _ValueUnitPickerSheet extends StatelessWidget {
  const _ValueUnitPickerSheet({
    required this.categoryValue,
    required this.languageCode,
    required this.selectedUnitId,
    required this.onSelected,
  });

  final NfcValueDefinition categoryValue;
  final String languageCode;
  final String selectedUnitId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        key: Key('nfc-field-${categoryValue.fieldId}-unit-picker-sheet'),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFD6DAE1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            for (final unit in categoryValue.units)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  key: Key(
                    'nfc-field-${categoryValue.fieldId}-unit-option-${unit.id}',
                  ),
                  onTap: () => onSelected(unit.id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 56,
                          child: Text(
                            unit.symbol,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            unit.label.resolve(languageCode),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        if (unit.id == selectedUnitId)
                          const Icon(
                            Icons.check_rounded,
                            color: Color(0xFF0878F8),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

InputDecoration _formDecoration(String label, String? errorText) =>
    InputDecoration(
      labelText: label,
      errorText: errorText,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF0878F8), width: 1.4),
      ),
    );

class _NfcQuantityEditor extends StatelessWidget {
  const _NfcQuantityEditor({
    required this.enabled,
    required this.quantity,
    required this.controller,
    required this.errorText,
    required this.onChanged,
    required this.onDecrease,
    required this.onIncrease,
  });

  final bool enabled;
  final int quantity;
  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String> onChanged;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.inventory,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE1E6EE)),
            ),
            child: Row(
              children: [
                Tooltip(
                  message: l10n.decreaseQuantity,
                  child: IconButton(
                    key: const Key('nfc-quantity-decrease'),
                    onPressed: enabled ? onDecrease : null,
                    icon: const Icon(Icons.remove_rounded),
                  ),
                ),
                Expanded(
                  child: TextField(
                    key: const Key('nfc-quantity-input'),
                    controller: controller,
                    enabled: enabled,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.center,
                    onChanged: onChanged,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
                Tooltip(
                  message: l10n.increaseQuantity,
                  child: IconButton(
                    key: const Key('nfc-quantity-increase'),
                    onPressed: enabled ? onIncrease : null,
                    icon: const Icon(Icons.add_rounded),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              errorText!,
              style: const TextStyle(color: Color(0xFFB3261E), fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class _NfcLocationRow extends StatelessWidget {
  const _NfcLocationRow({
    required this.enabled,
    required this.controller,
    required this.errorText,
  });

  final bool enabled;
  final TextEditingController controller;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      key: const Key('nfc-location'),
      controller: controller,
      enabled: enabled,
      textCapitalization: TextCapitalization.characters,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9-]')),
      ],
      decoration: _formDecoration(
        l10n.location,
        errorText,
      ).copyWith(suffixIcon: const Icon(Icons.location_on_outlined)),
    );
  }
}

class ComponentDetailPage extends StatelessWidget {
  const ComponentDetailPage({
    super.key,
    required this.catalog,
    required this.record,
  });

  final ResourceCatalog catalog;
  final ComponentRecord record;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final category = catalog.categoryById(record.categoryId);
    final languageCode = Localizations.localeOf(context).languageCode;
    final fields = catalog
        .fieldsFor(category)
        .where((field) => field.id != 'quantity');
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.componentDetail,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: OutlinedButton.icon(
            key: const Key('component-detail-delete-button'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              foregroundColor: const Color(0xFFC62828),
              side: const BorderSide(color: Color(0xFFC62828)),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete_outline),
            label: Text(l10n.delete),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                Row(
                  children: [
                    ComponentThumbnail(category: category, size: 88),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _recordName(record, category, languageCode),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            category.name.resolve(languageCode),
                            style: const TextStyle(
                              color: Color(0xFF6F798A),
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 34),
                Text(l10n.inventoryInformation, style: _sectionTitle),
                const SizedBox(height: 10),
                _DetailPanel(
                  children: [
                    _DetailRow(label: l10n.location, value: record.location),
                    _DetailRow(
                      label: l10n.currentQuantity,
                      value: _quantityLabel(context, record.quantity),
                    ),
                    _DetailRow(
                      label: l10n.category,
                      value: category.name.resolve(languageCode),
                      isLast: true,
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(l10n.specificationInformation, style: _sectionTitle),
                const SizedBox(height: 10),
                _DetailPanel(
                  children: [
                    for (var index = 0; index < fields.length; index++)
                      _DetailRow(
                        label: fields
                            .elementAt(index)
                            .label
                            .resolve(languageCode),
                        value: _displayFieldValue(
                          category,
                          fields.elementAt(index),
                          record.values,
                          languageCode,
                        ),
                        isLast: index == fields.length - 1,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const _sectionTitle = TextStyle(fontSize: 18, fontWeight: FontWeight.w700);

class _DetailPanel extends StatelessWidget {
  const _DetailPanel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE9ECF0)),
      ),
      child: Column(children: children),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFEFF1F4))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF7B8594), fontSize: 15),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15.5, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage({
    required this.catalog,
    required this.records,
    required this.backupFileService,
    required this.onImportDatabase,
    required this.onClearDatabase,
  });

  final ResourceCatalog catalog;
  final List<ComponentRecord> records;
  final ComponentBackupFileService backupFileService;
  final ValueChanged<List<ComponentRecord>> onImportDatabase;
  final VoidCallback onClearDatabase;

  Future<void> _exportDatabase(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    try {
      final exported = await backupFileService.exportBackup(
        contents: ComponentBackup(exportedAt: now, records: records).encode(),
        fileName: componentBackupFileName(now),
      );
      if (exported && context.mounted) {
        _showMessage(context, l10n.exportDatabaseSuccess('${records.length}'));
      }
    } catch (_) {
      if (context.mounted) {
        _showMessage(context, l10n.exportDatabaseFailed, error: true);
      }
    }
  }

  Future<void> _importDatabase(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    ComponentBackup backup;
    try {
      final contents = await backupFileService.importBackup();
      if (contents == null || !context.mounted) {
        return;
      }
      backup = ComponentBackup.decode(contents, catalog: catalog);
    } on FormatException {
      if (context.mounted) {
        _showMessage(context, l10n.invalidBackupFile, error: true);
      }
      return;
    } catch (_) {
      if (context.mounted) {
        _showMessage(context, l10n.importDatabaseFailed, error: true);
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('import-database-confirmation'),
        title: Text(l10n.importDatabase),
        content: Text(
          l10n.importDatabaseConfirmation('${backup.records.length}'),
        ),
        actions: [
          TextButton(
            key: const Key('import-database-cancel-button'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const Key('import-database-confirm-button'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.confirmImportDatabase),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    try {
      onImportDatabase(backup.records);
      _showMessage(
        context,
        l10n.importDatabaseSuccess('${backup.records.length}'),
      );
    } catch (_) {
      _showMessage(context, l10n.importDatabaseFailed, error: true);
    }
  }

  void _showMessage(
    BuildContext context,
    String message, {
    bool error = false,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: error
              ? const Color(0xFFC62828)
              : const Color(0xFF1B7F3B),
          content: Text(message),
        ),
      );
  }

  Future<void> _clearDatabase(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          key: const Key('clear-database-confirmation'),
          title: Text(l10n.clearDatabase),
          content: Text(l10n.clearDatabaseConfirmation),
          actions: [
            TextButton(
              key: const Key('clear-database-cancel-button'),
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              key: const Key('clear-database-confirm-button'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC62828),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.confirmClearDatabase),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) {
      return;
    }

    onClearDatabase();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1B7F3B),
          content: Text(AppLocalizations.of(context)!.clearDatabaseSuccess),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.only(top: 20, bottom: 28),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            l10n.profileTitle,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 28),
        Container(
          key: const Key('export-database-card'),
          child: _SettingsActionRow(
            key: const Key('export-database-button'),
            icon: Icons.ios_share_rounded,
            title: l10n.exportDatabase,
            onTap: () => _exportDatabase(context),
          ),
        ),
        Container(
          key: const Key('import-database-card'),
          child: _SettingsActionRow(
            key: const Key('import-database-button'),
            icon: Icons.file_download_outlined,
            title: l10n.importDatabase,
            onTap: () => _importDatabase(context),
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFE9ECF0)),
        _SettingsActionRow(
          key: const Key('clear-database-button'),
          icon: Icons.delete_outline,
          title: l10n.clearDatabase,
          color: const Color(0xFFC62828),
          onTap: () => _clearDatabase(context),
        ),
      ],
    );
  }
}

class _SettingsActionRow extends StatelessWidget {
  const _SettingsActionRow({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.color = const Color(0xFF0878F8),
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 20, 16),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 24),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: color == const Color(0xFFC62828) ? color : null,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _recordName(
  ComponentRecord record,
  CategoryDefinition category,
  String languageCode,
) {
  final name = _stringValue(record, 'name');
  if (name.isNotEmpty) {
    return name;
  }
  final value = _stringValue(record, category.nfc.value?.fieldId ?? 'value');
  if (value.isEmpty) {
    return category.name.resolve(languageCode);
  }
  final displayValue =
      category.nfc.value?.dictionaryById(value)?.label.resolve(languageCode) ??
      value;
  return '$displayValue ${category.name.resolve(languageCode)}';
}

String _stringValue(ComponentRecord record, String key) =>
    record.values[key]?.toString() ?? '';

String _displayFieldValue(
  CategoryDefinition category,
  FieldDefinition field,
  Map<String, Object?> values,
  String languageCode,
) {
  final value = values[field.id];
  if (value == null) {
    return '—';
  }
  if (value is String && category.nfc.value?.fieldId == field.id) {
    return category.nfc.value!
            .dictionaryById(value)
            ?.label
            .resolve(languageCode) ??
        value;
  }
  if (field.type == FieldType.enumValue && value is String) {
    return field.optionById(value)?.label.resolve(languageCode) ?? value;
  }
  if (value is int) {
    return field.nfc?.dictionaryByCode(value)?.label.resolve(languageCode) ??
        value.toString();
  }
  if (value is String) {
    return field.nfc?.dictionaryById(value)?.label.resolve(languageCode) ??
        value;
  }
  return value.toString();
}

String _formattedNumber(BuildContext context, int number) =>
    intl.NumberFormat.decimalPattern(Localizations.localeOf(context).toString())
        .format(number);

String _quantityLabel(BuildContext context, int quantity) =>
    AppLocalizations.of(context)!
        .quantityValue(_formattedNumber(context, quantity));

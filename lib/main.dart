import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;

import 'l10n/app_localizations.dart';

void main() {
  runApp(const CompBoxApp());
}

class CompBoxApp extends StatelessWidget {
  const CompBoxApp({super.key, this.locale});

  final Locale? locale;

  @override
  Widget build(BuildContext context) {
    const colorScheme = ColorScheme.light(
      primary: Color(0xFF0878F8),
      onPrimary: Colors.white,
      surface: Colors.white,
      onSurface: Color(0xFF16181D),
    );

    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      locale: locale,
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
      home: const CompBoxHome(),
    );
  }
}

class ComponentItem {
  const ComponentItem({
    required this.id,
    required this.manufacturerModel,
    required this.location,
    required this.quantity,
    required this.category,
  });

  final String id;
  final String manufacturerModel;
  final String location;
  final int quantity;
  final ComponentCategory category;

  String name(AppLocalizations l10n) => switch (category) {
    ComponentCategory.resistor => l10n.nameResistor,
    ComponentCategory.capacitor => l10n.nameCapacitor,
    ComponentCategory.diode => l10n.nameDiode,
    ComponentCategory.inductor => l10n.nameInductor,
    ComponentCategory.timer => l10n.nameTimer,
    ComponentCategory.connector => l10n.nameConnector,
    ComponentCategory.led => l10n.nameLed,
  };

  String specification(AppLocalizations l10n) => switch (category) {
    ComponentCategory.resistor => l10n.specResistor,
    ComponentCategory.capacitor => l10n.specCapacitor,
    ComponentCategory.diode => l10n.specDiode,
    ComponentCategory.inductor => l10n.specInductor,
    ComponentCategory.timer => l10n.specTimer,
    ComponentCategory.connector => l10n.specConnector,
    ComponentCategory.led => l10n.specLed,
  };
}

enum ComponentCategory {
  resistor,
  capacitor,
  diode,
  inductor,
  timer,
  connector,
  led,
}

const demoComponents = <ComponentItem>[
  ComponentItem(
    id: 'resistor-10k',
    manufacturerModel: 'YAGEO MFR-25FBF52-103K',
    location: 'A-01-03',
    quantity: 1280,
    category: ComponentCategory.resistor,
  ),
  ComponentItem(
    id: 'capacitor-100nf',
    manufacturerModel: 'TDK C1608X7R1H104K080AA',
    location: 'A-02-01',
    quantity: 560,
    category: ComponentCategory.capacitor,
  ),
  ComponentItem(
    id: 'diode-1n4148',
    manufacturerModel: 'ON Semiconductor',
    location: 'B-01-05',
    quantity: 780,
    category: ComponentCategory.diode,
  ),
  ComponentItem(
    id: 'inductor-22uh',
    manufacturerModel: 'Coilcraft MSS1206-223MLB',
    location: 'C-03-02',
    quantity: 320,
    category: ComponentCategory.inductor,
  ),
  ComponentItem(
    id: 'timer-ne555',
    manufacturerModel: 'Texas Instruments NE555DR',
    location: 'D-01-04',
    quantity: 210,
    category: ComponentCategory.timer,
  ),
  ComponentItem(
    id: 'connector-usb-c',
    manufacturerModel: 'HRO TYPE-C-16PIN-CH',
    location: 'E-02-01',
    quantity: 96,
    category: ComponentCategory.connector,
  ),
  ComponentItem(
    id: 'led-blue-5mm',
    manufacturerModel: 'Kingbright L-53ID',
    location: 'F-04-03',
    quantity: 450,
    category: ComponentCategory.led,
  ),
];

class CompBoxHome extends StatefulWidget {
  const CompBoxHome({super.key});

  @override
  State<CompBoxHome> createState() => _CompBoxHomeState();
}

class _CompBoxHomeState extends State<CompBoxHome> {
  final _searchController = TextEditingController();
  int _selectedTab = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ComponentItem> _filteredComponents(AppLocalizations l10n) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return demoComponents;
    }
    return demoComponents.where((component) {
      return component.name(l10n).toLowerCase().contains(query) ||
          component.manufacturerModel.toLowerCase().contains(query) ||
          component.location.toLowerCase().contains(query);
    }).toList();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
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
                child: _selectedTab == 0
                    ? _InventoryPage(
                        searchController: _searchController,
                        components: _filteredComponents(l10n),
                        onSearchChanged: (_) => setState(() {}),
                        onScanPressed: () => _showMessage(l10n.scanInProgress),
                        onComponentPressed: (component) {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  ComponentDetailPage(component: component),
                            ),
                          );
                        },
                      )
                    : const _ProfilePage(),
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
            onProfilePressed: () => setState(() => _selectedTab = 1),
            onNfcPressed: () => _showMessage(l10n.nfcPreparing),
          ),
        ),
      ),
    );
  }
}

class _InventoryPage extends StatelessWidget {
  const _InventoryPage({
    required this.searchController,
    required this.components,
    required this.onSearchChanged,
    required this.onScanPressed,
    required this.onComponentPressed,
  });

  final TextEditingController searchController;
  final List<ComponentItem> components;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onScanPressed;
  final ValueChanged<ComponentItem> onComponentPressed;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      key: const Key('inventory-list'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: components.length + 3,
      itemBuilder: (context, index) {
        if (index == 0) {
          return const _HomeHeading();
        }
        if (index == 1) {
          return _SearchField(
            controller: searchController,
            onChanged: onSearchChanged,
            onScanPressed: onScanPressed,
          );
        }
        if (index == 2) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(2, 22, 0, 12),
            child: Text(
              AppLocalizations.of(context)!.myComponents,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          );
        }

        final component = components[index - 3];
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: ComponentCard(
            component: component,
            onPressed: () => onComponentPressed(component),
          ),
        );
      },
    );
  }
}

class _HomeHeading extends StatelessWidget {
  const _HomeHeading();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.homeTitle,
              style: const TextStyle(
                color: Color(0xFF121419),
                fontSize: 28,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFEFF3F7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_circle_rounded,
              color: Color(0xFF7D8798),
              size: 34,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onScanPressed,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onScanPressed;

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
            size: 24,
          ),
          suffixIcon: IconButton(
            key: const Key('scan-button'),
            tooltip: AppLocalizations.of(context)!.scanTooltip,
            onPressed: onScanPressed,
            icon: const Icon(
              Icons.qr_code_scanner_rounded,
              color: Color(0xFF0878F8),
              size: 23,
            ),
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
    required this.component,
    required this.onPressed,
  });

  final ComponentItem component;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        key: Key('component-${component.id}'),
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Container(
          height: 78,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEFF1F4)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              ComponentThumbnail(category: component.category, size: 54),
              const SizedBox(width: 9),
              Expanded(child: _ComponentOverview(component: component)),
              const SizedBox(width: 5),
              _InventorySummary(component: component),
              const SizedBox(width: 1),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF9AA4B5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ComponentThumbnail extends StatelessWidget {
  const ComponentThumbnail({super.key, required this.category, this.size = 70});

  final ComponentCategory category;
  final double size;

  IconData get _icon => switch (category) {
    ComponentCategory.resistor => Icons.linear_scale_rounded,
    ComponentCategory.capacitor => Icons.crop_square_rounded,
    ComponentCategory.diode => Icons.arrow_forward_rounded,
    ComponentCategory.inductor => Icons.all_inclusive_rounded,
    ComponentCategory.timer => Icons.memory_rounded,
    ComponentCategory.connector => Icons.settings_input_component_rounded,
    ComponentCategory.led => Icons.lightbulb_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8EBEF)),
      ),
      alignment: Alignment.center,
      child: Icon(_icon, size: size * .42, color: const Color(0xFF8992A1)),
    );
  }
}

class _ComponentOverview extends StatelessWidget {
  const _ComponentOverview({required this.component});

  final ComponentItem component;

  @override
  Widget build(BuildContext context) {
    const secondary = TextStyle(
      color: Color(0xFF717B8D),
      fontSize: 11.5,
      height: 1.2,
    );
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          component.name(l10n),
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
          component.specification(l10n),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: secondary,
        ),
        Text(
          component.manufacturerModel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: secondary,
        ),
      ],
    );
  }
}

class _InventorySummary extends StatelessWidget {
  const _InventorySummary({required this.component});

  final ComponentItem component;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: 68,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.location,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF8D96A5),
              fontSize: 10,
              height: 1,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            component.location,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13.5, height: 1),
          ),
          const SizedBox(height: 3),
          Text(
            l10n.quantity,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF8D96A5),
              fontSize: 10,
              height: 1,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            _quantityLabel(context, component.quantity),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13.5, height: 1),
          ),
        ],
      ),
    );
  }
}

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
                    icon: Icons.person_outline_rounded,
                    label: AppLocalizations.of(context)!.profile,
                    selected: selectedIndex == 1,
                    selectedColor: selectedColor,
                    onPressed: onProfilePressed,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 5,
            child: Semantics(
              button: true,
              label: AppLocalizations.of(context)!.nfcScan,
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
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
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
      child: Padding(
        padding: const EdgeInsets.only(top: 13, bottom: 7),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(icon, color: color, size: 23),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ComponentDetailPage extends StatelessWidget {
  const ComponentDetailPage({super.key, required this.component});

  final ComponentItem component;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.componentDetail,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxContentWidth = constraints.maxWidth >= 700
                ? 600.0
                : double.infinity;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  children: [
                    Row(
                      children: [
                        ComponentThumbnail(
                          category: component.category,
                          size: 88,
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                component.name(l10n),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                component.specification(l10n),
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
                    Text(
                      l10n.inventoryInformation,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _DetailPanel(
                      children: [
                        _DetailRow(
                          label: l10n.location,
                          value: component.location,
                        ),
                        _DetailRow(
                          label: l10n.currentQuantity,
                          value: _quantityLabel(context, component.quantity),
                        ),
                        _DetailRow(
                          label: l10n.category,
                          value: _categoryName(l10n, component.category),
                          isLast: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text(
                      l10n.specificationInformation,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _DetailPanel(
                      children: [
                        _DetailRow(
                          label: l10n.specificationInformation,
                          value: component.specification(l10n),
                        ),
                        _DetailRow(
                          label: l10n.manufacturerModel,
                          value: component.manufacturerModel,
                          isLast: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

String _quantityLabel(BuildContext context, int quantity) {
  final l10n = AppLocalizations.of(context)!;
  final locale = Localizations.localeOf(context).toString();
  return l10n.quantityValue(
    intl.NumberFormat.decimalPattern(locale).format(quantity),
  );
}

String _categoryName(AppLocalizations l10n, ComponentCategory category) =>
    switch (category) {
      ComponentCategory.resistor => l10n.categoryResistor,
      ComponentCategory.capacitor => l10n.categoryCapacitor,
      ComponentCategory.diode => l10n.categoryDiode,
      ComponentCategory.inductor => l10n.categoryInductor,
      ComponentCategory.timer => l10n.categoryTimer,
      ComponentCategory.connector => l10n.categoryConnector,
      ComponentCategory.led => l10n.categoryLed,
    };

class _DetailPanel extends StatelessWidget {
  const _DetailPanel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            width: 92,
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
  const _ProfilePage();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        Text(
          l10n.profileTitle,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF2FE),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                l10n.profileMonogram,
                style: const TextStyle(
                  color: Color(0xFF0878F8),
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.prototypeAccount,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    l10n.prototypeOnly,
                    style: const TextStyle(
                      color: Color(0xFF778193),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 34),
        Text(
          l10n.inventoryOverview,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        _ProfileStats(l10n: l10n),
        const SizedBox(height: 34),
        Text(
          l10n.settings,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        _ProfileAction(
          icon: Icons.settings_outlined,
          label: l10n.preferences,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.settingsInProgress),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ProfileStats extends StatelessWidget {
  const _ProfileStats({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECF0)),
      ),
      child: Row(
        children: [
          _Stat(value: '7', label: l10n.componentStat),
          _Stat(value: '3,696', label: l10n.stockTotal, withDivider: true),
          _Stat(value: '6', label: l10n.locationStat, withDivider: true),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.label,
    this.withDivider = false,
  });

  final String value;
  final String label;
  final bool withDivider;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: withDivider
              ? const Border(left: BorderSide(color: Color(0xFFEDF0F4)))
              : null,
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: const TextStyle(color: Color(0xFF7B8595), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE9ECF0)),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF6F7988)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF98A1B0)),
            ],
          ),
        ),
      ),
    );
  }
}

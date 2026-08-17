import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comp_box/main.dart';

void main() {
  testWidgets('首页展示标题、元器件与默认导航状态', (tester) async {
    await tester.pumpWidget(const CompBoxApp(locale: Locale('zh')));

    expect(find.text('芯盒'), findsOneWidget);
    expect(find.text('10kΩ 电阻'), findsOneWidget);
    expect(find.text('我的元器件'), findsOneWidget);
    expect(find.text('首页'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);
  });

  testWidgets('搜索按名称、型号和库位过滤元器件', (tester) async {
    await tester.pumpWidget(const CompBoxApp(locale: Locale('zh')));

    await tester.enterText(find.byKey(const Key('component-search')), 'NE555');
    await tester.pump();
    expect(find.text('NE555 定时器'), findsOneWidget);
    expect(find.text('10kΩ 电阻'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('component-search')),
      'E-02-01',
    );
    await tester.pump();
    expect(find.text('USB-C 连接器'), findsOneWidget);
    expect(find.text('NE555 定时器'), findsNothing);
  });

  testWidgets('点击元器件打开详情页', (tester) async {
    await tester.pumpWidget(const CompBoxApp(locale: Locale('zh')));

    await tester.tap(find.byKey(const Key('component-resistor-10k')));
    await tester.pumpAndSettle();

    expect(find.text('元器件详情'), findsOneWidget);
    expect(find.text('YAGEO MFR-25FBF52-103K'), findsOneWidget);
  });

  testWidgets('底部导航可切换到我的页面', (tester) async {
    await tester.pumpWidget(const CompBoxApp(locale: Locale('zh')));

    await tester.tap(find.byKey(const Key('profile-tab')));
    await tester.pumpAndSettle();

    expect(find.text('芯盒 设计账号'), findsOneWidget);
    expect(find.text('设计期数据，仅作原型演示'), findsOneWidget);
  });

  testWidgets('扫码和 NFC 操作展示本地反馈', (tester) async {
    await tester.pumpWidget(const CompBoxApp(locale: Locale('zh')));

    await tester.tap(find.byKey(const Key('scan-button')));
    await tester.pump();
    expect(find.text('扫码功能设计中'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nfc-button')));
    await tester.pump();
    expect(find.text('正在准备 NFC 扫描'), findsOneWidget);
  });

  testWidgets('英文区域设置显示英文应用文案', (tester) async {
    await tester.pumpWidget(const CompBoxApp(locale: Locale('en')));

    expect(find.text('CompBox'), findsOneWidget);
    expect(find.text('10 kΩ resistor'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}

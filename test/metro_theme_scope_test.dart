import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metro_ui/animations.dart';
import 'package:metro_ui/app.dart';
import 'package:metro_ui/application_bar.dart';
import 'package:metro_ui/metro_theme.dart';
import 'package:metro_ui/widgets/toggle_switch.dart';

void main() {
  testWidgets('MetroApp respects a supplied high contrast color scheme', (
    tester,
  ) async {
    const marker = Key('custom high contrast');
    await tester.pumpWidget(
      MetroApp(
        themeMode: MetroThemeMode.light,
        highContrast: true,
        highContrastTheme: ThemeData(
          colorScheme: const ColorScheme.light(primary: Colors.purple),
        ),
        home: const SizedBox(key: marker),
      ),
    );
    final context = tester.element(find.byKey(marker));
    expect(MetroSystemThemeData.of(context).highContrast, isTrue);
    expect(Theme.of(context).colorScheme.primary, Colors.purple);
  });
  testWidgets('Material host supports independent version and color scopes', (
    tester,
  ) async {
    const outer = Key('outer theme');
    const inner = Key('inner theme');
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: MetroTheme(
          data: const MetroThemeData.fromPreset(
            version: MetroDesignVersion.wp81,
          ),
          child: Column(
            children: [
              const SizedBox(key: outer),
              MetroTheme(
                data: const MetroThemeData.fromPreset(
                  version: MetroDesignVersion.wp7,
                  brightness: Brightness.dark,
                  highContrast: true,
                  accentColor: Colors.orange,
                  extensions: [MetroAppBarTheme(buttonColor: Colors.teal)],
                ),
                child: ToggleSwitchBase(
                  key: inner,
                  value: true,
                  onChanged: (_) {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final local = tester.element(find.byKey(inner));
    final parent = tester.element(find.byKey(outer));
    expect(MetroSystemThemeData.of(local).version, MetroDesignVersion.wp7);
    expect(MetroSystemThemeData.of(local).highContrast, isTrue);
    expect(Theme.of(local).brightness, Brightness.dark);
    expect(Theme.of(local).colorScheme.primary, Colors.orange);
    final bar = Theme.of(local).extension<MetroAppBarTheme>()!;
    expect(bar.expandCurve, isA<UixEaseIn>());
    expect(bar.buttonColor, Colors.teal);
    expect(MetroSystemThemeData.of(parent).version, MetroDesignVersion.wp81);
    expect(Theme.of(parent).brightness, Brightness.light);
  });

  testWidgets('a global WP8 app can host a single WP7 bar', (tester) async {
    final controller = MetroAppBarController();
    controller.setAppBar(
      const MetroApplicationBar(
        theme: MetroThemeData.fromPreset(
          version: MetroDesignVersion.wp7,
          accentColor: Colors.orange,
        ),
        buttons: [MetroAppBarButton(icon: Icon(Icons.call), label: 'Call')],
      ),
      owner: Object(),
    );
    await tester.pumpWidget(
      MetroApp(
        version: MetroDesignVersion.wp8,
        home: Align(
          alignment: Alignment.bottomCenter,
          child: MetroApplicationBarOverlay(controller: controller),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final item = tester.element(find.byType(MetroAppBarButton));
    expect(MetroSystemThemeData.of(item).version, MetroDesignVersion.wp7);
    expect(Theme.of(item).colorScheme.primary, Colors.orange);
    controller.beginNavigation(continuous: false);
    expect(controller.currentBar, isNotNull);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });
}

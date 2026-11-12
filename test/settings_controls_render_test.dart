import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metro_ui/widgets/list_item.dart';
import 'package:metro_ui/uix_typography.dart';
import 'package:metro_ui/widgets/toggle_switch.dart';

void main() {
  testWidgets('render source-sized settings controls in both themes', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final loader = FontLoader('Segoe WP');
    for (final file in ['SegoeWP-Light.ttf', 'SegoeWP.ttf']) {
      loader.addFont(
        Future.value(
          ByteData.sublistView(File('fonts/$file').readAsBytesSync()),
        ),
      );
    }
    await loader.load();
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: key,
          child: Row(
            children: [
              for (final brightness in Brightness.values)
                Expanded(
                  child: Theme(
                    data: ThemeData(
                      brightness: brightness,
                      fontFamily: 'Segoe WP',
                      typography: uixTypography(Typography.material2021()),
                      colorScheme:
                          ColorScheme.fromSeed(
                            seedColor: Colors.blue,
                            brightness: brightness,
                          ).copyWith(
                            onSurface: brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                    ),
                    child: Material(
                      color: brightness == Brightness.dark
                          ? Colors.black
                          : Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 19.2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DoubleLineListItem(
                              headerText: 'Wi-Fi',
                              subHeaderText: 'connected',
                              onTap: () {},
                            ),
                            SingleLineListItem(
                              headerText: 'about',
                              onTap: () {},
                            ),
                            ToggleSwitch(
                              value: true,
                              label: 'Wi-Fi networking',
                              description: 'Connect to available networks.',
                              onChanged: (_) {},
                            ),
                            ToggleSwitch(
                              value: false,
                              label: 'Automatic brightness',
                              onChanged: (_) {},
                            ),
                            const ToggleSwitch(
                              value: true,
                              label: 'Disabled setting',
                              description: 'This setting is unavailable.',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('/private/tmp/wp-settings-controls-preview.png')
          .writeAsBytes(png!.buffer.asUint8List());
      image.dispose();
    });
  });
}

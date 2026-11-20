import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metro_ui/app.dart';
import 'package:metro_ui/metro_theme.dart';
import 'package:metro_ui/uix_metrics.dart';
import 'package:metro_ui/uix_typography.dart';
import 'package:metro_ui/widgets/uix_text.dart';

void main() {
  test('UIX point sizes and 480-wide geometry use separate scales', () {
    expect(uixFontSize(10), closeTo(10.6666667, 1e-6));
    expect(uixFontSize(54), closeTo(57.6, 1e-6));
    expect(48 * uixScale, closeTo(38.4, 1e-6));
  });

  testWidgets('Segoe WP resolves all six bundled faces by native weight', (
    tester,
  ) async {
    final faces = {
      UixFontWeight.light: 'SegoeWP-Light',
      UixFontWeight.semiLight: 'SegoeWP-Semilight',
      UixFontWeight.normal: 'SegoeWP',
      UixFontWeight.semiBold: 'SegoeWP-Semibold',
      UixFontWeight.bold: 'SegoeWP-Bold',
      UixFontWeight.black: 'SegoeWP-Black',
    };

    double measure(String family, FontWeight weight) {
      final painter = TextPainter(
        text: TextSpan(
          text: 'Segoe Windows 0129 MRIgQ',
          style: TextStyle(
            fontFamily: family,
            fontWeight: weight,
            fontSize: 80,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    await tester.runAsync(() async {
      // flutter test disables the engine's asset font registration.
      final bundled = FontLoader('Segoe WP');
      for (final face in faces.values) {
        bundled.addFont(rootBundle.load('fonts/$face.ttf'));
      }
      await bundled.load();
      final widths = <double>{};
      for (final entry in faces.entries) {
        final referenceFamily = 'reference-${entry.value}';
        await (FontLoader(
          referenceFamily,
        )..addFont(rootBundle.load('fonts/${entry.value}.ttf'))).load();
        final expected = measure(referenceFamily, entry.key);
        expect(measure('Segoe WP', entry.key), expected, reason: entry.value);
        widths.add(expected);
      }
      expect(widths, hasLength(faces.length));
    });
  });

  testWidgets('Plain Text in a bare MetroApp route uses UIX LabelStyle', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MetroApp(home: Center(child: Text('native label'))),
    );
    final paragraph = tester.renderObject<RenderParagraph>(
      find.byType(RichText),
    );
    final style = paragraph.text.style!;
    expect(style.fontFamily, 'packages/metro_ui/Segoe WP');
    expect(style.fontSize, uixFontSize(15));
    expect(style.fontWeight, UixFontWeight.normal);
    expect(style.letterSpacing, 0);
    expect(style.height, isNull);
    expect(style.decoration, isNot(TextDecoration.underline));
  });

  testWidgets('tight labels preserve the original paragraph when it wraps', (
    tester,
  ) async {
    await tester.runAsync(
      () => UixText.preloadFontMetrics('packages/metro_ui/Segoe WP'),
    );
    const label = 'A long settings description';
    const key = ValueKey('tight label');
    await tester.pumpWidget(
      const MetroApp(
        home: Center(
          child: SizedBox(
            width: 64,
            child: UixText.fromText(
              Text(label),
              key: key,
              boundsType: UixTextBounds.tight,
            ),
          ),
        ),
      ),
    );
    final tight = find.byKey(key);
    final paragraph = find.descendant(
      of: tight,
      matching: find.byType(RichText),
    );
    expect(tester.getSize(tight).height, tester.getSize(paragraph).height);

    await tester.pumpWidget(
      const MetroApp(
        home: Center(
          child: SizedBox(
            width: 500,
            child: UixText.fromText(
              Text(label),
              key: key,
              boundsType: UixTextBounds.tight,
            ),
          ),
        ),
      ),
    );
    expect(
      tester.getSize(tight).height,
      lessThan(tester.getSize(paragraph).height),
    );
  });

  testWidgets(
    'UixText uses the registered face and independent boundary flags',
    (tester) async {
      final bundle = _AlternateFontBundle();
      await tester.runAsync(() async {
        await (FontLoader(
          _AlternateFontBundle.family,
        )..addFont(bundle.load('fonts/alternate.ttf'))).load();
        await UixText.preloadFontMetrics(
          _AlternateFontBundle.family,
          bundle: bundle,
        );
      });

      const size = 64.0;
      const style = TextStyle(
        inherit: false,
        fontFamily: _AlternateFontBundle.family,
        fontSize: size,
      );
      const pivot = UixTextBounds(
        alignToAscender: true,
        trimLeftSideBearing: true,
      );
      const labels = [
        UixText('H', key: Key('full'), style: style),
        UixText('H', key: Key('pivot'), boundsType: pivot, style: style),
        UixText(
          'g',
          key: Key('tight'),
          boundsType: UixTextBounds.tight,
          style: style,
        ),
        UixText(
          'j',
          key: Key('negative-bearing'),
          boundsType: pivot,
          style: style,
        ),
        UixText(
          'H',
          key: Key('baseline'),
          boundsType: UixTextBounds(alignToBaseline: true),
          style: style,
        ),
        UixText(
          'H文',
          key: Key('fallback'),
          boundsType: UixTextBounds.tight,
          style: style,
        ),
      ];
      await tester.pumpWidget(
        DefaultAssetBundle(
          bundle: bundle,
          child: const MaterialApp(
            home: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: labels),
            ),
          ),
        ),
      );

      Rect box(String id) => tester.getRect(find.byKey(Key(id)));
      Finder paragraph(String id) => find.descendant(
        of: find.byKey(Key(id)),
        matching: find.byType(RichText),
      );
      final pivotParagraph = tester.renderObject<RenderParagraph>(
        paragraph('pivot'),
      );
      final baseline = pivotParagraph.getDryBaseline(
        pivotParagraph.constraints,
        TextBaseline.alphabetic,
      )!;

      // The bundle supplies a different cap height from the original font asset.
      const cap = 1200 / 2048 * size;
      const descent = 514 / 2048 * size;
      const bearing = 188 / 2048 * size;
      expect(box('pivot').height, closeTo(cap + descent, .001));
      expect(box('tight').height, closeTo(cap, .001));
      expect(box('baseline').height, closeTo(2210 / 2048 * size, .001));
      expect(box('full').width - box('pivot').width, closeTo(bearing, .001));
      expect(
        tester.getTopLeft(paragraph('pivot')).dy + baseline - box('pivot').top,
        closeTo(cap, .001),
      );
      expect(
        tester.getTopLeft(paragraph('negative-bearing')).dx,
        box('negative-bearing').left,
      );
      expect(
        box('fallback').height,
        tester.getSize(paragraph('fallback')).height,
      );
    },
  );

  testWidgets('A Metro scope uses its own font metrics inside Material', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DefaultTextStyle(
          style: TextStyle(fontFamily: 'host-font', height: 1.7),
          child: MetroTheme(
            data: MetroThemeData.fromPreset(),
            child: Text('scoped'),
          ),
        ),
      ),
    );
    final paragraph = tester.renderObject<RenderParagraph>(
      find.byType(RichText),
    );
    expect(paragraph.text.style!.fontFamily, 'packages/metro_ui/Segoe WP');
    expect(paragraph.text.style!.height, isNull);
  });

  testWidgets('A Metro preset scope keeps the app custom font family', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MetroApp(
        fontFamily: 'custom-font',
        home: MetroTheme(
          data: MetroThemeData.fromPreset(version: MetroDesignVersion.wp7),
          child: Text('scoped'),
        ),
      ),
    );
    final paragraph = tester.renderObject<RenderParagraph>(
      find.byType(RichText),
    );
    expect(paragraph.text.style!.fontFamily, 'custom-font');
  });
  test('all script geometries use native font metrics', () {
    final original = Typography.material2021();
    final typography = uixTypography(original);
    for (final pair in [
      (original.englishLike, typography.englishLike),
      (original.dense, typography.dense),
      (original.tall, typography.tall),
    ]) {
      for (final styles in [
        (pair.$1.displayLarge, pair.$2.displayLarge),
        (pair.$1.displayMedium, pair.$2.displayMedium),
        (pair.$1.displaySmall, pair.$2.displaySmall),
        (pair.$1.headlineLarge, pair.$2.headlineLarge),
        (pair.$1.headlineMedium, pair.$2.headlineMedium),
        (pair.$1.headlineSmall, pair.$2.headlineSmall),
        (pair.$1.titleLarge, pair.$2.titleLarge),
        (pair.$1.titleMedium, pair.$2.titleMedium),
        (pair.$1.titleSmall, pair.$2.titleSmall),
        (pair.$1.bodyLarge, pair.$2.bodyLarge),
        (pair.$1.bodyMedium, pair.$2.bodyMedium),
        (pair.$1.bodySmall, pair.$2.bodySmall),
        (pair.$1.labelLarge, pair.$2.labelLarge),
        (pair.$1.labelMedium, pair.$2.labelMedium),
        (pair.$1.labelSmall, pair.$2.labelSmall),
      ]) {
        expect(styles.$2!.height, isNull);
        expect(styles.$2!.fontSize, styles.$1!.fontSize);
        expect(styles.$2!.fontWeight, styles.$1!.fontWeight);
      }
    }
  });

  testWidgets('MetroApp supplies native height and respects explicit height', (
    tester,
  ) async {
    late TextStyle themeStyle;
    await tester.pumpWidget(
      MetroApp(
        home: Material(
          child: Builder(
            builder: (context) {
              themeStyle = Theme.of(context).textTheme.bodyMedium!;
              return const Column(
                children: [
                  Text('native', key: Key('native')),
                  Text(
                    'explicit',
                    key: Key('explicit'),
                    style: TextStyle(height: 1.7),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    expect(themeStyle.height, isNull);
    RenderParagraph paragraph(String key) =>
        tester.renderObject<RenderParagraph>(
          find.descendant(
            of: find.byKey(Key(key)),
            matching: find.byType(RichText),
          ),
        );
    expect(paragraph('native').text.style!.height, isNull);
    expect(paragraph('explicit').text.style!.height, 1.7);
  });

  testWidgets('MetroApp pages support an explicitly scoped line height', (
    tester,
  ) async {
    const key = Key('custom line height');
    await tester.pumpWidget(
      MetroApp(
        home: DefaultTextStyle.merge(
          style: const TextStyle(height: 1.8),
          child: const UixText(
            'native font metrics override',
            key: key,
            boundsType: UixTextBounds.tight,
            maxLines: 1,
            softWrap: false,
          ),
        ),
      ),
    );
    final paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.byKey(key), matching: find.byType(RichText)),
    );
    expect(paragraph.text.style!.height, 1.8);
  });
}

class _AlternateFontBundle extends CachingAssetBundle {
  static const family = 'Alternate UIX test face';

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (key == 'FontManifest.json') {
      return '[{"family":"$family","fonts":[{"asset":"fonts/alternate.ttf"}]}]';
    }
    return super.loadString(key, cache: cache);
  }

  @override
  Future<ByteData> load(String key) async {
    if (key != 'fonts/alternate.ttf') return rootBundle.load(key);
    final original = await rootBundle.load('fonts/SegoeWP.ttf');
    final bytes = ByteData.sublistView(
      Uint8List.fromList(
        original.buffer.asUint8List(
          original.offsetInBytes,
          original.lengthInBytes,
        ),
      ),
    );
    for (var i = 0; i < bytes.getUint16(4); i++) {
      final record = 12 + 16 * i;
      if (bytes.getUint32(record) == 0x4f532f32) {
        bytes.setInt16(bytes.getUint32(record + 8) + 88, 1200);
        return bytes;
      }
    }
    throw StateError('Missing OS/2 table in the test font');
  }
}

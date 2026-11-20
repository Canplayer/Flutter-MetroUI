import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metro_ui/app.dart';
import 'package:metro_ui/metro_theme.dart';
import 'package:metro_ui/uix_metrics.dart';
import 'package:metro_ui/uix_typography.dart';
import 'package:metro_ui/widgets/uix_tight_text.dart';

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
    const label = 'A long settings description';
    const key = ValueKey('tight label');
    await tester.pumpWidget(
      const MetroApp(
        home: Center(
          child: SizedBox(
            width: 64,
            child: UixTightText.fromText(Text(label), key: key),
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
            child: UixTightText.fromText(Text(label), key: key),
          ),
        ),
      ),
    );
    expect(
      tester.getSize(tight).height,
      lessThan(tester.getSize(paragraph).height),
    );
  });

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
          child: const UixTightText('native font metrics override', key: key),
        ),
      ),
    );
    final paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.byKey(key), matching: find.byType(RichText)),
    );
    expect(paragraph.text.style!.height, 1.8);
  });
}

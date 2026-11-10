import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metro_ui/app.dart';
import 'package:metro_ui/uix_typography.dart';

void main() {
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

  testWidgets('a supplied theme keeps its explicit line height', (
    tester,
  ) async {
    final base = ThemeData();
    late TextStyle style;
    await tester.pumpWidget(
      MetroApp(
        // ignore: deprecated_member_use
        theme: base.copyWith(
          textTheme: base.textTheme.copyWith(
            bodyMedium: base.textTheme.bodyMedium!.copyWith(height: 1.8),
          ),
        ),
        home: Builder(
          builder: (context) {
            style = Theme.of(context).textTheme.bodyMedium!;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(style.height, 1.8);
  });
}

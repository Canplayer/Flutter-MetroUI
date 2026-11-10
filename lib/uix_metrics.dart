/// UIX design metrics shared by the reconstructed controls.
library;

/// 480-wide design units -> Flutter logical pixels (480 -> 384).
const double uixScale = 0.8;

/// Converts a UIX `FontSize` value to a Flutter `fontSize`.
///
/// The value stored in the UIX resources is a point size: the renderer
/// multiplies it by 4/3 (96/72) before creating the text format
/// (`UIXRender.dll` VA 0x10035cf7 and 0x10035995 load the float at object+8,
/// multiply it by the double at 0x10019bc8 = 4/3 and pass it together with a
/// 700 font weight). The project then applies [uixScale].
///
/// Cross-check: the WP8 panorama title is 128 design units; 128 * 4/3 * 0.8 =
/// 136.5, matching the 135 measured from device screenshots
/// (`WP8与Flutter的Panorama字号差异.md`).
double uixFontSize(double points) => points * (4 / 3) * uixScale;

/// Segoe WP vertical metrics, read out of `fonts/SegoeWP.ttf`:
/// `head.unitsPerEm` 2048, `hhea.ascender/descender` and
/// `OS/2.usWinAscent/usWinDescent` 2210/514, `OS/2.sCapHeight` 1434.
///
/// `fsSelection` bit 7 (`USE_TYPO_METRICS`) is clear, so DirectWrite reports
/// the 2210/514 win metrics - exactly what FreeType reports to Flutter. Both
/// stacks therefore measure the same line box for this font; any vertical
/// difference between them comes from where that box is placed, not from the
/// font.
const double uixFontAscent = 2210 / 2048; // 1.0791 em above the baseline
const double uixFontDescent = 514 / 2048; // 0.2510 em below the baseline
const double uixFontCapHeight = 1434 / 2048; // 0.7002 em

/// Offset (negative = up) that centres a label's cap box instead of its line
/// box, in logical pixels for the given [fontSize].
///
/// Segoe WP's line box is lopsided: 1.0791 em above the baseline but only
/// 0.2510 em below it. A `Text` centred by Flutter centres that line box, which
/// leaves the capitals `(ascent - descent - capHeight) / 2` = 0.064 em below the
/// visual centre - 1.2 px at 18 px, 1.3 px at 20 px. That is why labels look
/// like they sit slightly low.
double uixOpticalTextOffset(double fontSize) =>
    -(uixFontAscent - uixFontDescent - uixFontCapHeight) / 2 * fontSize;

/// Line height of a UIX label, in em.
///
/// UIX keeps a one-line label inside a 1 em box and only widens it when a style
/// opts in through the `LineSpacing` slot (`MediumHighLoose` and friends set it
/// to `MediumLooseLeading`; `MediumMid`, `EditBoxStyle`, `ListPickerFont` do
/// not). Material 3's text theme instead injects `height: 1.43`, which makes the
/// line box 43 % taller - at 20.27 px it is 29 px, taller than the 28.8 px
/// content box of a 38.4 px ListPicker frame, so the label gets top-anchored
/// and drops ~2.5 px. Every control here pins `height` to this value.
const double uixLineHeight = 1;

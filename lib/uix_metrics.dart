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

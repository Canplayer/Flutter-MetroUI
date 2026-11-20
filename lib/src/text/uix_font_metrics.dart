import 'dart:math' as math;
import 'dart:typed_data';

/// Design metrics of one static OpenType face.
class UixFontMetrics {
  UixFontMetrics._({
    required this.unitsPerEm,
    required this.weight,
    required this.ascent,
    required this.descent,
    required this.lineGap,
    required this.capHeight,
    required this._characterMap,
    required this._horizontalMetrics,
    required this._horizontalMetricCount,
    required this._glyphCount,
  });

  final int unitsPerEm;
  final int weight;
  final int ascent;
  final int descent;
  final int lineGap;
  final int? capHeight;
  final ByteData _characterMap;
  final ByteData _horizontalMetrics;
  final int _horizontalMetricCount;
  final int _glyphCount;

  static UixFontMetrics? read(ByteData font) {
    try {
      return _read(font);
    } on RangeError {
      return null;
    }
  }

  static UixFontMetrics? _read(ByteData font) {
    final signature = font.getUint32(0);
    if (signature != 0x00010000 && signature != 0x4f54544f) return null;
    final tables = <String, ByteData>{};
    final count = font.getUint16(4);
    for (var i = 0; i < count; i++) {
      final record = 12 + 16 * i;
      final tag = String.fromCharCodes([
        for (var j = 0; j < 4; j++) font.getUint8(record + j),
      ]);
      final offset = font.getUint32(record + 8);
      final length = font.getUint32(record + 12);
      if (offset > font.lengthInBytes || length > font.lengthInBytes - offset) {
        return null;
      }
      tables[tag] = ByteData.sublistView(font, offset, offset + length);
    }

    // Variable face metrics can change with the instance's axes (MVAR).
    if (tables.containsKey('fvar')) return null;
    final head = tables['head'];
    final hhea = tables['hhea'];
    final hmtx = tables['hmtx'];
    final maxp = tables['maxp'];
    final os2 = tables['OS/2'];
    final cmap = tables['cmap'];
    if (head == null ||
        hhea == null ||
        hmtx == null ||
        maxp == null ||
        os2 == null ||
        cmap == null) {
      return null;
    }
    final characterMap = _unicodeCharacterMap(cmap);
    final unitsPerEm = head.getUint16(18);
    final glyphCount = maxp.getUint16(4);
    final horizontalMetricCount = hhea.getUint16(34);
    if (unitsPerEm == 0 ||
        characterMap == null ||
        horizontalMetricCount == 0 ||
        horizontalMetricCount > glyphCount ||
        hmtx.lengthInBytes < 2 * (glyphCount + horizontalMetricCount)) {
      return null;
    }

    final version = os2.getUint16(0);
    final useTypoMetrics = version >= 4 && os2.getUint16(62) & 0x80 != 0;
    final ascent = useTypoMetrics ? os2.getInt16(68) : os2.getUint16(74);
    final descent = useTypoMetrics ? -os2.getInt16(70) : os2.getUint16(76);
    final lineGap = useTypoMetrics
        ? os2.getInt16(72)
        : math.max(
            0,
            hhea.getInt16(4) -
                hhea.getInt16(6) +
                hhea.getInt16(8) -
                ascent -
                descent,
          );
    final capHeight = version >= 2 ? os2.getInt16(88) : 0;
    if (ascent <= 0 || descent < 0) return null;
    return UixFontMetrics._(
      unitsPerEm: unitsPerEm,
      weight: os2.getUint16(4),
      ascent: ascent,
      descent: descent,
      lineGap: lineGap,
      capHeight: capHeight > 0 ? capHeight : null,
      characterMap: _copy(characterMap),
      horizontalMetrics: _copy(hmtx),
      horizontalMetricCount: horizontalMetricCount,
      glyphCount: glyphCount,
    );
  }

  // Keep only the tables used when measuring labels, especially for fonts
  // with large outline tables.
  static ByteData _copy(ByteData data) => ByteData.sublistView(
    Uint8List.fromList(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    ),
  );

  static ByteData? _unicodeCharacterMap(ByteData cmap) {
    ByteData? bmp;
    for (var i = 0; i < cmap.getUint16(2); i++) {
      final entry = 4 + 8 * i;
      final platform = cmap.getUint16(entry);
      final encoding = cmap.getUint16(entry + 2);
      if (platform != 0 &&
          !(platform == 3 && (encoding == 1 || encoding == 10))) {
        continue;
      }
      final offset = cmap.getUint32(entry + 4);
      final format = cmap.getUint16(offset);
      if (format == 12) {
        final length = cmap.getUint32(offset + 4);
        final groups = cmap.getUint32(offset + 12);
        if (length >= 16 + 12 * groups &&
            length <= cmap.lengthInBytes - offset) {
          return ByteData.sublistView(cmap, offset, offset + length);
        }
      }
      if (format == 4) {
        final length = cmap.getUint16(offset + 2);
        final segmentCount = cmap.getUint16(offset + 6) ~/ 2;
        if (segmentCount > 0 &&
            length >= 16 + 8 * segmentCount &&
            length <= cmap.lengthInBytes - offset) {
          bmp = ByteData.sublistView(cmap, offset, offset + length);
        }
      }
    }
    return bmp;
  }

  int _glyphIndex(int rune) {
    final cmap = _characterMap;
    if (cmap.getUint16(0) == 12) {
      var low = 0;
      var high = cmap.getUint32(12);
      while (low < high) {
        final middle = (low + high) ~/ 2;
        final group = 16 + 12 * middle;
        final first = cmap.getUint32(group);
        if (rune < first) {
          high = middle;
        } else if (rune > cmap.getUint32(group + 4)) {
          low = middle + 1;
        } else {
          return cmap.getUint32(group + 8) + (rune - first);
        }
      }
      return 0;
    }

    if (rune >= 0xffff) return 0;
    final segments = cmap.getUint16(6) ~/ 2;
    var low = 0;
    var high = segments;
    while (low < high) {
      final middle = (low + high) ~/ 2;
      if (cmap.getUint16(14 + 2 * middle) < rune) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    if (low == segments) return 0;
    final start = cmap.getUint16(16 + 2 * (segments + low));
    if (rune < start) return 0;
    final delta = cmap.getInt16(16 + 2 * (2 * segments + low));
    final rangeOffset = 16 + 2 * (3 * segments + low);
    final range = cmap.getUint16(rangeOffset);
    if (range == 0) return (rune + delta) & 0xffff;
    final address = rangeOffset + range + 2 * (rune - start);
    if (address + 2 > cmap.lengthInBytes) return 0;
    final glyph = cmap.getUint16(address);
    return glyph == 0 ? 0 : (glyph + delta) & 0xffff;
  }

  bool contains(int rune) {
    final glyph = _glyphIndex(rune);
    return glyph > 0 && glyph < _glyphCount;
  }

  int? leftSideBearing(int rune) {
    final glyph = _glyphIndex(rune);
    if (glyph == 0 || glyph >= _glyphCount) return null;
    final offset = glyph < _horizontalMetricCount
        ? 4 * glyph + 2
        : 4 * _horizontalMetricCount + 2 * (glyph - _horizontalMetricCount);
    return _horizontalMetrics.getInt16(offset);
  }
}

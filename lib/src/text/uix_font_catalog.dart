import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'uix_font_metrics.dart';

/// Keeps font data scoped to the bundle that supplied the manifest.
class UixFontCatalog {
  UixFontCatalog._(this._bundle);

  static final _catalogs = Expando<UixFontCatalog>();

  static UixFontCatalog of(AssetBundle bundle) =>
      _catalogs[bundle] ??= UixFontCatalog._(bundle);

  final AssetBundle _bundle;
  final _faces = <String, List<UixFontFace>>{};
  final _pending = <String, Future<List<UixFontFace>>>{};
  late final _manifest = _readManifest();

  List<UixFontFace>? faces(String family) => _faces[family];

  Future<List<UixFontFace>> load(String family) =>
      _pending.putIfAbsent(family, () async {
        final fonts = await _manifest;
        var assets = fonts[family];
        // The same package's assets are unqualified when it is the application.
        const ownPackage = 'packages/metro_ui/';
        if (assets == null && family.startsWith(ownPackage)) {
          assets = fonts[family.substring(ownPackage.length)];
        }
        final faces = await Future.wait((assets ?? const []).map(_readFace));
        return _faces[family] = faces.whereType<UixFontFace>().toList();
      });

  Future<Map<String, List<Map<String, Object?>>>> _readManifest() async {
    try {
      final entries = jsonDecode(await _bundle.loadString('FontManifest.json'));
      if (entries is! List) return {};
      return {
        for (final entry in entries)
          if (entry case {
            'family': final String family,
            'fonts': final List fonts,
          })
            family: fonts.whereType<Map<String, Object?>>().toList(),
      };
    } on FormatException {
      return {};
    } on FlutterError {
      return {};
    }
  }

  Future<UixFontFace?> _readFace(Map<String, Object?> entry) async {
    final asset = entry['asset'];
    if (asset is! String) return null;
    try {
      final metrics = UixFontMetrics.read(await _bundle.load(asset));
      if (metrics == null) return null;
      final weight = entry['weight'];
      return UixFontFace(
        metrics,
        weight: weight is int ? weight : metrics.weight,
        italic: entry['style'] == 'italic',
      );
    } on FlutterError {
      return null;
    }
  }
}

class UixFontFace {
  const UixFontFace(this.metrics, {required this.weight, required this.italic});

  final UixFontMetrics metrics;
  final int weight;
  final bool italic;
}

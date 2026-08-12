import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../../core/result.dart';
import '../../domain/models/menu.dart';
import '../../domain/repositories/menu_repository.dart';

/// Phase 0 menu source: a bundled JSON asset. Same interface the live Ebriza
/// repository will implement in Phase 1, so callers never change.
class BundledMenuRepository implements MenuRepository {
  final String assetPath;
  final AssetBundle bundle;

  BundledMenuRepository({required this.assetPath, AssetBundle? bundle})
    : bundle = bundle ?? rootBundle;

  @override
  Future<Result<Menu>> loadMenu(
    String venueId, {
    bool forceRefresh = false,
  }) async {
    try {
      final raw = await bundle.loadString(assetPath);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return Ok(Menu.fromJson(json));
    } catch (e) {
      // Degrade open: a real repository would fall back to the last cache here.
      return Err('Nu am putut încărca meniul', cause: e);
    }
  }
}

import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../../core/result.dart';
import '../../domain/diagnostics/app_logger.dart';
import '../../domain/models/menu.dart';
import '../../domain/repositories/menu_repository.dart';

/// Phase 0 menu source: a bundled JSON asset. Same interface the live Ebriza
/// repository will implement in Phase 1, so callers never change.
class BundledMenuRepository implements MenuRepository {
  final String assetPath;
  final AssetBundle bundle;
  final AppLogger logger;

  BundledMenuRepository({
    required this.assetPath,
    AssetBundle? bundle,
    this.logger = const SilentLogger(),
  }) : bundle = bundle ?? rootBundle;

  @override
  Future<Result<Menu>> loadMenu(
    String venueId, {
    bool forceRefresh = false,
  }) async {
    try {
      final raw = await bundle.loadString(assetPath);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return Ok(Menu.fromJson(json));
    } catch (e, s) {
      // Degrade open: a real repository would fall back to the last cache here.
      logger.error(
        'menu load failed for $venueId ($assetPath)',
        error: e,
        stackTrace: s,
      );
      return Err('Nu am putut încărca meniul', cause: e);
    }
  }
}

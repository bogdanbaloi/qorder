import '../../core/result.dart';
import '../models/menu.dart';

/// The backend menu source, behind an interface (like `IntegrationBackend`).
/// Phase 0: a bundled JSON asset. Phase 1: live from Ebriza `List items`,
/// with a cached fallback. Callers never know which.
abstract interface class MenuRepository {
  Future<Result<Menu>> loadMenu(String venueId, {bool forceRefresh = false});
}

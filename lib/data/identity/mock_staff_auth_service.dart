import '../../domain/identity/session.dart';
import '../../domain/identity/staff_auth_service.dart';

/// Checks the venue's access code locally (no backend), so the staff/owner gate
/// works on the in-memory demo. Built with the config codes at the composition
/// root. Returns a placeholder token, since the mock enforces nothing.
class MockStaffAuthService implements StaffAuthService {
  final String staffCode;
  final String ownerCode;

  const MockStaffAuthService({
    required this.staffCode,
    required this.ownerCode,
  });

  @override
  Future<String?> authenticate(
    String venueId,
    AppRole role,
    String code,
  ) async {
    final expected = role == AppRole.owner ? ownerCode : staffCode;
    return code == expected ? 'mock-staff-token' : null;
  }
}

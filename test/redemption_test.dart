import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/domain/loyalty/redemption.dart';

// REQ-LOYAL-006: the client parses a redemption from the backend JSON, so a
// customer can see their claimed rewards and the code to show the staff.
void main() {
  test('parses a redemption from the backend JSON', () {
    final r = Redemption.fromJson(const {
      'id': 'RDM-1',
      'reward': 'Beer',
      'cost': 100,
      'code': 'ABC234',
      'consumed': false,
      'createdAtMs': 42,
    });
    expect(r.id, 'RDM-1');
    expect(r.reward, 'Beer');
    expect(r.cost, 100);
    expect(r.code, 'ABC234');
    expect(r.consumed, isFalse);
    expect(r.createdAtMs, 42);
  });

  test('a missing consumed flag defaults to false', () {
    final r = Redemption.fromJson(const {
      'id': 'RDM-2',
      'reward': 'Platter',
      'cost': 250,
      'code': 'XYZ789',
    });
    expect(r.consumed, isFalse);
    expect(r.createdAtMs, 0);
  });
}

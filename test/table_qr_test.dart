import 'package:flutter_test/flutter_test.dart';
import 'package:qorder/features/table/table_qr.dart';

// REQ-LOYAL-002: the loyal in-app scanner parses a table number from the scanned
// QR value (our table link, a query parameter, or a bare number).
void main() {
  test('parses the table from our table link', () {
    expect(tableFromScan('https://qorder.app/t/7'), 7);
    expect(tableFromScan('http://192.168.1.5:8082/#/t/12'), 12);
  });

  test('parses a table query parameter', () {
    expect(tableFromScan('https://qorder.app/menu?table=9'), 9);
  });

  test('parses a bare number, trimming spaces', () {
    expect(tableFromScan('5'), 5);
    expect(tableFromScan('  5  '), 5);
  });

  test('returns null when there is no table', () {
    expect(tableFromScan('https://example.com/hello'), isNull);
    expect(tableFromScan('not a table'), isNull);
    expect(tableFromScan(''), isNull);
  });
}

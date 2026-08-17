/// Extracts a table number from a scanned QR value. Accepts our table link
/// (".../t/7" or ".../#/t/7"), a "?table=7" query, or a bare number. Returns null
/// when none is found. Pure, so the parsing is unit-tested without a camera.
int? tableFromScan(String raw) {
  final value = raw.trim();
  final path = RegExp(r'/t/(\d+)').firstMatch(value);
  if (path != null) return int.tryParse(path.group(1)!);
  final query = RegExp(r'[?&]table=(\d+)').firstMatch(value);
  if (query != null) return int.tryParse(query.group(1)!);
  return int.tryParse(value);
}

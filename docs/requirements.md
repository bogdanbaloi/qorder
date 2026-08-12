# Requirement-to-test traceability

Every requirement maps to at least one automated test. This is the OFT-style
discipline from the HMI platform, idiomatic to Flutter.

Fiecare cerință e legată de cel puțin un test automat.

| REQ | Requirement | Test(s) |
|-----|-------------|---------|
| REQ-MONEY-001 | Money is exact (integer minor units), never floating point | `test/money_test.dart` |
| REQ-MENU-001 | Menu is a structured model parsed from JSON, rendered natively | `test/menu_parse_test.dart`, `test/widget_test.dart` |
| REQ-CART-001 | Cart math sums lines with options and quantity | `test/cart_test.dart` |
| REQ-TBL-001 | Submit is gated on a validated table AND a non-empty cart | `test/submit_flow_test.dart` |
| REQ-ORD-001 | A good submit confirms (server id) and clears the cart; never a silent drop | `test/submit_flow_test.dart` |
| REQ-ORD-002 | Orders receive a monotonic FIFO sequence | `test/ordering_mock_test.dart` |
| REQ-ORD-003 | Processing streams status: received -> preparing -> done | `test/ordering_mock_test.dart` |
| REQ-ERR-001 | Submit failure retries then fails clearly; cart preserved (degrade-open) | `test/submit_flow_test.dart`, `test/ordering_mock_test.dart` |
| REQ-FLOW-001 | Full happy path: browse -> add -> set table -> submit -> confirmed | `integration_test/app_test.dart` |
| REQ-DL-001 | A `/t/:table` link pre-fills the table number (Phase 2 wiring) | seam present in `lib/app/router.dart` (test in Phase 2) |

## Status
- Phase 0: REQ-MONEY/MENU/CART/TBL/ORD/ERR covered by `flutter test` (15 tests,
  green). REQ-FLOW-001 runs on a device: `flutter test integration_test`.
- REQ-DL-001 is a designed seam; full deep-link test lands in Phase 2.

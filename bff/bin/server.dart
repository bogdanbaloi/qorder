import 'dart:io';

import 'package:qorder_bff/consent_store.dart';
import 'package:qorder_bff/identity_store.dart';
import 'package:qorder_bff/order_api.dart';
import 'package:qorder_bff/order_store.dart';
import 'package:qorder_bff/redemption_store.dart';
import 'package:qorder_bff/request_store.dart';
import 'package:qorder_bff/staff_auth_store.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

Future<void> main() async {
  // Per-venue staff/owner codes. A real deploy loads these per venue (or from the
  // POS user directory); the demo mirrors the app's AppConfig.demo codes.
  final staffAuth = InMemoryStaffAuthStore(
    codesByVenue: {
      'demo': {'staff': '2468', 'owner': '1357'},
    },
  );
  final api = OrderApi(
    InMemoryOrderStore(),
    InMemoryWaiterRequestStore(),
    InMemoryRedemptionStore(),
    InMemoryIdentityStore(),
    InMemoryConsentStore(),
    staffAuth,
  );
  // HOST=0.0.0.0 to expose on the LAN so phones can reach the laptop.
  final host = Platform.environment['HOST'] ?? '127.0.0.1';
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final server = await shelf_io.serve(api.handler, host, port);
  stdout.writeln('qorder BFF on http://${server.address.host}:${server.port}');
}

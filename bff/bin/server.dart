import 'dart:io';

import 'package:qorder_bff/order_api.dart';
import 'package:qorder_bff/order_store.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

Future<void> main() async {
  final api = OrderApi(InMemoryOrderStore());
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final server = await shelf_io.serve(api.handler, '127.0.0.1', port);
  stdout.writeln('qorder BFF on http://${server.address.host}:${server.port}');
}

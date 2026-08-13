import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/providers.dart';
import '../features/order/order_controller.dart';
import 'router.dart';
import 'theme.dart';

class QorderApp extends ConsumerStatefulWidget {
  const QorderApp({super.key});

  @override
  ConsumerState<QorderApp> createState() => _QorderAppState();
}

class _QorderAppState extends ConsumerState<QorderApp> {
  @override
  void initState() {
    super.initState();
    _resumePendingOrdersOnLaunch();
  }

  /// Resilience (ADR-0012): once the first frame is up, resend anything the
  /// outbox still holds from a previous session. Fire-and-forget on purpose,
  /// the controller surfaces its own state, so `unawaited` marks that intent.
  void _resumePendingOrdersOnLaunch() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(orderControllerProvider.notifier).resumePending());
    });
  }

  @override
  Widget build(BuildContext context) {
    final cfg = ref.watch(appConfigProvider);
    return MaterialApp.router(
      title: cfg.branding.venueName,
      theme: buildTheme(cfg.branding),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

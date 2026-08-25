import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/providers.dart';
import '../features/order/order_controller.dart';
import '../features/settings/theme_mode_controller.dart';
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
    final mode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: cfg.branding.venueName,
      theme: buildTheme(cfg.branding, Brightness.light),
      darkTheme: buildTheme(cfg.branding, Brightness.dark),
      themeMode: mode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

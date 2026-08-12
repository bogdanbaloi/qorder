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
    // Resilience: on launch, resend any order left pending in the outbox.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(orderControllerProvider.notifier).resumePending();
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

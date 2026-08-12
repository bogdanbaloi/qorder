import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/providers.dart';
import 'router.dart';
import 'theme.dart';

class QorderApp extends ConsumerWidget {
  const QorderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.watch(appConfigProvider);
    return MaterialApp.router(
      title: cfg.branding.venueName,
      theme: buildTheme(cfg.branding),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

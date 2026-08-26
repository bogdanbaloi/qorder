import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../domain/diagnostics/app_logger.dart';

/// Installs the app-wide error boundary: an uncaught Flutter or async error is
/// logged through [logger] (which the app can ship to the backend) instead of
/// vanishing into a red screen, and a release build shows a calm fallback rather
/// than the raw error widget. The client twin of the BFF's catch-all (REQ-OBS-005).
void installErrorBoundary(AppLogger logger) {
  FlutterError.onError = (details) {
    reportFlutterError(logger, details);
    // Keep the framework's own presentation in debug, where the red screen helps.
    FlutterError.presentError(details);
  };

  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    reportPlatformError(logger, error, stack);
    return true; // handled: do not let it crash the isolate.
  };

  // In release, swap the raw red/grey error widget for a calm, self-contained one.
  if (kReleaseMode) {
    ErrorWidget.builder = (details) => const _FallbackErrorWidget();
  }
}

/// Logs a Flutter framework/widget error. Extracted so a test drives it directly.
void reportFlutterError(AppLogger logger, FlutterErrorDetails details) {
  logger.error(
    'uncaught Flutter error',
    error: details.exception,
    stackTrace: details.stack,
  );
}

/// Logs an uncaught async/platform error. Extracted so a test drives it directly.
void reportPlatformError(AppLogger logger, Object error, StackTrace stack) {
  logger.error('uncaught error', error: error, stackTrace: stack);
}

/// A calm, dependency-free fallback shown in release when a widget fails to build.
/// It sets its own [Directionality] and colours, so it renders even when the
/// failure is above the app's theme.
class _FallbackErrorWidget extends StatelessWidget {
  const _FallbackErrorWidget();

  @override
  Widget build(BuildContext context) => const Directionality(
    textDirection: TextDirection.ltr,
    child: ColoredBox(
      color: Color(0xFF1E1E20),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Ceva n-a mers. Reîncearcă.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    ),
  );
}

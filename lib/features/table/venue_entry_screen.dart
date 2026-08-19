import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/providers.dart';
import '../menu/menu_screen.dart';
import 'unknown_venue_screen.dart';

/// The deep-link entry for `/v/:venue/t/:table`. Resolves the venue against the
/// `VenueConfigSource`: a known venue becomes the active venue and the menu opens
/// with the table pre-filled; an unknown venue shows [UnknownVenueScreen] rather
/// than guessing a default. This is the read side of multi-tenancy at the app
/// entry point; the menu and table wiring stay unchanged.
class VenueEntryScreen extends ConsumerStatefulWidget {
  final String? venue;
  final int? tableParam;

  const VenueEntryScreen({
    required this.venue,
    required this.tableParam,
    super.key,
  });

  @override
  ConsumerState<VenueEntryScreen> createState() => _VenueEntryScreenState();
}

class _VenueEntryScreenState extends ConsumerState<VenueEntryScreen> {
  bool _known = false;

  @override
  void initState() {
    super.initState();
    final venue = widget.venue;
    _known =
        venue != null &&
        ref.read(venueConfigSourceProvider).configFor(venue) != null;
    if (_known) {
      // A provider must not be modified during build, so set the active venue
      // after the first frame. The app theme follows appConfigProvider, and
      // this runs before the menu's own post-frame table set (parent first),
      // so the table is validated against the resolved venue's policy.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(activeVenueIdProvider.notifier).set(widget.venue!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_known) return UnknownVenueScreen(venueId: widget.venue);
    return MenuScreen(tableParam: widget.tableParam);
  }
}

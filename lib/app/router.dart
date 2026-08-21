import 'package:go_router/go_router.dart';

import '../domain/identity/session.dart';
import '../features/account/account_screen.dart';
import '../features/admin/admin_screen.dart';
import '../features/cart/cart_screen.dart';
import '../features/menu/menu_screen.dart';
import '../features/owner/owner_dashboard.dart';
import '../features/session/role_guard.dart';
import '../features/session/sign_in_screen.dart';
import '../features/settings/owner_settings_screen.dart';
import '../features/table/venue_entry_screen.dart';
import '../features/waiter/waiter_screen.dart';
import 'routes.dart';

/// App routes. `Routes.table` is the seam for the Phase 2 QR / universal-link
/// flow: it pre-fills the table number from the URL, then shows the menu.
final router = GoRouter(
  initialLocation: Routes.menu,
  routes: [
    GoRoute(path: Routes.menu, builder: (context, state) => const MenuScreen()),
    GoRoute(path: Routes.cart, builder: (context, state) => const CartScreen()),
    GoRoute(
      path: Routes.account,
      builder: (context, state) => const AccountScreen(),
    ),
    GoRoute(
      path: Routes.signIn,
      builder: (context, state) => const SignInScreen(),
    ),
    GoRoute(
      path: Routes.table,
      builder: (context, state) => MenuScreen(
        tableParam: int.tryParse(state.pathParameters[Routes.tableParam] ?? ''),
      ),
    ),
    GoRoute(
      path: Routes.venueTable,
      builder: (context, state) => VenueEntryScreen(
        venue: state.pathParameters[Routes.venueParam],
        tableParam: int.tryParse(state.pathParameters[Routes.tableParam] ?? ''),
      ),
    ),
    GoRoute(
      path: Routes.waiter,
      builder: (context, state) =>
          const RoleGuard(role: AppRole.staff, child: WaiterScreen()),
    ),
    GoRoute(
      path: Routes.owner,
      builder: (context, state) =>
          const RoleGuard(role: AppRole.owner, child: OwnerDashboard()),
    ),
    GoRoute(
      path: Routes.settings,
      builder: (context, state) =>
          const RoleGuard(role: AppRole.owner, child: OwnerSettingsScreen()),
    ),
    GoRoute(
      path: Routes.admin,
      builder: (context, state) => const AdminScreen(),
    ),
  ],
);

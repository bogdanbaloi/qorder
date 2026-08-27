# 0082 - Installable PWA (add to home screen)

## Status

Accepted. The foundation for the "app on the phone" experience (icon, full-screen,
and, later, push notifications) without an App Store.

## Context

Two surfaces need to feel like an app on a phone: the staff/bar view (so it can
alert on a new order) and the venue owner's view. A native app from the App Store
is heavy (approval, updates, install friction) and wrong for the customer, whose
ordering must stay a zero-install web page reached by the table QR.

Flutter web already ships most of a Progressive Web App: a `standalone` manifest, a
service worker generated at build, plus the iOS meta tags. But it ships the template
defaults (the Flutter blue, "A new Flutter project.") and is missing a couple of
meta tags, so it does not install cleanly or on brand.

## Decision

Configure the web app as a proper installable PWA, from the one Flutter codebase.

- **Manifest.** `display: standalone` (full-screen, no browser chrome), the real
  name and description, brand colours (`theme_color` the signature orange,
  `background_color` the dark surface) and the icon set. So "Add to Home Screen"
  gives a branded, app-like launch.
- **index.html.** Adds the `viewport`, `theme-color` and `apple-mobile-web-app-capable`
  meta tags (alongside the ones Flutter ships), so a full-screen install works on
  both Android and iOS. The real description replaces the template one.
- The service worker (offline + installability) is Flutter's own, generated on
  `flutter build web`, so nothing extra is maintained.

## Consequences

- Staff and owners can add qorder to their home screen in one tap: an icon, a
  full-screen app-like launch, no App Store, no download. A test asserts the
  manifest is `standalone` and branded and the meta tags are present.
- Customers are unaffected: they keep opening the plain web page from the table QR,
  no install. The PWA is for the roles that reuse the app, not the one-shot patron.
- This is the base for push notifications (offers to loyal customers, new-order
  alerts to staff), which need an installed PWA to fire with the screen off. That
  is the follow-up.
- Custom branded icons (the current ones are the Flutter placeholder) are a small
  design follow-up.

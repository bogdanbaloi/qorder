# ADR-0052: Venue config as a JSON document (asset now, backend later)

- Status: Accepted
- Date: 2026-08-19

## Context (EN)
ADR-0050 put the venue config behind a `VenueConfigSource` port, but the config
was still a compile-time constant (`AppConfig.demo`). Baked into the binary, a new
venue or an edited colour means a rebuild and a redeploy. For a product serving
many pubs the config must be DATA, fetched at runtime, so one binary serves every
venue and an owner edit takes effect without an app release.

## Decision (EN)
- **The config is serialisable.** `AppConfig.fromJson` (and `Branding`,
  `TableNumberPolicy`, `LoyaltyProgram`, `RewardTier`) parse a venue from JSON.
  Colours accept a hex string (`"0xFF2A2A2C"`) so the document is human-editable.
  Enums parse by name, forgiving of an unknown value. A `copyWith` is added for
  the backend overlay and the future Settings screen.
- **A JSON catalogue asset.** `assets/venues/demo.json` (`{ "venues": [ ... ] }`)
  holds the venues. `parseVenueCatalog` is a pure function from the document to
  `List<AppConfig>`, unit-tested without a bundle. A test asserts the shipped
  asset matches `AppConfig.demo`, so moving to JSON changed the source, not the
  values.
- **A loader with degrade-open.** `loadVenueConfigSource` reads the asset and
  builds an `InMemoryVenueConfigSource`. A missing or malformed asset falls back
  to the built-in demo (ADR-0007 style) so startup never bricks. `main()` loads it
  at bootstrap and overrides `venueConfigSourceProvider`.
- **`backendBaseUrl` stays a deployment concern.** It is the same BFF URL for
  every venue in a build, passed via `--dart-define=QORDER_BFF_URL` and overlaid
  onto each loaded venue, not stored per venue in the catalogue.

## Alternatives rejected (EN)
- **Make the port async.** `Future<AppConfig?> configFor` would ripple through
  `appConfigProvider` and every consumer (and the app theme). Instead the async
  load happens once at bootstrap and the port stays synchronous.
- **Store colours as raw ints.** Correct but unreadable and error-prone to
  hand-edit. A hex string (or an int) is parsed, so both work.
- **Delete `AppConfig.demo`.** It is the degrade-open fallback and the test
  baseline. Keeping it is the robust choice until a remote source and a bundled
  fallback document exist.
- **Add `toJson` now.** Not needed for the read side. It lands with the owner
  Settings screen (the write side).

## Consequences (EN)
- A venue is now data: add or edit `assets/venues/demo.json` (later a backend
  document) with no code change. One binary serves every venue.
- The port and every consumer are unchanged. Only the source implementation and
  `main()` wiring changed.
- Follow-ups: `toJson` + the owner Settings screen (Felia 4), a remote
  `VenueConfigSource` and schema-version handling when the document shape evolves.

---

## Context (RO)
ADR-0050 a pus configul de local în spatele portului `VenueConfigSource`, dar
configul era tot o constantă de compilare (`AppConfig.demo`). Ars în binar, un
local nou sau o culoare schimbată înseamnă rebuild și redeploy. Pentru un produs
care servește multe cârciumi, configul trebuie să fie DATE, aduse la runtime, ca
un singur binar să servească fiecare local și o editare a patronului să se aplice
fără un release de app.

## Decizie (RO)
- **Configul e serializabil.** `AppConfig.fromJson` (plus `Branding`,
  `TableNumberPolicy`, `LoyaltyProgram`, `RewardTier`) parsează un local din JSON.
  Culorile acceptă un string hex (`"0xFF2A2A2C"`) ca documentul să fie editabil de
  om. Enum-urile se parsează după nume, iertătoare la o valoare necunoscută. Un
  `copyWith` e adăugat pentru overlay-ul de backend și viitorul ecran de Setări.
- **Un asset catalog JSON.** `assets/venues/demo.json` (`{ "venues": [ ... ] }`)
  ține localurile. `parseVenueCatalog` e o funcție pură din document în
  `List<AppConfig>`, testată fără bundle. Un test verifică că asset-ul livrat
  coincide cu `AppConfig.demo`, deci trecerea la JSON a schimbat sursa, nu
  valorile.
- **Un loader cu degrade-open.** `loadVenueConfigSource` citește asset-ul și
  construiește un `InMemoryVenueConfigSource`. Un asset lipsă sau stricat cade
  înapoi pe demo-ul din binar (stil ADR-0007), ca pornirea să nu se blocheze
  niciodată. `main()` îl încarcă la bootstrap și suprascrie
  `venueConfigSourceProvider`.
- **`backendBaseUrl` rămâne o grijă de deployment.** E același URL de BFF pentru
  fiecare local dintr-un build, dat prin `--dart-define=QORDER_BFF_URL` și overlaid
  pe fiecare local încărcat, nu stocat per local în catalog.

## Alternative respinse (RO)
- **Portul async.** `Future<AppConfig?> configFor` s-ar propaga prin
  `appConfigProvider` și fiecare consumator (și tema app-ului). În schimb
  încărcarea async se face o dată la bootstrap și portul rămâne sincron.
- **Culori ca int-uri brute.** Corect, dar ilizibil și predispus la erori la
  editarea manuală. Un string hex (sau un int) e parsat, deci merg amândouă.
- **Ștergerea `AppConfig.demo`.** E fallback-ul degrade-open și baza testelor.
  Păstrarea lui e alegerea robustă până există o sursă remote și un document de
  fallback livrat.
- **Adăugarea `toJson` acum.** Nu e nevoie pentru latura de citire. Vine cu ecranul
  de Setări al patronului (latura de scriere).

## Consecințe (RO)
- Un local e acum date: adaugi sau editezi `assets/venues/demo.json` (mai târziu un
  document de backend) fără schimbare de cod. Un singur binar servește fiecare
  local.
- Portul și fiecare consumator rămân neschimbate. S-au schimbat doar implementarea
  sursei și cablajul din `main()`.
- De urmat: `toJson` + ecranul de Setări (Felia 4), un `VenueConfigSource` remote
  și tratarea versiunii de schemă când forma documentului evoluează.

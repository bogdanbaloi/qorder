# ADR-0051: Venue resolved from the deep link (`/v/:venue/t/:table`)

- Status: Accepted
- Date: 2026-08-19

## Context (EN)
ADR-0050 made the config addressable per venue behind `VenueConfigSource`, but
the app still acted as the single default venue: the QR link `/t/:table` carried
only the table. For many venues, the sticker must carry the venue too, and the
app must resolve it at entry and drive the whole session with that venue's config.

## Decision (EN)
- **A venue-carrying route.** `/v/:venue/t/:table` alongside the existing
  `/t/:table` (which stays, mapped to the default venue, so nothing breaks). The
  `table` path parameter is shared.
- **A settable active venue.** `activeVenueIdProvider` becomes a small
  `Notifier<String>` (`ActiveVenue.set`) instead of a constant, so the link can
  point the app at a venue. `appConfigProvider` (ADR-0050) already recomputes from
  it, and the app theme follows, so setting the venue reconfigures the whole app.
- **A `VenueEntryScreen` gate.** The route builds this entry, which resolves the
  venue against `VenueConfigSource`: known -> set the active venue (after the
  first frame, as a provider must not be modified during build) and open
  `MenuScreen` with the table pre-filled; unknown -> `UnknownVenueScreen`, a dead
  end that asks the customer to rescan rather than showing a wrong venue's menu.
- **Ordering.** The entry's post-frame venue set is registered before the menu's
  own post-frame table set (parent builds first), so the table is validated
  against the resolved venue's policy.

## Alternatives rejected (EN)
- **Fold venue handling into `MenuScreen`.** The unknown-venue case needs a
  different screen, and the menu should not own venue resolution; a thin entry
  gate keeps `MenuScreen` unchanged (Single Responsibility).
- **Resolve the venue synchronously in the route builder.** Modifying a provider
  during build throws; the post-frame set mirrors the existing `tableParam`
  pattern. A pre-`MaterialApp` URL parse would remove the one-frame default-theme
  flash but is a larger change, deferred.
- **Silently fall back to the default venue for an unknown id.** That would show a
  wrong menu. The port returns null and the entry surfaces a clear error.

## Consequences (EN)
- A sticker link now selects the venue; the app reconfigures (branding, menu,
  policy, loyalty) for it. On web this works directly; native App Links /
  Universal Links registration is still a separate infra step.
- Follow-ups: a one-frame theme flash on entry (a pre-MaterialApp resolve removes
  it); the known/unknown resolution could move from the entry's initState into a
  provider for purer testability.

---

## Context (RO)
ADR-0050 a făcut configul adresabil pe local în spatele lui `VenueConfigSource`,
dar aplicația tot juca singurul local implicit: linkul QR `/t/:masa` ducea doar
masa. Pentru multe localuri, sticker-ul trebuie să ducă și localul, iar aplicația
trebuie să-l rezolve la intrare și să conducă toată sesiunea cu configul acelui
local.

## Decizie (RO)
- **O rută care poartă localul.** `/v/:local/t/:masa` pe lângă `/t/:masa`
  existentă (care rămâne, mapată pe localul implicit, deci nu se strică nimic).
  Parametrul `masa` e comun.
- **Un local activ settable.** `activeVenueIdProvider` devine un mic
  `Notifier<String>` (`ActiveVenue.set`) în loc de constantă, ca linkul să poată
  îndrepta aplicația spre un local. `appConfigProvider` (ADR-0050) deja se
  recalculează din el, iar tema urmează, deci setarea localului reconfigurează
  toată aplicația.
- **Un gate `VenueEntryScreen`.** Ruta construiește acest entry, care rezolvă
  localul cu `VenueConfigSource`: cunoscut -> setează localul activ (după primul
  cadru, că un provider nu se modifică în timpul build-ului) și deschide
  `MenuScreen` cu masa pre-completată; necunoscut -> `UnknownVenueScreen`, o
  fundătură care cere clientului să scaneze din nou în loc să arate meniul greșit.
- **Ordinea.** Setarea post-frame a localului din entry se înregistrează înaintea
  setării post-frame a mesei din meniu (părintele se construiește primul), deci
  masa e validată cu politica localului rezolvat.

## Alternative respinse (RO)
- **Băgarea tratării localului în `MenuScreen`.** Cazul local-necunoscut cere alt
  ecran, iar meniul nu ar trebui să dețină rezoluția localului; un gate subțire
  ține `MenuScreen` neschimbat (Single Responsibility).
- **Rezolvarea sincronă a localului în builder-ul rutei.** Modificarea unui
  provider în timpul build-ului aruncă; setarea post-frame oglindește pattern-ul
  existent `tableParam`. Un parse de URL înainte de `MaterialApp` ar elimina
  flash-ul de un cadru cu tema implicită, dar e o schimbare mai mare, amânată.
- **Fallback tăcut la localul implicit pentru un id necunoscut.** Ar arăta un
  meniu greșit. Portul întoarce null și entry-ul arată o eroare clară.

## Consecințe (RO)
- Un link de sticker selectează acum localul; aplicația se reconfigurează
  (branding, meniu, politică, loialitate) pentru el. Pe web merge direct;
  înregistrarea nativă App Links / Universal Links rămâne un pas de infra separat.
- De urmat: un flash de un cadru cu tema la intrare (un resolve înainte de
  MaterialApp îl elimină); rezoluția known/unknown ar putea trece din initState-ul
  entry-ului într-un provider pentru testabilitate mai pură.

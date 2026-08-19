# ADR-0049: Venue config resolved through a source port (multi-tenant seam)

- Status: Accepted
- Date: 2026-08-19

## Context (EN)
qorder was single-tenant at runtime: `appConfigProvider` returned the one
compile-time constant `AppConfig.demo`, and every other provider watched it. The
config is already per-venue DATA (branding, table policy, loyalty, access codes),
but baked into the binary, so a second venue meant a second build. To become a
product for many pubs, the app must resolve WHICH venue it is and load THAT
venue's config, without a rewrite of the consumers. This is the foundation slice
for both multi-venue (read the config for a venueId) and the future owner Settings
screen (write the same config document).

## Decision (EN)
- **A `VenueConfigSource` port (Domain).** One method: `AppConfig? configFor(
  String venueId)`, returning null for an unknown venue so the caller can show a
  clear path rather than guess a default. Read side only; the Settings write side
  will be a separate port (Interface Segregation).
- **`InMemoryVenueConfigSource` (Data).** Holds configs keyed by venueId; a
  `.demo()` factory carries the single existing venue, so the default deployment
  behaves exactly as before. A remote source drops in behind the port later, with
  no change to callers (config becomes editable data, one binary for all venues).
- **Composition root wiring.** `venueConfigSourceProvider` binds the port to the
  in-memory impl; `activeVenueIdProvider` names the venue this app is acting as
  (default `demo`); `appConfigProvider` resolves the active venue through the
  source, falling back to the demo config only as a safety net.
- **No behaviour change.** The active venue is `demo`, the source holds `demo`, so
  every consumer sees the same config as before. The full suite stays green.

## Alternatives rejected (EN)
- **Keep `AppConfig.demo` inline.** Cannot serve a second venue without a rebuild;
  blocks both multi-venue and Settings.
- **Jump straight to a JSON document + remote fetch.** Bigger step mixing the
  seam with serialisation and I/O. The port is introduced first so the later JSON
  work (a follow-up slice) changes only the implementation, not the callers.
- **Throw on an unknown venue in the provider.** A crash is the wrong UX. The port
  returns null; the link resolver (a later slice) surfaces the unknown-venue case
  before routing, and the provider keeps a defensive demo fallback.
- **A settable active venue now (Notifier).** Not needed until the link carries the
  venue; a plain provider defaulting to `demo` is the minimal correct step and
  becomes settable in the venue-from-link slice.

## Consequences (EN)
- The app no longer depends on a single hard-wired config; it resolves the active
  venue's config through a port. Tests override the source and the active venue to
  act as any venue.
- Sets up the next slices: venue-from-link (`/v/:venue/t/:table` sets the active
  venue), config-as-JSON (swap the source implementation), and the owner Settings
  screen (the write side of the same document).
- Follow-up: the demo fallback in `appConfigProvider` becomes purely defensive
  once the link resolver handles unknown venues.

---

## Context (RO)
qorder era single-tenant la runtime: `appConfigProvider` întorcea singura
constantă de compilare `AppConfig.demo`, iar toți ceilalți provideri o urmăreau.
Configul e deja DATE per-venue (branding, politică de mese, loialitate, coduri de
acces), dar ars în binar, deci un al doilea local însemna un al doilea build. Ca
să devină produs pentru multe cârciumi, aplicația trebuie să rezolve CARE local
este și să încarce configul ACELUI local, fără a rescrie consumatorii. E felia de
temelie și pentru multi-venue (citirea configului pentru un venueId), și pentru
viitorul ecran de Setări al patronului (scrierea aceluiași document de config).

## Decizie (RO)
- **Un port `VenueConfigSource` (Domain).** O metodă: `AppConfig? configFor(
  String venueId)`, care întoarce null pentru un local necunoscut ca apelantul să
  poată arăta o cale clară în loc să ghicească un default. Doar latura de citire;
  latura de scriere (Settings) va fi un port separat (Interface Segregation).
- **`InMemoryVenueConfigSource` (Data).** Ține configuri indexate pe venueId; un
  factory `.demo()` poartă singurul local existent, deci deploy-ul implicit se
  comportă exact ca înainte. O sursă remote intră în spatele portului mai târziu,
  fără schimbare la apelanți (configul devine date editabile, un binar pentru toate
  localurile).
- **Cablaj în composition root.** `venueConfigSourceProvider` leagă portul de
  impl-ul in-memory; `activeVenueIdProvider` numește localul pe care-l joacă
  aplicația (implicit `demo`); `appConfigProvider` rezolvă localul activ prin
  sursă, cu fallback la configul demo doar ca plasă de siguranță.
- **Fără schimbare de comportament.** Localul activ e `demo`, sursa ține `demo`,
  deci fiecare consumator vede același config ca înainte. Suita rămâne verde.

## Alternative respinse (RO)
- **Păstrarea `AppConfig.demo` inline.** Nu poate servi un al doilea local fără
  rebuild; blochează și multi-venue, și Settings.
- **Saltul direct la document JSON + fetch remote.** Pas mai mare care amestecă
  seam-ul cu serializarea și I/O-ul. Portul se introduce întâi, ca munca de JSON de
  mai târziu (o felie viitoare) să schimbe doar implementarea, nu apelanții.
- **Aruncarea unei excepții pe local necunoscut în provider.** Un crash e UX
  greșit. Portul întoarce null; resolver-ul de link (o felie viitoare) tratează
  localul necunoscut înainte de rutare, iar providerul păstrează un fallback demo
  defensiv.
- **Un local activ settable acum (Notifier).** Nu e nevoie până linkul nu poartă
  localul; un provider simplu cu default `demo` e pasul minim corect și devine
  settable în felia venue-din-link.

## Consecințe (RO)
- Aplicația nu mai depinde de un singur config cablat; rezolvă configul localului
  activ printr-un port. Testele suprascriu sursa și localul activ ca să joace orice
  local.
- Pregătește feliile următoare: venue-din-link (`/v/:venue/t/:table` setează
  localul activ), config-ca-JSON (schimbi implementarea sursei) și ecranul de
  Setări al patronului (latura de scriere a aceluiași document).
- De urmat: fallback-ul demo din `appConfigProvider` devine pur defensiv odată ce
  resolver-ul de link tratează localurile necunoscute.

# ADR-0027: Toggleable RO/EN UI localization

- Status: Accepted
- Date: 2026-08-16

## Context (EN)
The customer app is used by Romanian and foreign guests. The UI chrome (buttons,
labels, hints) must switch between Romanian and English at a tap. The menu
CONTENT stays as the venue supplies it (brand names like "Pilsner Urquell" are not
translated); only the interface is localized.

## Decision (EN)
A small custom i18n, generic by design:
- `AppStrings`: an interface listing every UI string as a getter or method.
- `StringsRo` and `StringsEn`: one implementation per language. Adding a language
  is a new value plus a new implementation, no widget edits (Open/Closed).
- `languageProvider` (a `Notifier<AppLanguage>`): Romanian by default, `toggle()`
  flips it, the choice is persisted through the `LocalStore` port and restored on
  launch.
- `stringsProvider`: derives the current `AppStrings` from the language. Widgets
  `ref.watch(stringsProvider)` and read labels off it, so no widget holds a
  literal (Dependency Inversion). A toggle button lives in the menu app bar.

Chose a hand-written table over `flutter_localizations` + ARB/intl codegen: two
languages of app chrome do not justify the codegen toolchain, and the interface
keeps it just as extensible.

## Alternatives rejected (EN)
- **flutter_localizations + ARB codegen.** Heavier setup for a small string set.
  The interface gives the same Open/Closed benefit without codegen.
- **Literals with inline `lang == en ? ... : ...`.** Scatters the decision across
  widgets and is not extensible to a third language.
- **Translating the menu content.** Out of scope: names are venue data, and
  per-language content belongs with the menu source (Ebriza) later.

## Consequences (EN)
- A tap switches the whole customer UI. A third language is one class.
- The waiter surface stays Romanian (staff), localizable later via the same table.
- Follow-up: wire the shared_preferences `LocalStore` so the choice survives a
  restart, and auto-pick the device language on first launch.

---

## Context (RO)
Aplicația de client e folosită de oaspeți români și străini. Interfața (butoane,
etichete, hint-uri) trebuie să comute între română și engleză dintr-o atingere.
CONȚINUTUL meniului rămâne cum îl dă localul (nume de brand ca "Pilsner Urquell"
nu se traduc); doar interfața e localizată.

## Decizie (RO)
Un i18n propriu mic, generic prin design:
- `AppStrings`: o interfață care listează fiecare string de UI ca getter sau
  metodă.
- `StringsRo` și `StringsEn`: câte o implementare pe limbă. O limbă nouă e o
  valoare nouă plus o implementare nouă, fără modificări în widget-uri
  (Open/Closed).
- `languageProvider` (un `Notifier<AppLanguage>`): română implicit, `toggle()` o
  schimbă, alegerea e persistată prin portul `LocalStore` și restaurată la
  pornire.
- `stringsProvider`: derivă `AppStrings` curent din limbă. Widget-urile fac
  `ref.watch(stringsProvider)` și citesc etichetele de acolo, deci niciun widget
  nu ține un literal (Dependency Inversion). Un buton de comutare stă în bara de
  meniu.

Am ales un tabel scris de mână în locul `flutter_localizations` + ARB/intl cu
codegen: două limbi de interfață nu justifică lanțul de codegen, iar interfața îl
ține la fel de extensibil.

## Alternative respinse (RO)
- **flutter_localizations + codegen ARB.** Setup mai greu pentru un set mic de
  string-uri. Interfața dă același beneficiu Open/Closed fără codegen.
- **Literale cu `lang == en ? ... : ...` peste tot.** Împrăștie decizia prin
  widget-uri și nu se extinde la o a treia limbă.
- **Traducerea conținutului de meniu.** În afara scopului: numele sunt date ale
  localului, iar conținutul pe limbă stă cu sursa meniului (Ebriza) mai târziu.

## Consecințe (RO)
- O atingere schimbă toată interfața de client. O a treia limbă e o clasă.
- Suprafața ospătarului rămâne română (personal), localizabilă mai târziu prin
  același tabel.
- De urmat: cablarea `LocalStore` cu shared_preferences ca alegerea să
  supraviețuiască unei reporniri și alegerea automată a limbii telefonului la
  prima pornire.

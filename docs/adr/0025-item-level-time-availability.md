# ADR-0025: Item-level time-of-day availability

- Status: Accepted
- Date: 2026-08-16

## Context (EN)
A category could already carry a `TimeWindow` (e.g. Morning Deal in the morning).
But some things are time-limited at the item level, not the whole category, and
the venue wants the menu to be smart about the hour: only offer what is available
now.

## Decision (EN)
Give `MenuItem` its own optional `availability: TimeWindow?`, mirroring the
category, and a pure `isAvailableAt(DateTime)` that ANDs the manual `available`
flag with the window (null window = always). The same `TimeWindow` type is
reused, plus a `hoursLabel` ("06:00-12:00") for a note. The menu View disables an
item that is off now and shows "disponibil HH:MM", reading the domain rule rather
than computing it. `now` is passed in from the build, so the rule is unit-tested
with explicit times, no wall-clock. The rule lives in the Domain layer, the
widget only renders (MVVM). Windows are data (JSON), so a venue opens the feature
without a code change; the demo seeds Morning Deal at 06:00-12:00.

## Alternatives rejected (EN)
- **Category-only windows.** Too coarse: a single time-limited drink would force
  its own category.
- **Hide unavailable items.** They vanish with no explanation. Disabling with a
  "disponibil HH:MM" note tells the customer it exists and when to come back.
- **Read the clock inside the model.** That hides an input and breaks testing.
  Passing `now` keeps `isAvailableAt` pure.

## Consequences (EN)
- The menu reflects the hour at both category and item granularity.
- Follow-up: show the day restriction too (not only hours), and an optional
  hide-vs-disable policy per venue. A `clockProvider` could inject time app-wide.

---

## Context (RO)
O categorie putea deja purta un `TimeWindow` (ex. Morning Deal dimineața). Dar
unele lucruri sunt limitate pe oră la nivel de produs, nu de categorie întreagă,
iar localul vrea meniul să fie deștept cu ora: să ofere doar ce e disponibil acum.

## Decizie (RO)
Dăm lui `MenuItem` propriul `availability: TimeWindow?` opțional, ca la categorie,
și un `isAvailableAt(DateTime)` pur care combină (AND) flag-ul manual `available`
cu fereastra (fereastră nulă = mereu). Se refolosește același tip `TimeWindow`,
plus un `hoursLabel` ("06:00-12:00") pentru notă. View-ul de meniu dezactivează un
produs indisponibil acum și afișează "disponibil HH:MM", citind regula din domain,
nu calculând-o. `now` e pasat din build, deci regula e testată unitar cu ore
explicite, fără ceas real. Regula stă în stratul Domain, widget-ul doar afișează
(MVVM). Ferestrele sunt date (JSON), deci un local pornește feature-ul fără
schimbare de cod; demo-ul pune Morning Deal la 06:00-12:00.

## Alternative respinse (RO)
- **Ferestre doar pe categorie.** Prea grosier: o singură băutură limitată pe oră
  ar cere o categorie separată.
- **Ascunderea produselor indisponibile.** Dispar fără explicație. Dezactivarea cu
  nota "disponibil HH:MM" îi spune clientului că există și când să revină.
- **Citirea ceasului în model.** Ascunde un input și strică testarea. Pasarea lui
  `now` ține `isAvailableAt` pur.

## Consecințe (RO)
- Meniul reflectă ora, la nivel de categorie și de produs.
- De urmat: afișarea și a restricției pe zile (nu doar ore) și o politică
  opțională ascunde-vs-dezactivează per local. Un `clockProvider` ar putea injecta
  timpul în toată aplicația.

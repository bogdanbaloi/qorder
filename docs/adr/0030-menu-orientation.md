# ADR-0030: Menu orientation (active category chip + available-now filter)

- Status: Accepted
- Date: 2026-08-16

## Context (EN)
The menu has 29 categories. The jump chips let you leap to a section, but nothing
told you WHERE you were while scrolling, and there was no quick way to hide what
the hour has closed.

## Decision (EN)
- **Active category chip.** The list reports its visible positions through
  `ItemPositionsListener`. A scroll handler maps the top-most visible row to its
  category (via the stored header-row indices) and highlights that category's
  chip. The chip bar is itself a `ScrollablePositionedList`, so the active chip is
  scrolled into view. Tapping a chip still jumps the list.
- **"Available now" filter.** A `FilterChip` toggles hiding closed categories and
  items outside their time window, reusing `MenuItem.isAvailableAt` and a new
  `Category.copyWith(items:)`. The filtered category set drives both the chips and
  the rows, so they stay in sync.

## Alternatives rejected (EN)
- **A sticky header overlay.** More complex, and the highlighted, auto-scrolled
  chip already answers "where am I" while staying tappable.
- **Filtering in the widget by skipping rows.** That would desync the chips (built
  from the full list) from the rows. Filtering the category set up front keeps one
  source of truth for both.

## Consequences (EN)
- The customer always sees which category they are in, and can hide what is closed.
- The scroll handler runs on every position change; it early-outs and only calls
  setState when the active category actually changes.
- Follow-up: a true sticky header if wanted, and remembering the filter choice.

---

## Context (RO)
Meniul are 29 de categorii. Chip-urile de salt te duc la o secțiune, dar nimic
nu-ți spunea UNDE ești cât derulezi, și nu era o cale rapidă de a ascunde ce a
închis ora.

## Decizie (RO)
- **Chip de categorie activ.** Lista își raportează pozițiile vizibile prin
  `ItemPositionsListener`. Un handler de scroll mapează rândul cel mai de sus la
  categoria lui (prin indicii de rând-antet stocați) și evidențiază chip-ul acelei
  categorii. Bara de chip-uri e ea însăși un `ScrollablePositionedList`, deci
  chip-ul activ e adus în vedere. Tap pe chip tot sare în listă.
- **Filtru „disponibile acum".** Un `FilterChip` comută ascunderea categoriilor
  închise și a produselor în afara ferestrei de timp, refolosind
  `MenuItem.isAvailableAt` și un `Category.copyWith(items:)` nou. Setul filtrat de
  categorii conduce și chip-urile, și rândurile, deci rămân sincronizate.

## Alternative respinse (RO)
- **Un antet lipicios suprapus.** Mai complex, iar chip-ul evidențiat și
  auto-scrolat răspunde deja la „unde sunt", rămânând apăsabil.
- **Filtrarea în widget prin sărirea rândurilor.** Ar desincroniza chip-urile
  (construite din lista completă) de rânduri. Filtrarea setului de categorii din
  start ține o sursă unică pentru amândouă.

## Consecințe (RO)
- Clientul vede mereu în ce categorie e și poate ascunde ce e închis.
- Handler-ul de scroll rulează la fiecare schimbare de poziție; iese devreme și
  cheamă setState doar când categoria activă chiar se schimbă.
- De urmat: un antet cu adevărat lipicios dacă se dorește și memorarea alegerii de
  filtru.

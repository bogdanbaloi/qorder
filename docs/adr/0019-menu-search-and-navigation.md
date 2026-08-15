# ADR-0019: Menu search and category navigation

- Status: Accepted
- Date: 2026-08-14

## Context (EN)
A real menu has many items across many categories. Scrolling a long list is the
main friction for a customer. The app needs live search and a fast way to jump
to a category. This is pure presentation over the existing menu model, no POS.

## Decision (EN)
Put the FILTER in the domain: `Menu.filtered(query)` (plus `MenuItem.matches`)
returns a menu with only matching items by name, description or tag, dropping
empty categories. It is a pure function, unit-tested without the UI. The menu
screen adds a search field (live, with a clear button) and, when not searching,
a horizontal bar of category chips that scroll the list to that category via a
`GlobalKey` per section and `Scrollable.ensureVisible`. When searching, the chips
hide and the list shows the flat filtered results, or "Nimic găsit".

## Alternatives rejected (EN)
- **Filter inside the widget**: mixes business logic with layout and is hard to
  test. The filter belongs on the model.
- **Category chips that filter (tabs) instead of scroll-to**: hides the other
  categories. Scroll-to keeps everything browsable, the chip is just a shortcut.
- **A search package / fuzzy matching**: over-engineering for one venue's menu.
  A case-insensitive substring match is enough and predictable.

## Consequences (EN)
- Finding an item is fast: type to filter, or tap a category to jump.
- The filter is reused as-is when the menu comes live from Ebriza (Phase 1), it
  is model logic, not tied to the JSON source.
- Follow-up (next B increment): item photos + a detail sheet, dietary badges.

---

## Context (RO)
Un meniu real are multe produse în multe categorii. Derularea unei liste lungi e
principala frecare pentru client. Aplicația are nevoie de căutare live și de un
mod rapid de a sări la o categorie. E pură prezentare peste modelul de meniu
existent, fără POS.

## Decizie (RO)
Punem FILTRUL în domeniu: `Menu.filtered(query)` (plus `MenuItem.matches`)
întoarce un meniu doar cu produsele care se potrivesc după nume, descriere sau
etichetă, aruncând categoriile rămase goale. E o funcție pură, testată unitar
fără UI. Ecranul de meniu adaugă un câmp de căutare (live, cu buton de golire)
și, când nu cauți, o bară orizontală de chips de categorii care derulează lista
la acea categorie prin câte un `GlobalKey` pe secțiune și
`Scrollable.ensureVisible`. Când cauți, chips-urile se ascund și lista arată
rezultatele filtrate, sau „Nimic găsit".

## Alternative respinse (RO)
- **Filtrul în widget**: amestecă logica de business cu layout-ul și e greu de
  testat. Filtrul aparține modelului.
- **Chips care filtrează (taburi) în loc de sari-la**: ascunde celelalte
  categorii. Sari-la ține totul răsfoibil, chip-ul e doar o scurtătură.
- **Un pachet de căutare / potrivire fuzzy**: over-engineering pentru meniul unui
  local. O potrivire de subșir, indiferent de majuscule, ajunge și e predictibilă.

## Consecințe (RO)
- Găsirea unui produs e rapidă: tastezi ca să filtrezi, sau apeși o categorie ca
  să sari.
- Filtrul se refolosește ca atare când meniul vine live din Ebriza (Faza 1), e
  logică de model, nu legată de sursa JSON.
- De urmat (următorul increment B): poze la produse + fișă de detaliu, badge-uri
  alimentare.

# ADR-0020: Menu item detail sheet (photo, badges, add)

- Status: Accepted
- Date: 2026-08-14

## Context (EN)
Rows of name and price are not enough to decide. A customer wants to see a photo,
a description and any dietary tags before adding. The menu also grows richer as
Ebriza supplies images (Phase 1). This is presentation over the model plus one
new optional field.

## Decision (EN)
Add an optional `imageUrl` to `MenuItem` (nullable, so the current data still
works). Tapping a menu row opens a bottom sheet with the photo (or a placeholder
box), the name, description, tag badges, the price and an "Adaugă în coș" button,
which is now the single add path. The row itself shows a thumbnail when an image
exists and renders the tags as small badges. Images degrade gracefully: a failed
or missing image shows a placeholder, never a broken box.

## Alternatives rejected (EN)
- **Keep tap-to-add with no detail**: fast but blind, the customer cannot see
  what they are ordering. A sheet is the intuitive menu pattern.
- **Bundle sample image URLs in the JSON now**: network images over a congested
  pub WiFi is the very problem we avoid. Images arrive from Ebriza; the code is
  ready, the demo shows the placeholder.
- **Map only known dietary tags**: brittle. Rendering all tags as badges is
  general and works whatever Ebriza sends.

## Consequences (EN)
- The customer sees a photo, description and badges before adding, from one tap.
- Ready for Ebriza images with no code change, just data.
- Follow-up: distinguish dietary badges from marketing ones, item options in the
  sheet.

---

## Context (RO)
Rânduri cu nume și preț nu ajung ca să te decizi. Clientul vrea să vadă o poză, o
descriere și eventualele etichete alimentare înainte să adauge. Meniul devine și
mai bogat când Ebriza dă imagini (Faza 1). E prezentare peste model plus un câmp
nou opțional.

## Decizie (RO)
Adăugăm un `imageUrl` opțional pe `MenuItem` (nullable, deci datele actuale merg
în continuare). La apăsarea unui rând se deschide o fișă (bottom sheet) cu poza
(sau un placeholder), numele, descrierea, badge-urile de etichete, prețul și un
buton „Adaugă în coș", care e acum singura cale de adăugare. Rândul arată un
thumbnail când există imagine și randează etichetele ca badge-uri mici. Imaginile
degradează grațios: una lipsă sau eșuată arată un placeholder, niciodată o cutie
stricată.

## Alternative respinse (RO)
- **Adăugare la tap fără detalii**: rapid dar orb, clientul nu vede ce comandă. O
  fișă e tiparul intuitiv de meniu.
- **Bagăm URL-uri de imagini în JSON acum**: imagini prin WiFi-ul aglomerat al
  pubului e fix problema pe care o evităm. Imaginile vin din Ebriza; codul e
  gata, demo-ul arată placeholder-ul.
- **Mapăm doar etichete alimentare cunoscute**: fragil. Randarea tuturor
  etichetelor ca badge-uri e generală și merge cu orice trimite Ebriza.

## Consecințe (RO)
- Clientul vede poză, descriere și badge-uri înainte să adauge, dintr-o apăsare.
- Gata pentru imaginile din Ebriza fără schimbare de cod, doar date.
- De urmat: separarea badge-urilor alimentare de cele de marketing, opțiunile de
  produs în fișă.

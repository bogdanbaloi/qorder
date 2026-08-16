# ADR-0029: Category icons from the venue site's SVGs

- Status: Accepted
- Date: 2026-08-16

## Context (EN)
The menu was text only, while the venue site marks each drink type with an icon
(coffee, beer, shots, wine, rum). Adding those icons makes the app look like the
site and helps scanning. The site has no per-product photos, only these five
drink-type SVGs.

## Decision (EN)
Bundle the site's own five SVG icons under `assets/icons` and render them with
`flutter_svg`. A pure `categoryIconAsset(Category)` maps a category to an icon:
it uses an explicit `Category.icon` key when the data provides one, otherwise it
derives the key from the category name by drink-type keywords. The category
header shows the icon before the name, tinted to the dark colour on the inverted
(orange) bands so it stays visible. Mapping is pure, so it is unit-tested and a
venue can override any category from JSON.

## Alternatives rejected (EN)
- **Per-product photos.** The site has none, and hosting real photos is an Ebriza
  concern later. The five drink-type icons are what exists and what fits.
- **A hard-coded switch in the widget.** The mapping is a pure function plus a
  data override, so it is testable and a venue changes an icon without code.
- **A generic icon font (Material icons).** The venue's own SVGs match its brand
  exactly; a generic glyph would not.

## Consequences (EN)
- Every category shows an on-brand icon, the menu reads like the site.
- Adds the `flutter_svg` dependency and ~14 KB of icons.
- Follow-up: annotate the demo categories with explicit `icon` keys if the
  keyword heuristic mis-picks any, and add a food icon (Quick Bite falls back to
  the shots icon today).

---

## Context (RO)
Meniul era doar text, pe când site-ul localului marchează fiecare tip de băutură
cu o iconiță (cafea, bere, shot-uri, vin, rom). Adăugarea lor face aplicația să
semene cu site-ul și ajută la scanare. Site-ul nu are poze per-produs, doar aceste
cinci iconițe SVG pe tip.

## Decizie (RO)
Bundle-uim cele cinci iconițe SVG ale site-ului în `assets/icons` și le randăm cu
`flutter_svg`. Un `categoryIconAsset(Category)` pur mapează o categorie la o
iconiță: folosește o cheie `Category.icon` explicită când o dau datele, altfel
derivă cheia din numele categoriei după cuvinte-cheie de tip. Antetul de categorie
arată iconița înaintea numelui, colorată în nuanța închisă pe benzile inversate
(portocalii) ca să rămână vizibilă. Maparea e pură, deci e testată unitar, iar un
local poate suprascrie orice categorie din JSON.

## Alternative respinse (RO)
- **Poze per-produs.** Site-ul n-are, iar găzduirea de poze reale e treabă de
  Ebriza mai târziu. Cele cinci iconițe pe tip sunt ce există și ce se potrivește.
- **Un switch hard-codat în widget.** Maparea e o funcție pură plus un override din
  date, deci e testabilă, iar un local schimbă o iconiță fără cod.
- **Un font generic de iconițe (Material icons).** SVG-urile localului se
  potrivesc exact cu brandul lui; un glif generic n-ar face-o.

## Consecințe (RO)
- Fiecare categorie arată o iconiță pe brand, meniul se citește ca site-ul.
- Adaugă dependența `flutter_svg` și ~14 KB de iconițe.
- De urmat: adnotarea categoriilor demo cu chei `icon` explicite dacă euristica pe
  cuvinte greșește vreuna și adăugarea unei iconițe de mâncare (Quick Bite cade
  acum pe iconița de shot-uri).

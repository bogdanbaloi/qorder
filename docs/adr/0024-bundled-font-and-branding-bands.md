# ADR-0024: Bundled display font and config-driven category bands

- Status: Accepted
- Date: 2026-08-16

## Context (EN)
The theme is already config-driven (`Branding` holds colours + a `displayFont`).
Two visual gaps remained versus the venue site: the techno heading font did not
render on the phone, and the menu was a single dark background where the site
alternates dark and coloured sections.

## Decision (EN)
- **Bundle the font.** Chakra Petch ships under `assets/fonts` (SIL OFL 1.1,
  licence included) and is declared in `pubspec`. `buildTheme` applies it as a
  local font family (`copyWith(fontFamily: ...)`). The `google_fonts` package is
  dropped.
- **Add a `Branding.alternatingCategoryBands` token.** When on, menu categories
  alternate a dark band (primary-coloured text) with a primary-coloured band
  (dark text), mirroring the site. Off by default. The parity is decided once in
  the menu screen while flattening rows, and each row carries an `inverted` flag,
  so the header and the item tiles of one category share a seamless band.

## Alternatives rejected (EN)
- **Keep runtime font fetch (`google_fonts`).** It fetches over the network on
  first paint, which failed on the mobile web build and needs connectivity. A
  bundled font renders offline and deterministically.
- **Hard-code the bands in the widget.** That buries a branding choice in UI code.
  As a config token any venue turns the look on or off without a code change,
  which is the same policy-vs-mechanism split the rest of `Branding` follows.
- **A uniform coloured background.** It matches only half the site and is harsh to
  read across a long menu.

## Consequences (EN)
- Headings show the signature font on every device, no network needed.
- A venue picks the banded or the plain look from config.
- The bundled font adds ~0.3 MB of assets. Follow-up: subset the font to the
  glyphs actually used if size matters.

---

## Context (RO)
Tema e deja condusă din config (`Branding` ține culorile + un `displayFont`). Au
rămas două diferențe vizuale față de site-ul localului: fontul techno de la
titluri nu se randra pe telefon, iar meniul avea un singur fundal închis, pe când
site-ul alternează secțiuni închise și colorate.

## Decizie (RO)
- **Bundle-uim fontul.** Chakra Petch e livrat în `assets/fonts` (SIL OFL 1.1, cu
  licența inclusă) și declarat în `pubspec`. `buildTheme` îl aplică drept familie
  locală de font (`copyWith(fontFamily: ...)`). Pachetul `google_fonts` e scos.
- **Adăugăm tokenul `Branding.alternatingCategoryBands`.** Când e pornit,
  categoriile din meniu alternează o bandă închisă (text în culoarea primară) cu o
  bandă în culoarea primară (text închis), ca pe site. Implicit oprit. Paritatea e
  decisă o dată în ecranul de meniu la aplatizarea rândurilor, iar fiecare rând
  poartă un flag `inverted`, ca antetul și rândurile de produse ale unei categorii
  să formeze o bandă continuă.

## Alternative respinse (RO)
- **Păstrarea fontului luat la runtime (`google_fonts`).** Îl descarcă din rețea la
  prima afișare, ceea ce pica pe build-ul web mobil și cere conexiune. Un font
  bundle-uit se randează offline și determinist.
- **Codarea benzilor direct în widget.** Asta ascunde o alegere de branding în cod
  de UI. Ca token de config, orice local pornește sau oprește efectul fără
  schimbare de cod, exact separarea politică-mecanism pe care o urmează restul lui
  `Branding`.
- **Un fundal colorat uniform.** Se potrivește doar cu jumătate din site și e
  obositor la citit pe un meniu lung.

## Consecințe (RO)
- Titlurile arată fontul semnătură pe orice dispozitiv, fără rețea.
- Un local alege din config aspectul cu benzi sau cel simplu.
- Fontul bundle-uit adaugă ~0.3 MB de assets. De urmat: subsetarea fontului la
  glifele efectiv folosite dacă dimensiunea contează.

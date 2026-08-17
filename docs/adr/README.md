# Architecture Decision Records (ADR)

One page per significant decision. Each ADR is bilingual: English structure,
Romanian below. Rejected alternatives are recorded on purpose.

Fiecare decizie importantă are o pagină. Fiecare ADR e bilingv: structura în
engleză, româna dedesubt. Alternativele respinse sunt notate intenționat.

| # | Decision | Decizie |
|---|----------|---------|
| [0001](0001-cross-platform-stack.md) | Cross-platform stack = Flutter | Stack = Flutter |
| [0002](0002-state-management.md) | State management = Riverpod / MVVM (SOLID) | Stare = Riverpod / MVVM |
| [0003](0003-deep-link-strategy.md) | Deep links = Universal/App Links + landing page | Deep link = universal/app links |
| [0004](0004-menu-data-model.md) | Menu = structured model, money in minor units | Meniu = model structurat |
| [0005](0005-ordering-backend-ebriza.md) | Ordering backend = Ebriza POS via a thin BFF | Backend = Ebriza prin BFF |
| [0006](0006-offline-fifo-degrade-open.md) | Offline outbox, FIFO, degrade-open | Outbox, FIFO, degrade-open |
| [0007](0007-multi-tenant-seam.md) | Multi-tenant via a venueId seam | Multi-tenant prin venueId |
| [0008](0008-bar-view-ebriza-ipad.md) | Bar view = the existing Ebriza iPad | Bar = iPad-ul Ebriza |
| [0009](0009-secrets-in-bff.md) | Secrets live in the BFF, never in the app | Secretele stau în BFF |
| [0010](0010-order-lifecycle.md) | Order lifecycle + status sync | Ciclul de viață al comenzii |
| [0011](0011-hmi-reuse.md) | What we reuse (and not) from the HMI platform | Ce reutilizăm din HMI |
| [0012](0012-resilience.md) | Resilience: outbox, idempotency, degrade-open | Reziliență: outbox, idempotență |
| [0013](0013-application-use-cases.md) | Application use-cases (SubmitOrderUseCase) | Use-case-uri de aplicație |
| [0014](0014-order-acceptance-policy.md) | Order acceptance policy (waiter confirm) | Politică de acceptare (confirmare ospătar) |
| [0015](0015-thin-bff.md) | Thin BFF holds orders + the waiter flow | BFF subțire |
| [0016](0016-remote-backend-adapter.md) | Remote backend adapter (app talks to the BFF) | Adaptor remote (app <-> BFF) |
| [0017](0017-waiter-requests.md) | Table-to-waiter requests (call waiter / bill) | Cereri către ospătar (cheamă / nota) |
| [0018](0018-order-timings.md) | Order timings (acceptance + ready-to-table gap) | Timpi comandă (acceptare + gol gata-la-masă) |
| [0019](0019-menu-search-and-navigation.md) | Menu search + jump-to-category navigation | Căutare meniu + sari-la-categorie |
| [0020](0020-menu-item-detail.md) | Menu item detail sheet (photo, badges, add) | Fișă de produs (poză, badge-uri, adăugare) |
| [0021](0021-order-status-steps.md) | Order status as visual steps | Status comandă ca pași vizuali |
| [0022](0022-confirm-before-submit.md) | Review dialog before submitting | Verificare înainte de trimitere |
| [0023](0023-waiter-surface-clarity.md) | Waiter surface clarity (counts + waiting time) | Claritate ospătar (numere + timp) |
| [0024](0024-bundled-font-and-branding-bands.md) | Bundled display font + config-driven category bands | Font bundle-uit + benzi de categorie din config |
| [0025](0025-item-level-time-availability.md) | Item-level time-of-day availability | Disponibilitate pe oră la nivel de produs |
| [0026](0026-happy-hour-promotions.md) | Happy-hour promotions (time-boxed pricing) | Promoții happy hour (preț pe interval orar) |
| [0027](0027-ui-localization-ro-en.md) | Toggleable RO/EN UI localization | Localizare interfață RO/EN comutabilă |
| [0028](0028-track-all-customer-orders.md) | Track the live status of every order | Statusul live al fiecărei comenzi |
| [0029](0029-category-icons.md) | Category icons from the venue site's SVGs | Iconițe de categorie din SVG-urile site-ului |
| [0030](0030-menu-orientation.md) | Menu orientation (active chip + available-now filter) | Orientare în meniu (chip activ + filtru disponibile) |
| [0031](0031-faster-adding.md) | Faster adding (quantity, quick-add, haptic) | Adăugare rapidă (cantitate, +, haptic) |
| [0032](0032-cart-polish.md) | Cart polish (persisted name, savings, empty state) | Coș (nume reținut, economie, stare goală) |
| [0033](0033-order-ready-payoff.md) | Order-ready payoff (alert, green banner, estimate) | Payoff la gata (alertă, banner verde, estimare) |
| [0034](0034-identity-and-staff-guard.md) | Identity/role seam + staff access guard | Seam de identitate/rol + guard staff |
| [0035](0035-owner-dashboard.md) | Owner dashboard (live snapshot) + generalized role guard | Dashboard patron (snapshot live) + guard pe rol |
| [0036](0036-owner-sales-metrics.md) | Real owner metrics (revenue + history) from the BFF | Metrici reale patron (încasări + istoric) din BFF |
| [0037](0037-i18n-all-surfaces.md) | Localize the staff and owner surfaces too | Localizare și pe suprafețele staff/patron |
| [0038](0038-loyal-enrollment.md) | Loyal-customer enrollment + loyal-gated table pick | Înrolare client fidel + alegere masă gated |
| [0039](0039-qr-table-scanner.md) | In-app QR table scanner + declutter loyal enrollment | Scanner QR de masă + declutter înrolare |
| [0040](0040-account-loyalty-screen.md) | Account / loyalty screen with order history | Ecran cont / fidelitate cu istoric comenzi |
| [0041](0041-loyalty-points-rewards.md) | Loyalty points + reward ladder derived from history | Puncte fidelitate + scară recompense din istoric |
| [0042](0042-owner-dashboard-insights.md) | Owner dashboard: avg value, day-over-day, hourly, top products | Dashboard patron: valoare medie, zi-la-zi, orar, top produse |
| [0043](0043-loyal-intuitiveness.md) | Loyal intuitiveness: points chip, greeting, enrol confirmation | Intuitivitate fidel: chip puncte, salut, confirmare înscriere |


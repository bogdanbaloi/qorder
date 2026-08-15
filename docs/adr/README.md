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

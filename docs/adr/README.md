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

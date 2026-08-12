# ADR-0002: State management = Riverpod, MVVM, SOLID at the seams

- Status: Accepted
- Date: 2026-08-12

## Context (EN)
The app must keep business logic out of widgets, be testable, modular, and easy
to extend to new features and new clients.

## Decision (EN)
Use **MVVM** with **Riverpod**. Widgets (View) are dumb; Riverpod Notifiers are
the ViewModels/presentation logic; the domain layer (interfaces + models) is pure
Dart. Dependencies are wired in one composition root (`lib/di/providers.dart`),
which tests override. SOLID is applied **at the seams that change** (backend,
menu source, payment, notifications, branding), not everywhere.

## Alternatives rejected (EN)
- **BLoC**: more boilerplate for no gain at this size.
- **setState only**: no separation; logic leaks into widgets.
- **Interfaces for everything** (e.g. `Money`): over-engineering; only abstract
  where change is expected.

## Consequences (EN)
- View never calls a service directly; it goes through a ViewModel that depends
  on interfaces (Dependency Inversion => UI independent of business logic).
- Mock-vs-real is a one-line provider override (Liskov substitution).

---

## Context (RO)
Aplicația trebuie să țină logica de business în afara widget-urilor, să fie
testabilă, modulară, și ușor de extins la feature-uri și clienți noi.

## Decizie (RO)
Folosim **MVVM** cu **Riverpod**. Widget-urile (View) sunt "proaste"; Notifier-ele
Riverpod sunt ViewModel-urile; domeniul (interfețe + modele) e Dart pur.
Dependențele se leagă într-o singură rădăcină de compoziție
(`lib/di/providers.dart`), pe care testele o suprascriu. SOLID se aplică **la
cusăturile care se schimbă** (backend, sursă de meniu, plată, notificări,
branding), nu peste tot.

## Alternative respinse (RO)
- **BLoC**: mai mult cod de umplutură, fără câștig la mărimea asta.
- **Doar setState**: fără separare; logica se scurge în widget-uri.
- **Interfețe pentru orice** (ex. `Money`): over-engineering; abstractizezi doar
  unde vine schimbarea.

## Consecințe (RO)
- View-ul nu cheamă niciodată direct un serviciu; trece printr-un ViewModel care
  depinde de interfețe (Dependency Inversion => UI independent de logică).
- Mock vs real e o suprascriere de o linie (substituție Liskov).

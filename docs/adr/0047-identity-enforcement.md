# ADR-0047: Server-side authorization for customer data (slice 3, enforcement)

- Status: Accepted
- Date: 2026-08-17

## Context (EN)
ADR-0046 keyed a customer's loyalty on their `customerId` (`cust:<phone>`), which
is derivable from a phone number. Without a check, anyone could read a customer's
history / redemptions / consent by putting a guessed `customerId` in the URL. This
slice enforces authorization (the SMS half of slice 3 stays blocked externally;
the enforcement half does not need it).

## Decision (EN)
- **Token issued at sign-in, checked on customer-scoped reads/writes.** The BFF
  already issues a bearer token on verify. Customer-scoped routes (customer
  orders, redemption list, redeem, consent get/set) now call `_authorized`: if the
  key is a **known customer** (`IdentityStore.isKnownCustomer`), a bearer token
  whose `customerForToken` equals that key is required, else `403`.
- **Anonymous keys stay open.** An anonymous `clientId` is a random device id, not
  derivable, so reading your own device data needs no token. Only identified
  customers (guessable ids) are gated. This keeps the anonymous flow working while
  closing the enumeration hole.
- **Client sends the token.** The remote sources (`RemoteHistorySource`,
  `RemoteRedemptionSource`, `RemoteConsentSource`) gained an `authToken`; the
  composition root passes the session token, so a signed-in customer's requests
  carry `Authorization: Bearer …`. Sign-in sets the session before writing consent,
  so the token is present.

## Alternatives rejected (EN)
- **Gate anonymous reads too.** They are self-scoped by an unguessable id;
  requiring auth there adds friction for no gain and breaks the anonymous flow.
- **Opaque-id customerIds (random, not phone-derived) instead of enforcement.**
  Security by obscurity; a real token check is the correct control and is needed
  anyway for writes.
- **A blanket auth middleware on every route.** Most routes are public (menu,
  submit) or staff-gated differently; scoping the check to customer routes is
  precise and avoids breaking them.

## Consequences (EN)
- A customer's data is now readable only by that customer (matching token); the
  guess-the-id hole is closed. Verified on the BFF handler.
- The client must be signed in for identified reads to succeed against the remote
  backend; anonymous and mock paths are unaffected (the mock ignores tokens, so
  tests are unchanged).
- This is per-customer authorization. Broader per-tenant staff/owner authorization
  (their surfaces still use a client-side access code) and real SMS remain later
  work; the token seam (`customerForToken`) is where they extend.

---

## Context (RO)
ADR-0046 a cheiat loialitatea pe `customerId` (`cust:<telefon>`), derivabil dintr-un
număr de telefon. Fără o verificare, oricine putea citi istoricul / revendicările /
consimțământul unui client punând un `customerId` ghicit în URL. Felia asta impune
autorizarea (jumătatea SMS a feliei 3 rămâne blocată extern; jumătatea de
enforcement nu are nevoie de ea).

## Decizie (RO)
- **Token emis la sign-in, verificat pe citirile/scrierile de client.** BFF-ul deja
  emite un bearer token la verify. Rutele de client (comenzi client, listă
  revendicări, redeem, consent get/set) apelează acum `_authorized`: dacă cheia e un
  **client cunoscut** (`IdentityStore.isKnownCustomer`), se cere un bearer token al
  cărui `customerForToken` egalează cheia, altfel `403`.
- **Cheile anonime rămân deschise.** Un `clientId` anonim e un id de dispozitiv
  aleator, nederivabil, deci citirea propriilor date nu cere token. Doar clienții
  identificați (id-uri ghicibile) sunt gated. Fluxul anonim merge mai departe, iar
  gaura de enumerare se închide.
- **Clientul trimite token-ul.** Sursele remote (`RemoteHistorySource`,
  `RemoteRedemptionSource`, `RemoteConsentSource`) au primit un `authToken`;
  rădăcina de compoziție pasează token-ul din sesiune, deci cererile unui client
  logat poartă `Authorization: Bearer …`. Sign-in-ul setează sesiunea înainte de
  scrierea consimțământului, deci token-ul e prezent.

## Alternative respinse (RO)
- **Gating și pe citirile anonime.** Sunt self-scoped printr-un id neghicibil; a
  cere auth acolo adaugă fricțiune degeaba și rupe fluxul anonim.
- **customerId opac (aleator, nu din telefon) în loc de enforcement.** Securitate
  prin obscuritate; o verificare de token reală e controlul corect și oricum e
  necesară pentru scrieri.
- **Un middleware de auth pe toate rutele.** Majoritatea rutelor sunt publice
  (meniu, submit) sau gated diferit pentru staff; restrângerea la rutele de client
  e precisă și nu le rupe.

## Consecințe (RO)
- Datele unui client sunt acum citibile doar de acel client (token care se
  potrivește); gaura „ghicește id-ul" e închisă. Verificat pe handler-ul BFF.
- Clientul trebuie să fie logat ca citirile identificate să reușească pe backendul
  remote; căile anonime și mock sunt neafectate (mockul ignoră token-urile, deci
  testele-s neschimbate).
- E autorizare per-client. Autorizarea mai largă per-tenant pentru staff/patron
  (suprafețele lor încă folosesc un cod de acces pe client) și SMS-ul real rămân
  muncă ulterioară; seam-ul de token (`customerForToken`) e locul de extindere.

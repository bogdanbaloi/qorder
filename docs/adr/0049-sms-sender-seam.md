# ADR-0049: SMS sender seam + OTP rate limiting

- Status: Accepted
- Date: 2026-08-18

## Context (EN)
OTP verification works end to end, but the code is delivered by a dev shortcut
(returned as `devCode`), not a real text. A real SMS provider is a paid external
dependency (account, sender-ID registration, per-message cost), so it is not wired
yet. This makes the code SMS-ready behind a seam and adds the anti-abuse control
that real SMS needs.

## Decision (EN)
- **`SmsSender` port.** `startChallenge` produces the code; the API calls
  `sms.send(phone, code)`. `DevSmsSender` (default) logs the code; a real adapter
  (Twilio / Infobip / Viber) drops in at the composition root, provider-agnostic.
- **`devCode` gated by a flag.** `OrderApi.exposeDevCode` (default true) echoes the
  code in the `/auth/otp/start` response for the no-SMS demo; production sets it
  false once a real sender is wired, and the response stops carrying the code.
- **OTP rate limiting.** `startChallenge` allows at most `_maxStartsPerWindow` (5)
  challenges per phone per `_rateWindowMs` (10 min); beyond that it returns null
  and the API responds `429`. Stops a bad actor from burning the SMS budget. The
  client shows a "could not send the code" message on failure.
- The client is unchanged: `RemoteIdentityService` already treats a null `devCode`
  as "no dev hint", so a production response with no code just hides the hint.

## Alternatives rejected (EN)
- **Wire a real provider now.** A paid account + sender-ID registration + API keys
  the app owner must set up; premature before a provider is chosen (SMS vs Viber
  vs a Romanian aggregator).
- **Rate limit in the API layer.** The store owns the challenge lifecycle, so the
  window lives with it; the API just maps null to `429`.
- **Drop `devCode` entirely now.** The demo needs the code without reading server
  logs; the flag keeps the demo working and flips off cleanly for production.

## Consequences (EN)
- Swapping to real SMS is a one-line composition-root change plus
  `exposeDevCode: false`; no client or flow changes.
- The rate limit protects the SMS budget from day one, even on the dev sender.
- The app owner still must choose a provider, create the account and set the API
  key via env (never in the repo); that stays their step.

---

## Context (RO)
Verificarea OTP merge cap-coadă, dar codul e livrat printr-o scurtătură de dev
(întors ca `devCode`), nu printr-un SMS real. Un provider SMS real e o dependență
externă plătită (cont, înregistrare sender-ID, cost per mesaj), deci nu e cablat
încă. Asta face codul „SMS-ready" în spatele unui seam și adaugă controlul anti-abuz
de care are nevoie SMS-ul real.

## Decizie (RO)
- **Port `SmsSender`.** `startChallenge` produce codul; API-ul cheamă
  `sms.send(phone, code)`. `DevSmsSender` (default) loghează codul; un adaptor real
  (Twilio / Infobip / Viber) intră în rădăcina de compoziție, agnostic de provider.
- **`devCode` controlat de un flag.** `OrderApi.exposeDevCode` (default true) întoarce
  codul în răspunsul `/auth/otp/start` pentru demo-ul fără SMS; producția îl pune pe
  false când e cablat un sender real, iar răspunsul nu mai poartă codul.
- **Rate limit pe OTP.** `startChallenge` permite cel mult `_maxStartsPerWindow` (5)
  challenge-uri per telefon per `_rateWindowMs` (10 min); peste asta întoarce null și
  API-ul răspunde `429`. Oprește un rău-voitor să ardă bugetul de SMS. Clientul arată
  „nu s-a putut trimite codul" la eșec.
- Clientul e neschimbat: `RemoteIdentityService` tratează deja un `devCode` null ca
  „fără hint de dev", deci un răspuns de producție fără cod doar ascunde hintul.

## Alternative respinse (RO)
- **Cablarea unui provider real acum.** Cont plătit + înregistrare sender-ID + API
  key-uri pe care le setează proprietarul app-ului; prematur înainte de a alege
  providerul (SMS vs Viber vs agregator RO).
- **Rate limit în stratul API.** Store-ul deține ciclul challenge-ului, deci
  fereastra stă cu el; API-ul doar mapează null la `429`.
- **Scoaterea completă a lui `devCode` acum.** Demo-ul are nevoie de cod fără să
  citească log-uri; flag-ul ține demo-ul funcțional și se stinge curat pt producție.

## Consecințe (RO)
- Trecerea la SMS real e o schimbare de o linie în rădăcina de compoziție plus
  `exposeDevCode: false`; fără schimbări de client sau de flux.
- Rate limit-ul protejează bugetul de SMS din prima zi, chiar și pe dev sender.
- Proprietarul app-ului tot trebuie să aleagă un provider, să facă contul și să pună
  API key-ul prin env (niciodată în repo); ăsta rămâne pasul lui.

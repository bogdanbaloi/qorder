# Demo qorder — ghid complet

Ghid de prezentare pentru client (patron de local). Ține-l deschis pe telefon.

## 1. Pornire (o singură comandă)

Din folderul `qorder`, în Git Bash:

```bash
bash demo.sh
```

Pornește backend-ul + aplicația și afișează link-urile pentru telefoane (aceeași
rețea WiFi). Deschide-le în **Chrome/Safari**, cu `http://` în față (nu în
căutarea Google).

| Persoană | Link | Cod |
|---|---|---|
| Client (masă) | `http://<ip>:8082/#/t/7` | — |
| Cont / fidelitate | `http://<ip>:8082/#/me` | OTP demo: **000000** |
| Ospătar | `http://<ip>:8082/#/waiter` | **2468** |
| Patron | `http://<ip>:8082/#/owner` | **1357** |

Oprești tot cu `Ctrl+C`.

## 2. Reguli de aur (înainte să începi)

- **Comandă întâi, apoi arăți patronul** — să aibă cifre pe dashboard.
- **Pentru puncte, loghează-te înainte să comanzi** (comenzile se leagă de client).
- **Nu reporni backend-ul** în timpul demo-ului — e in-memory, repornirea șterge tot.
- Scanner-ul QR de masă nu merge pe telefon pe `http` (cere context securizat) —
  folosește link-ul `/t/7`. Restul (OTP, puncte, comenzi) merge pe `http`.

## 3. Ce e nou de la ultima întâlnire (punctual)

### Fidelitate — clientul e al TĂU (nou, complet)
- Cont de client cu autentificare pe **telefon + cod (OTP)**.
- **Puncte** din cheltuială + **scară de recompense** (100/250/500 puncte).
- **Chip de puncte** în bara de meniu (vezi punctele cât comanzi).
- **Istoric de comenzi** în cont.
- **Revendicare recompensă**: cod de arătat ospătarului, validat de el.
- **Identitate cross-device**: punctele urmează clientul pe orice telefon.
- **Consimțământ** captat la înscriere (GDPR), per local.

### Patron — dashboard îmbogățit
- **Valoare medie comandă**.
- **Comparație față de ziua precedentă** (comenzi + încasări).
- **Vânzări pe oră** (grafic).
- **Top produse** (cele mai vândute).
- (aveam deja: încasări azi, comenzi, timpi medii acceptare/livrare, grafic
  zilnic, snapshot live pending / în lucru / cereri).

### Client — comandă
- **Reparat**: după ce plasezi o comandă, coșul arată din nou „Trimite comanda"
  când adaugi produse noi (înainte rămânea blocat pe „Comandă nouă").
- Salut pe cont + confirmare la înscriere (mici touch-uri de intuitivitate).

### Securitate / backend (invizibile în demo, de menționat verbal)
- Autorizare **pe server** pentru datele clientului: nimeni nu-ți poate citi
  comenzile ghicind un id.
- Autorizare **staff/patron pe token**, per local (per-tenant).
- Pregătit pentru **SMS real** (acum cod demo) + protecție anti-abuz (rate-limit).
- **Multi-local**: fiecare local are configul lui (branding, meniu, mese,
  loialitate) ca **date**, nu cod. Un singur app servește toate localurile, iar
  QR-ul duce localul + masa. **Nu arăta la demo** (e sub capotă), doar menționează.
- **Persistență pe bază de date** (Postgres multi-tenant): datele localurilor sunt
  durabile și izolate între ele. **Nu arăta la demo** (demo-ul rulează in-memory),
  doar menționează că e pregătit pentru producție.

### Peste tot
- Interfață **RO / EN** pe toate ecranele (client, ospătar, patron).
- **Agnostic de POS**: merge pe orice casă (inclusiv Ebriza) sau fără casă.

## 4. Scenariu de 5 minute (ordine)

1. Pe laptop, deschide **ospătar** + **patron** în 2 tab-uri.
2. Pe telefon `/#/t/7`: comanzi 1-2 beri → confirmi. Comanda apare la ospătar →
   **Confirmă** → **Gata** → **Livrat**.
3. Adaugi alt produs → arăți că butonul **„Trimite comanda" merge** (bug reparat).
4. `/#/me` → intră cu telefonul (000000) → comandă ~100 lei → arăți **punctele +
   chip-ul** → **Folosește** recompensa → validezi pe ecranul de ospătar.
5. `/#/owner` → arăți **încasările, media, top produse, graficele**.

## 5. Ce spui la fiecare ecran (client = patron, nu tehnic)

**Deschidere**
> „De la ultima dată am dus-o de la comandă simplă la un sistem complet: clientul
> comandă singur, ospătarul vede tot live, tu îți vezi cifrele și îți ții clienții."

**Client — `/#/t/7`**
> „Scanează QR-ul de la masă, ajunge pe meniul tău, cu poze, prețuri, happy hour.
> Comandă singur, vede live unde e comanda lui. Nu mai strigă după ospătar."

**Ospătar — `/#/waiter` (2468)**
> „Vede comanda instant, cu masa și cine a comandat. Confirmă, gata, livrat. Vede
> și cât a așteptat fiecare masă. Nu mai uită nimeni nimic."

**Patron — `/#/owner` (1357)**
> „Vezi totul fără să întrebi pe nimeni: încasările de azi, valoarea medie, cum
> merge față de ieri, la ce oră vinzi, ce se vinde cel mai bine. Din telefon."

**Cei doi timpi de pe dashboard (unde: ecranul patron `/#/owner`, cardurile de sus):**

- **Timp mediu preluare** = de când **clientul trimite** comanda până când
  **ospătarul o confirmă** (submit -> accept). Îți arată cât de repede sare
  personalul pe comenzile noi. Mare = clienții așteaptă la început.
- **Timp mediu livrare la masă** = de când **băutura e gata** până când **ajunge
  la masă** (ready -> delivered). E gap-ul bar -> masă, **separat** de timpul de
  preparare. Mare = băuturile stau gata pe bar și nu le duce nimeni.

> La demo: „Ăștia doi timpi îți spun unde pierzi clienți — dacă preluarea e mare,
> pui mai mult personal la comenzi; dacă livrarea e mare, băuturile stau pe bar.
> Le vezi mediate live, nu le ghicești."

Notă: apar când există comenzi în lucru cu ștampilele respective. La demo,
comandă întâi (confirmă -> gata -> livrat) ca să ai cifre.

**Fidelitate — `/#/me` (000000)** — piesa de vânzare
> „Asta e diferența față de Glovo: clientul e al TĂU. Se logează cu telefonul,
> adună puncte, îl aduci înapoi cu recompense. Ai datele lui, nu un intermediar
> care ia 30%. Și punctele îl urmăresc pe orice telefon."

**Închidere**
> „Totul e pregătit pentru orice casă de marcat, inclusiv Ebriza-ul tău. E RO și
> EN. Următorul pas: îl punem pe localul tău, cu meniul și brandul tău."

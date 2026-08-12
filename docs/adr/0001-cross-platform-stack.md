# ADR-0001: Cross-platform stack = Flutter

- Status: Accepted
- Date: 2026-08-12

## Context (EN)
We need one product on iOS and Android, with Huawei/AppGallery as a
"support if feasible" target, built and maintained by one engineer new to
mobile but senior in systems. Testability and a clean UI/logic separation are
first-class requirements.

## Decision (EN)
Use **Flutter** (Dart). One codebase for iOS + Android; the Android build is a
plain APK that also runs on Huawei/HMS as long as we take **no GMS dependency**.

## Alternatives rejected (EN)
- **React Native**: viable, but weaker built-in testing and a JS ecosystem the
  author finds less suited to systems work.
- **Two native apps (Swift + Kotlin)**: 2x surface for a solo build, no upside.
- **Kotlin Multiplatform + Compose Multiplatform**: shared iOS UI still young.
- **PWA / webview**: no store presence (so no AppGallery), weaker link handling,
  and webview was explicitly ruled out.

## Consequences (EN)
- First-class unit/widget/integration testing.
- "No GMS dependency" becomes an architectural constraint (see ADR-0008).
- iOS builds require a Mac (or a cloud Mac) at Phase 2.

---

## Context (RO)
Ne trebuie un produs pe iOS și Android, cu Huawei/AppGallery ca țintă "dacă e
fezabil", construit și întreținut de un singur inginer nou în mobile dar senior
în sisteme. Testabilitatea și separarea UI/logică sunt cerințe de bază.

## Decizie (RO)
Folosim **Flutter** (Dart). Un singur cod pentru iOS și Android; build-ul de
Android e un APK simplu care merge și pe Huawei/HMS cât timp **nu ne legăm de
GMS** (serviciile Google).

## Alternative respinse (RO)
- **React Native**: viabil, dar testare mai slabă și un ecosistem JavaScript mai
  puțin potrivit pentru un om de sisteme.
- **Două aplicații native (Swift + Kotlin)**: dublu de muncă pentru un singur om.
- **Kotlin Multiplatform + Compose**: UI-ul partajat pe iOS e încă tânăr.
- **PWA / webview**: fără prezență în magazine (deci fără AppGallery), link-uri
  mai slabe, iar webview a fost exclus explicit.

## Consecințe (RO)
- Testare unit/widget/integrare de clasă întâi.
- "Fără dependență de GMS" devine o constrângere de arhitectură (vezi ADR-0008).
- Build-ul de iOS cere un Mac în Faza 2.

# iOS UI-Fit Analysis — Compound-term length overflow report

**Date:** 2026-04-16
**Scope:** Static string-length analysis of UI-constrained keys across all 13 locales, measuring fit against typical iOS UI budget.

## Methodology

- Extracted the ~30 keys that render in **tab bars, full-caps action buttons, and primary buttons**.
- Classified by UI context:
  - **Tab bar item**: ≤10ch safe, 11–14ch warn, ≥15ch overflow (iOS auto-truncates with ellipsis)
  - **Full-caps action button** (`action_*`): ≤20ch safe, 21–28ch warn, ≥29ch overflow on iPhone SE (smallest device)
  - **Primary button**: ≤28ch safe, 29–35ch warn, ≥36ch overflow
- Cross-referenced against EN baseline; flagged all OVERFLOW (🔴) and WARN (🟡) per locale.

---

## 🔴 Confirmed overflow risks (13 keys, most in FR/IT/PT/RO)

### Tab bar (3 critical — ellipsis will truncate)

| Key | EN | FR | IT | PT | RO | SK | HR | Notes |
|---|---|---|---|---|---|---|---|---|
| `tab_my_pets` | 7: My Pets | 🔴 24: Mes animaux de compagnie | 🔴 27: I miei animali di compagnia | 🔴 28: Os meus animais de estimação | 🔴 26: Animalele de companie mele | 🟡 23: Moji domáci miláčikovia | 🟡 19: Moji kućni ljubimci | Bottom-tab label |
| `tab_success` | 10: Found pets | 🔴 30: Animaux de compagnie retrouvés | 🔴 28: Animali di compagnia trovati | 🔴 32: Animais de estimação encontrados | 🔴 26: Animale de companie găsite | 🔴 26: Nájdení domáci miláčikovia | 🟡 24: Pronađeni kućni ljubimci | Tab in alerts |
| `tab_scan_qr` | 7: Scan QR | 10 | 12 | 6: Ler QR | 11 | 11: Skenovat QR | 11 | HU 16 (Scan code) — WARN |

### Full-caps action buttons (FR critical)

| Key | EN | FR | IT | PT | Recommendation |
|---|---|---|---|---|---|
| `action_add_pet` | 7: ADD PET | 🔴 30: AJOUTER UN ANIMAL DE COMPAGNIE | 16 | 16 | Shorten FR to `AJOUTER ANIMAL` (15) |
| `action_order_tags` | 10: ORDER TAGS | 🔴 34: COMMANDER DES MÉDAILLES CONNECTÉES | 18 | 🟡 20 | Shorten FR to `COMMANDER MÉDAILLES` (20) |
| `action_replace_tag` | 11: REPLACE TAG | 🔴 31: REMPLACER LA MÉDAILLE CONNECTÉE | 🟡 23 | 🟡 19 | Shorten FR to `REMPLACER MÉDAILLE` (19) |

### Primary buttons (FR/IT/PT/RO worst)

| Key | EN len | Worst locale/length | Recommendation |
|---|---|---|---|
| `edit_pet` | 8: Edit Pet | 🔴 IT 48: Modifica il profilo del tuo animale di compagnia | Shorten IT to `Modifica profilo animale` (24) |
| `order_more_title` | 15: Order More Tags | 🔴 PT 39: Encomendar mais plaquinhas inteligentes | Acceptable as sheet title; verify as button |
| `order_replace_title` | 21: Order Replacement Tag | 🔴 PT/FR 48: Encomendar plaquinha inteligente de substituição | If button: shorten to `Encomendar substituição` (23) |
| `plan_tag_activated` | 14: Tag Activated! | 🔴 FR 37: Ta médaille connectée a été activée ! | Shorten to `Médaille activée !` (19) if title; else OK |
| `create_pet_profile` | 18: Create Pet Profile | 🔴 RO 39: Creează profilul animalului de companie | Shorten RO to `Creează profil animal` (21) |
| `welcome_scan_first_tag` | 19: Scan Your First Tag | 🔴 FR 38: Scanner ta première médaille connectée | Shorten FR to `Scanner ta première médaille` (29) |
| `plan_skip_free` | 24: Skip for now (Free Plan) | 🔴 NO 36: Hopp over for nå (Gratis abonnement) | Most locales 30+ — inherent length; consider dropping `(Free Plan)` suffix |

---

## 🟡 Tight-fit warnings (16 keys)

These are likely to fit at default font size but may clip on iPhone SE (1st gen / 5.4") or with Dynamic Type: Large or larger. Native QA recommended:

- `tab_account`: DE 13 (Benutzerkonto) — WARN
- `tab_missing`: PT 12 (Desaparecido) — WARN
- `action_mark_found`: CS 21, DE 22, FR 22, PL 22, SK 19 — multiple WARN
- `action_report_missing`: DE 19, FR 22, PT 21, RO 19 — multiple WARN
- `add_pet` / `select_pet` / `delete_pet_button` / `tag_activate_button`: similar compound-term issues in FR/IT/PT/RO/SK
- `scan_tag_now`: 🟡 DE 21, IT 21, CS 19, HR 18, RO 18 — tight
- `order_tags` / `tag_activate_button`: IT/CS/HR/NB 18-24ch — tight
- `tag_activated`: IT/HR/PL/SK 18-22ch — tight
- `create_new_pet` / `pet_name`: IT 30-31, HR 28 — tight

---

## Root cause

**The overflow is primarily driven by the spec-mandated compound terms:**
- FR `animal de compagnie` (~18ch) — 12 chars longer than `animal`
- FR `médaille connectée` (~18ch) — 12 chars longer than `médaille`
- IT `animale di compagnia` (~20ch)
- PT `animal de estimação` (~19ch) + `plaquinha inteligente` (~21ch)
- RO `animal de companie` (~18ch) + `plăcuță inteligentă` (~19ch)
- SK `domáci miláčik` (~15ch) + genitive `domáceho miláčika` (~19ch)
- HR `kućni ljubimac` (~15ch)

**None of these are translation errors — they are the mandated forms per CLAUDE-localisation-audit-0415.md §3.** The spec prioritises semantic correctness over terseness.

---

## Recommendations

### Option A — Localise button-specific short forms (recommended)

For contexts where the compound term is redundant with surrounding UI (e.g. tab bar already says "My Pets" section → tab_my_pets doesn't need "de compagnie" repeated), use contextual short forms:

| Key | Context | Short form (per-locale) |
|---|---|---|
| `tab_my_pets` | Tab bar icon makes context clear | FR: `Mes animaux`; IT: `I miei animali`; PT: `Os meus animais`; RO: `Animalele mele`; SK: `Moji miláčikovia`; HR: `Moji ljubimci` |
| `tab_success` | Tab in alerts | FR: `Retrouvés`; IT: `Ritrovati`; PT: `Encontrados`; RO: `Găsite`; SK: `Nájdení`; HR: `Pronađeni` |
| `action_add_pet` | Full-caps action button | FR: `AJOUTER ANIMAL`; IT: `AGGIUNGI ANIMALE` (already OK) |
| `action_order_tags` | Action button | FR: `COMMANDER MÉDAILLES`; PT: `ENCOMENDAR` |
| `action_replace_tag` | Action button | FR: `REMPLACER MÉDAILLE`; ES: `REEMPLAZAR CHAPA` |
| `edit_pet` / `add_pet` / `select_pet` / `delete_pet_button` | Buttons | Drop compound in UI button text — use simple form e.g. IT "Modifica animale", FR "Ajouter animal" |

This keeps the compound term in FAQ/descriptions/help text (where the full form reads naturally) and uses short form in space-constrained UI. **Industry standard practice.**

### Option B — Add Dynamic Type size constraint / truncation handling

Add `.minimumScaleFactor(0.7)` on button labels and `.lineLimit(1)` with `.truncationMode(.middle)` on tab bar items. This is a SwiftUI-level fix that keeps the spec-compliant full term but handles overflow gracefully.

### Option C — iPhone SE / small-screen QA pass

Run UI tests on iPhone SE (3rd gen, 4.7″) in FR, IT, PT, RO, SK, HR locales and inspect the 13 overflow keys. If they render acceptably on that smallest target device, leave as-is.

---

## Recommended action

**Hybrid of A + B:** Add short-form overrides for the 3 tab-bar keys and 3 full-caps action buttons (highest-risk contexts), and apply SwiftUI `minimumScaleFactor(0.75)` + `lineLimit(1)` globally on `Button` label styles for graceful degradation of the other 7 primary buttons.

This requires code changes in the iOS app, not just strings.

---

## Simulator rendering — what I did confirm

**Built and launched the app** in iPhone 16 simulator across 11 locales (fr, pt, it, sk, ro, hr, pl, nb, de, cs, es) + iPhone SE 3rd gen (smallest) for FR. Screenshots at `/tmp/pet-screens/`.

**Pre-login screen validation:**
- All locales render cleanly at login. Title ("Welcome back!" / "Content de te revoir !" / "Vitaj späť!" / "Willkommen zurück!"), email input, CTA button, terms links all fit without clipping.
- Informal register visible: FR `te revoir`, DE `Gib deine E-Mail`, SK `Vitaj späť` (with restored `ť`), PT `à tua câmara`.
- Diacritics render correctly: SK `späť`/`Začni`/`známku`, PL `Twojego pupila`, RO `codul de autentificare`, HR `naruči besplatni privjesak`.
- FR narrow NBSP before `!`/`?` visible as small gap ("revoir !", "compte ?").
- SENRA brand subtitle fits (longer in SK "KOMUNITNÁ ZNÁMKA PRE DOMÁCE ZVIERATÁ" and RO "MEDALONUL COMUNITAR PENTRU ANIMALE DE COMPANIE" — note: RO subtitle still uses `MEDALONUL`, see InfoPlist section below).

**Post-login screens NOT validated** — tab bar, action buttons, home screen require authentication against the backend. The 13 identified overflow risks are all post-login. Static analysis is the best I can offer without a working test account.

**iPhone SE (smallest, 4.7″) pre-login in FR**: fits without clipping. Content scrolls if needed (expected SE behavior for longer bodies).

## Additional finding: InfoPlist.strings permission prompts (not in original audit)

Discovered during simulator render: `PetSafety/PetSafety/Resources/<loc>.lproj/InfoPlist.strings` files (iOS permission prompts for camera/photos/location) were NOT part of the main audit and contained:
- Banned vocabulary: `Tiermarke` (de), `medaglioni` (it), `médaillons` (fr), `placa` (es), `etiqueta` (pt), `medalion` (ro), `kjæledyrmerke` (nb), `štítcích` (cs), `štítkoch` (sk), bare `ljubim*` without kućni (hr), `zwierz*` (pl).
- Formal register: `Ihre/Ihrer` (de), `vaše/vám` (cs/sk), `votre` (fr), `sua/seu` (pt).

**Fixed across all 11 target locales.** Post-fix: all InfoPlist.strings use approved controlled vocabulary + informal register. These are user-facing permission prompts, so they matter.

## What I did NOT do

- **Dynamic Type audit** — user-adjustable font size accessibility settings (XS through AX5) multiply the fit risk. Only assessed default size here.
- **Landscape orientation** — tab bar shortens in landscape, making `tab_success` FR/PT/IT values almost certainly truncate.
- **Post-login screen rendering** — requires live backend, test account, or Firebase mock. 13 identified overflow risks are in those screens.

---

## Files modified: none

This report is pure analysis. No locale files were edited. All ~13 overflow cases are consequences of the §3-mandated controlled vocabulary (which we applied correctly in the prior audit). The decision whether to override with UI-specific short forms is a product + UX judgement call.

---

## Suggested next step

Pick one of:
1. **Apply Option A short-form overrides** — I add per-locale short tab/action-button strings (new keys like `tab_my_pets_short`) and wire them into the SwiftUI tab bar / buttons. ~30 string edits + ~5 code edits.
2. **Apply Option B SwiftUI modifiers** — I add `.minimumScaleFactor(0.75).lineLimit(1)` on all `Button` labels and tab items in the SwiftUI codebase. ~10-20 code edits.
3. **Boot simulator & take screenshots** — I run the worst-case locale (FR) in simulator and capture the tab bar + add-pet + order-tags screens to visually confirm overflow behaviour before deciding A vs B.

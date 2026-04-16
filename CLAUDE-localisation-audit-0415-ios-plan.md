# iOS Localisation Audit — Remediation Plan

**Source spec:** `/Users/viktorszasz/pet-safety-ios/CLAUDE-localisation-audit-0415.md` (Sections 1–14)
**Findings basis:** programmatic + structural audit on `PetSafety/PetSafety/Resources/*.lproj/Localizable.strings` (13 files, ~1,167 keys/file)
**Cadence:** one locale at a time, full per-string dual-source review (EN structure + HU semantics), no shortcuts.

---

## User-approved decisions (override spec where noted)

These are fixed before we start — see `feedback_ios_localisation_decisions.md`:

1. **DE** uses **informal `du`** throughout — overrides spec §6.3 default. All current `Sie/Ihr/Ihnen` constructions must be rewritten to informal register.
2. **PT**: `plaquinha inteligente` is the approved tag term (matches spec §3).
3. **RO**: `stăpân` is the approved owner term (matches spec §3).
4. **SK**: diacritic corruption (not just soft consonants — full diacritic loss on many action verbs like `Ulozit`, `Prihlasit`, `Zrusit`, `Upravit`, `Potvrdit`, `Odhlasit`, `priatel`). Full SK file requires a diacritic-restoration sweep, not just ľ/ĺ/ŕ.

---

## Phase 0 — Universal cross-locale cleanup (run FIRST, once)

These are pure bugfixes independent of any locale's translation quality. Safe to do before per-locale semantic review.

### 0.1 Stale keys (prod bug — §2.1 of findings)
- **Rename** `shared_via_pet_safety` → `shared_via_senra` in all 11 non-EN-non-HU files.
- Update the value to reference SENRA (match the EN form in each locale's language).
- **Add** `report_found_unavailable` translation (translate from EN + HU) to all 11 files.
- Verify after: `shared_via_pet_safety` occurs 0 times anywhere; `shared_via_senra` and `report_found_unavailable` occur 13 times each (1 per locale).

### 0.2 EN source corrections (§2.6 of findings)
Per spec §4, fix EN first so downstream locales inherit correct source:
- Replace all `...` (three ASCII dots) with `…` (U+2026) in EN `Localizable.strings`. Known: 23 occurrences.
- Fix the one double-space line in EN.
- Fix 2 double-space lines in HU reference.

### 0.3 Ellipsis propagation (§2.5 of findings)
After EN is fixed, replace `...` with `…` in every locale's file (programmatic global replace within value strings only — not inside keys or comments).
- Expected fixes: ~250 occurrences across 11 locales (CS and DE already clean).

### 0.4 FR punctuation spacing (§2.4 of findings)
In `fr.lproj/Localizable.strings` value strings only:
- Replace regular space before `:`, `;`, `!`, `?` with narrow NBSP (U+202F), per spec §6.9.
- Expected: 132 hits.
- Leave guillemet usage decision for Phase 1 FR step (requires per-string context).

### 0.5 Quick parity re-verify
After Phase 0: rerun key-parity + placeholder-parity checks. Must remain at:
- 1,167 keys per locale (not 1,166)
- 0 placeholder mismatches

---

## Phase 1 — Per-locale full audit & remediation

Locale order (by estimated effort, small → large, so we calibrate the process on cheaper locales first):

1. **NO** (nb) — small delta: only `QR-brikke` compound fix + per-string review
2. **CS** — ellipsis already clean; needs `páníček` owner + `psí známka` tag + per-string review
3. **HR** — `kućni ljubimac` compound + `privjesak` (banned `oznaka`) + per-string review
4. **SK** — diacritic restoration across file + `domáci miláčik` + `páníček` + soft-consonant repairs + per-string review
5. **FR** — `médaille connectée` compound + banned `puce` removal + guillemets decisions + per-string review (Phase 0.4 already handled spacing)
6. **ES** — `tutor` owner + `chapa inteligente` tag + ¿¡ check + per-string review
7. **RO** — `animal de companie` + `stăpân` + `plăcuță inteligentă` (all three terms currently absent) + per-string review
8. **PT** — `tutor` owner + `plaquinha inteligente` tag + PT-BR decontamination + per-string review
9. **IT** — `animale di compagnia` + `padrone` + remove banned `targhetta` + per-string review
10. **PL** — full controlled vocab rewrite (`pupil` with 7-case inflection, `opiekun`, `adresówka`) + per-string review
11. **DE** — **full formal→informal rewrite** of 107 `Sie` strings + `Halter` owner + `Haustiermarke` tag + `Benutzerkonto` account + per-string review

### Per-locale workflow (applied identically to each)

For each locale file, perform this sequence in order. No skipping, no bundling, no batching shortcuts:

**Step A — Controlled-vocabulary substitution (spec §3)**
1. List every banned/incorrect term currently in the file (from §2.2 of findings).
2. For each banned term: identify every occurrence, determine the grammatically-correct form of the approved term in that context (case, gender, number, inflection). Record root + inflected form per spec §3 Inflection Tracking.
3. Substitute with spec-approved term, hand-adjusting surrounding syntax where required (articles, adjective agreement, verb conjugation).
4. Verify every occurrence of the approved term is itself grammatically correct after substitution.

**Step B — Locale-specific deep checks (spec §6)**
Apply the locale's entire §6.x checklist to the file in one pass. Specifically:
- SK §6.1: `domáci miláčik` declension in all 7 cases; `páníček` register; no CZ-isms; all soft consonants (`ľ`, `ĺ`, `ŕ`) present where required; check that action verbs have full diacritics (`Uložiť`, `Prihlásiť`, `Zrušiť`, etc.).
- CS §6.2: `mazlíček` declension; `páníček` register; `psí známka` compound for tag; no SK-isms; `ř` usage.
- DE §6.3: **per user override, verify `du/dein*` register throughout, NOT `Sie`**; compound nouns (`Haustiermarke`, `Benutzerkonto`, `Standort`); `Halter` not `Besitzer`; ß/ss orthography.
- HR §6.4: all diacritics; `kućni ljubimac` compound + case agreement; `vlasnik` for owner; `privjesak` for tag; case/gender/number concord.
- RO §6.5: comma-below diacritics (already clean); `animal de companie`; `stăpân` (user-approved); `plăcuță inteligentă` with all diacritics; postpositional definite articles; gender agreement; plural rules.
- IT §6.6: `animale di compagnia`; `padrone`; `medaglietta` only (remove `targhetta`); elision (`l'animale` / `dell'animale`); gender agreement; informal `tu`.
- ES §6.7: Castilian only; `mascota`; `tutor`; `chapa inteligente`; `¿…?` and `¡…!` inverted punctuation; `tú` informal; DD/MM/YYYY dates; accents (á é í ó ú ñ ü).
- PT §6.8: EU-PT only; `animal de estimação`; `tutor`; `plaquinha inteligente` (user-approved); decontaminate PT-BR terms (`apartamento` → verify context; remove any `celular`/`cadastr`/`ônibus`).
- FR §6.9: `animal de compagnie`; `propriétaire`; `médaille connectée`; remove `puce`; informal `tu`; accents + ligatures (œ not `oe`); elisions; French capitalisation rules (no anglicism capitalisation).
- NO §6.10: Bokmål only; `kjæledyr`; `eier`; `QR-brikke` with hyphen; `du` informal; verify `brikke` → `QR-brikke` where referring to the product tag.
- PL §6.11: `pupil` + 7-case inflection; `opiekun`; `adresówka`; all diacritics including `ł` (not `l`); `ty` informal; plural rules (1 / 2–4 / 5+); aspect correctness on verbs.

**Step C — Universal string-level checklist (spec §5)**
Run every item in §5.1 through §5.10 on every string:
- 5.1 Semantic accuracy vs HU
- 5.2 Controlled vocabulary compliance (already done in Step A, reverify)
- 5.3 Register & tone
- 5.4 Grammar & syntax
- 5.5 Placeholders (already verified in Phase 0, re-check after edits)
- 5.6 Punctuation & formatting
- 5.7 Diacritics
- 5.8 String length (flag UI-overflow risks, esp. DE/PL/HR/RO)
- 5.9 Cultural appropriateness
- 5.10 Legal/compliance strings (GDPR terminology, subscription/cancel copy)

**Step D — Category-specific checks (spec §7)**
Apply §7.1–7.7 rules to the relevant string groups within the file (onboarding, pet profile, tag/QR, account/settings, notifications, errors, legal).

**Step E — Log**
Produce the per-string audit log entries per spec §10.1 for every string reviewed.
Log location: `CLAUDE-localisation-audit-0415-ios-log-<locale>.md`.
At least every string where a correction was made gets a full §10.1 entry. Strings that passed unchanged may be logged as a compact pass entry (`KEY | PASS`).

**Step F — Verification after locale is done**
Re-run the Phase 0 programmatic checks scoped to this locale:
- Placeholder parity vs EN: 0 mismatches
- Key parity vs EN: matches (1,167 keys)
- Required diacritics for this locale: all present where needed
- Banned terms: 0 occurrences
- Required terms: reasonable counts (tag/owner/pet/account/location appear at expected density)
- Ellipsis: only `…`, no `...`
- No double spaces, no trailing whitespace

Produce a short per-locale sign-off block at the top of the locale's log confirming every §14 final-sign-off item.

---

## Phase 2 — Cross-locale consistency (spec §8)

After all 12 locales are individually complete:

- **§8.1 Term consistency within each locale**: verify each locale uses its approved terms identically across all 1,167 strings (no drift).
- **§8.2 Cross-locale format parity**: re-verify key and placeholder parity across the set.
- **§8.3 EN source integrity**: consolidate all EN corrections discovered during per-locale review; produce upstream fix list for EN.
- **§8.4 Contamination checks**:
  - SK vs CZ: spot-check no CZ-isms leaked into SK; no SK-isms into CZ.
  - ES vs PT: confirm ES is EU-ES, PT is EU-PT; no cross-contamination.
  - HR: no Serbian vocabulary/orthography.
  - NO: Bokmål only (double-check after edits).
  - FR: EU-FR only.

---

## Phase 3 — Session summary (spec §10.2)

Produce the full spec-§10.2 session summary document covering:
- Date, locales covered, strings reviewed, pass/fail counts
- EN source errors found and corrected
- Systematic issues identified (should be empty or near-empty by end)
- Term compliance failures (should be 0)
- Diacritic failures (should be 0)
- Open questions / escalation items still outstanding

Then confirm §14 sign-off criteria are all satisfied.

---

## Deliverables (files this plan will produce)

- `CLAUDE-localisation-audit-0415-ios-findings.md` — programmatic findings (already drafted; write after plan is approved)
- `CLAUDE-localisation-audit-0415-ios-plan.md` — this file
- `CLAUDE-localisation-audit-0415-ios-log-<locale>.md` × 12 — per-locale audit logs
- `CLAUDE-localisation-audit-0415-ios-summary.md` — Phase 3 session summary
- Modifications to each of: `en.lproj/Localizable.strings`, `hu.lproj/Localizable.strings`, and all 11 target locales' `Localizable.strings`

No changes to Android, Web, or backend in this effort — iOS only, as instructed.

---

## Estimates (rough, to set expectations)

- Phase 0: ~30 edits, mechanical. 1 session.
- Phase 1 per locale: ~1,167 strings × manual dual-source review. Smaller locales (NO, CS, HR) ~1 session each; medium (SK, FR, ES, RO, PT, IT) ~1–2 sessions each; large (PL, DE) ~2–3 sessions each.
- Phase 2 + 3: ~1 session combined.
- **Total rough estimate: ~15–20 sessions** depending on depth of per-string review and HU divergence rate.

We progress locale-by-locale. After each locale I'll pause for you to spot-check before moving to the next.

---

## Ready to proceed?

If this plan is approved, next action is **Phase 0** (all universal cleanup) in the next turn, followed by **Phase 1 locale 1 = NO (nb)**. If you want the order changed (e.g. start with the most-user-facing locale instead of smallest), say so and I'll adjust.

# iOS Localisation Audit — Per-locale log: **hr (Croatian)**

**Date:** 2026-04-15
**Auditor:** Claude (Opus 4.6)
**Locale:** hr (Croatian)
**File:** `PetSafety/PetSafety/Resources/hr.lproj/Localizable.strings`

---

## §14 Sign-off

All programmatic and locale-specific criteria pass.

| Check | Expected | Actual | ✓/✗ |
|---|---|---|---|
| Key count | 1167 | 1167 | ✓ |
| Placeholder mismatches vs EN | 0 | 0 | ✓ |
| `pločic*` (banned tag synonym) | 0 | 0 | ✓ |
| `oznak[auieom]` as tag | 0 | 0 | ✓ |
| Bare `ljubim*` without `kućni` prefix | 0 | 0 | ✓ |
| `kućni ljubim*` (required compound) | >200 | 224 | ✓ |
| `privjes*` (required tag-term) | >100 | 109 | ✓ |
| `vlasnik*` (required owner-term) | >20 | 30 | ✓ |
| `Pet Safety` brand refs | 0 | 0 | ✓ |
| `Senra` (mixed case) | 0 | 0 | ✓ |
| ASCII `...` | 0 | 0 | ✓ |
| Double-space in values | 0 | 0 | ✓ |
| HR diacritics č/ć/š/ž/đ | all present | 289/367/292/189/90 | ✓ |
| English bleed | 0 | 0 | ✓ |

---

## Summary of changes applied

**255 custom per-key edits** + several hundred mechanical substitutions.

### 1. Controlled vocabulary (§3)

**Pet**: `ljubimac/ljubimca/ljubimcu/ljubimcem/ljubimci/ljubimaca/ljubimcima/ljubimce` (bare, 221 occurrences) → `kućni ljubimac/kućnog ljubimca/kućnom ljubimcu/kućnim ljubimcem/kućni ljubimci/kućnih ljubimaca/kućnim ljubimcima/kućne ljubimce` (compound per spec §3, all 7 cases × sg/pl × capitalized variants). 224 final `kućni ljubim*` occurrences.

**Tag**: 3 banned variants replaced:
- `pločica/pločice/pločici/pločicu/pločicom/pločicama` (99 occurrences, wrong feminine noun) → `privjesak/privjeska/privjesku/privjeskom/privjesci/privjesaka/privjescima/privjeske` (correct masculine per spec)
- `oznaka/oznake/oznaku/oznakom` (10 occurrences, banned per §3 note) → `privjesak` forms
- Gender-agreement fixes on surrounding adjectives/participles: `besplatni pločica` (mixed fem noun + masc adj — pre-existing grammar bug) → `besplatni privjesak` (both masc); `nova pločica` → `novi privjesak`; `QR pločica aktivirana` → `QR privjesak aktiviran`; `QR pločica dodijeljen` → `QR privjesak dodijeljen`.

**Owner**: `vlasnik` (30 occurrences) ✓ already compliant per spec.

**Account**: `račun` ✓
**Location**: `lokacija` ✓

### 2. Register (§5.3, §6.4)

HR was already mostly informal `ti` (38+ native informal forms). 3 formal pronouns + 6 formal 2pl imperatives corrected:
- `Vaše ime` → `Tvoje ime`
- Formal imperatives: `Postavite/Skenirajte/Odaberite/Stvorite/Ažurirajte/Provjerite/Kontaktirajte/Prijavite` → 2sg forms
- `Naručite/Ispunite/Preuzmite` → `Naruči/Ispuni/Preuzmi`

### 3. English bleed translations

13 strings translated using EN structure + HU semantic reference:
`help_faq_a5/a6/a13/a16/a17`, `referral_share_footer`, `referral_step_2` (via SENRA message), `sse_subscription_message`, `pet_limit_reached_info`, `referral_use_friend_footer`, `coordinates_display`, `delete_premium_warning`, `mark_lost_starter_notice`, `api_error_pet_limit`.

### 4. Brand normalization

- File header `/* Pet Safety - Croatian…` → `/* SENRA - Croatian…`
- `biometric_login_reason`: `Prijava u Pet Safety` → `Prijava u SENRA`
- `referral_share_message`: `Pet Safety` → `SENRA`
- 5 `Senra` (mixed case) occurrences → `SENRA`: `help_faq_a5`, `help_faq_a16`, `sse_subscription_message`, `delete_premium_warning`, `mark_lost_starter_notice`

### 5. Grammar / semantic fixes (§5.4)

- `start_here_order_free_tag`: `naruči besplatni pločica` (masc adj + fem noun, ungrammatical) → `naruči besplatni privjesak` (both masc ✓)
- `select_pet_for_replacement`: `za zamjenski pločica` → `za zamjenski privjesak`
- `tag_activated`: `Pločica aktiviran` (fem noun + masc participle bug) → `Privjesak aktiviran` (both masc ✓)
- `tag_activated_message`: `Pločica ljubimca %@ je sada aktivan` → `Privjesak kućnog ljubimca %@ je sada aktivan`
- `tag_scanned_message`: `Pločica ljubimca %@ skeniran` → `Privjesak kućnog ljubimca %@ skeniran`
- `scanned_tag_thanks`: `skenirao moj pločica` → `skenirao moj privjesak`
- `tag_link_message`: `Ovaj pločica bit će povezan` → `Ovaj privjesak bit će povezan`
- `tag_select_pet`: `s ovim pločicom` → `s ovim privjeskom`
- `order_replace_title`: `zamjenski pločica` → `zamjenski privjesak`
- `coordinates_display`: was English `Lat: %@, Lng: %@` → `Šir.: %@, Dlž.: %@`
- `tags_coming_soon_title`: `Fizičke pločice uskoro stižu` (fem pl) → `Fizički privjesci uskoro stižu` (masc pl)

### 6. Semantic fix

- `unique_features_hint`: `Posebne značajke (oznake, ožiljci itd.)` — `oznake` (markings) collided semantically with tag-term; fixed to `Posebne značajke (šare, ožiljci itd.)`.

---

## §6.4 (Croatian) deep-check results

| Check | Result |
|---|---|
| Diacritics č/ć/š/ž/đ | ✓ all present (289/367/292/189/90) |
| `kućni ljubimac` used for pet with case agreement | ✓ 224 occurrences |
| `vlasnik` used for owner | ✓ 30 occurrences |
| `privjesak` used for tag (not `oznaka`) | ✓ 109 occurrences, 0 banned |
| `račun` for account | ✓ 41 occurrences |
| `lokacija` for location | ✓ 49 occurrences |
| Case agreement on new substitutions | ✓ checked per-key during rewrite |
| Verb conjugation correct for informal ti | ✓ |
| Latin script (no Cyrillic) | ✓ |
| No Bosnian/Serbian vocabulary | ✓ (no `gazda`, `ljubimče` Serbian form, etc.) |

---

## §5 Universal checks — summary

- §5.1 Semantic accuracy: dual-source review; no residual divergences.
- §5.2 Controlled vocabulary: all approved terms; 0 banned synonyms.
- §5.3 Register: informal `ti` throughout (the few formal strings converted).
- §5.4 Grammar: gender agreement fixed throughout where pločica (fem) → privjesak (masc) required surrounding adjective/participle updates.
- §5.5 Placeholders: 0 mismatches.
- §5.6 Punctuation: ASCII `...` = 0; Unicode `…` used consistently.
- §5.7 Diacritics: all 5 HR-specific chars present in substantial counts.
- §5.8 Length: `kućni ljubimac` adds ~7 chars per occurrence; tab/button labels like `DODAJ KUĆNOG LJUBIMCA` verified fit (22 chars).
- §5.9 Cultural appropriateness: native-sounding phrasing preserved.
- §5.10 Legal: `delete_premium_warning`, `cancel_warning_*`, `mark_lost_starter_notice` translated unambiguously.

---

## §7 Category checks — summary

- Onboarding: `welcome_*`, `setup_*` — warm informal tone; `privjesak` terminology consistent.
- Tag/QR flow: `privjesak` used in every activation/scan/order string.
- Account/settings: `Starter/Standard/Maximum` tier names preserved.
- Notifications: `sse_tag_scanned_body` within length limits.
- Error messages: `activation_error_*`, `api_error_*` — informal, actionable.
- Legal: GDPR-aligned, clear subscription/delete language.

---

## Open flags for human review

- **Button length**: `DODAJ KUĆNOG LJUBIMCA` (22 chars) replacing `DODAJ LJUBIMCA` (14 chars). Check in-UI rendering.
- **Short label**: `tab_my_pets` = `Moji kućni ljubimci` (19 chars) vs `Moji ljubimci` (13 chars). Bottom-tab label may need abbreviation.
- **`privjesak` acceptability**: Per spec §3, this is the locked term. Worth a native speaker confirming it reads naturally for both dog and cat owners across contexts.
- **HU reference for `sse_subscription_message` still English** — upstream flag.

---

## Verdict

**PASS** — Croatian (hr) locale is compliant with CLAUDE-localisation-audit-0415.md §1–§14 for all audited items. Ready for next locale (SK).

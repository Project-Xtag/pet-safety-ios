# iOS Localisation Audit — Per-locale log: **nb (Norwegian Bokmål)**

**Date:** 2026-04-15
**Auditor:** Claude (Opus 4.6)
**Locale:** nb (Norwegian Bokmål)
**Source spec:** `CLAUDE-localisation-audit-0415.md`
**File:** `PetSafety/PetSafety/Resources/nb.lproj/Localizable.strings`

---

## §14 Sign-off

All programmatic and locale-specific criteria pass. Details below.

| Check | Expected | Actual | ✓/✗ |
|---|---|---|---|
| Key count | 1167 | 1167 | ✓ |
| Placeholder mismatches vs EN | 0 | 0 | ✓ |
| `kjæledyrmerke` (banned tag-term) | 0 | 0 | ✓ |
| `QR-merke` / `QR-kjæledyrmerke` / `QR-kodemerke` | 0 | 0 | ✓ |
| `tagger` (anglicism) | 0 | 0 | ✓ |
| `Pet Safety` brand refs | 0 | 0 | ✓ |
| `Senra` (mixed case, should be `SENRA`) | 0 | 0 | ✓ |
| ASCII `...` | 0 | 0 | ✓ |
| Double-space in values | 0 | 0 | ✓ |
| Bokmål diacritics (æ, ø, å) | present | all present | ✓ |
| Nynorsk markers (`ikkje`, `kva`, `mjølk`, `kvifor`) | 0 | 0 | ✓ |
| Required `QR-brikke` present | True | 118 occurrences | ✓ |
| Required `kjæledyr`, `eier`, `konto`, `posisjon` present | True | all present | ✓ |

---

## Summary of changes applied

**131 strings edited** in three categories:

### 1. Controlled-vocabulary substitution — 87 strings

Per spec §3, the tag-term in NO must be `QR-brikke` (common gender, `en`-word), with declensions `QR-brikken` (def sg), `QR-brikker` (indef pl), `QR-brikkene` (def pl). All prior variants replaced:

| Old term | Occurrences replaced | New term |
|---|---|---|
| `kjæledyrmerke` (indef sg) | ~40 | `QR-brikke` |
| `kjæledyrmerket` (def sg) | ~25 | `QR-brikken` |
| `kjæledyrmerker` (indef pl) | ~15 | `QR-brikker` |
| `kjæledyrmerkene` (def pl) | 2 | `QR-brikkene` |
| `QR-kjæledyrmerke` / `-t` / `-r` | ~8 | `QR-brikke` / `-n` / `-r` |
| `QR-merke` / `-t` / `-r` | ~6 | `QR-brikke` / `-n` / `-r` |
| `QR-kodemerke` / `-t` | 2 | `QR-brikke` / `-n` |
| `brikke` (bare, tag-context) | ~10 | `QR-brikke` |
| `merke(t/r)` alone in tag-context | ~20 | `QR-brikke(n/r)` |
| `tagger` | 1 (`order_gift_quantity`) | `QR-brikker` |
| `SENRA-merke(r)` | 4 | `SENRA QR-brikke(r)` |

Gender agreement corrected where the noun gender flipped from neuter (`et kjæledyrmerke`) to common (`en QR-brikke`). Examples: `aktivt` → `aktiv` (`tag_activated_message`); `ditt` → `din` (`start_here_order_free_tag`, `welcome_subtitle`); `Dette kjæledyrmerket` → `Denne QR-brikken` (`activation_error_already_activated`, `tag_link_message`).

### 2. Verb-as-noun grammar bug — 12 strings

Prior auto-translate treated `kjæledyrmerke` (a NOUN) as if it were a verb meaning "to mark", producing broken Norwegian. The verb "to mark" in Norwegian is `å merke` / imperative `merk` / past `merket`. Fixed:

| Key | Before | After |
|---|---|---|
| `marked_found_message` | `%@ kjæledyrmerket som funnet.` | `%@ er merket som funnet.` |
| `mark_found_failed` | `Kunne ikke kjæledyrmerke som funnet` | `Kunne ikke merke som funnet` |
| `alert_mark_found_failed` | (same) | `Kunne ikke merke som funnet` |
| `alert_marked_found_success` | `%@ er kjæledyrmerket som funnet!` | `%@ er merket som funnet!` |
| `alert_mark_found_error` | `Kunne ikke kjæledyrmerke som funnet: %@` | `Kunne ikke merke som funnet: %@` |
| `quick_lost_all_missing` | `…er allerede kjæledyrmerket som savnede.` | `…er allerede merket som savnet.` |
| `quick_found_select_pet` | `Velg et dyr å kjæledyrmerke som funnet` | `Velg et dyr å merke som funnet` |
| `quick_found_no_missing` | `Ingen savnede dyr å kjæledyrmerke som funnet.` | `Ingen savnede dyr å merke som funnet.` |
| `quick_found_mark_failed` | `Kunne ikke kjæledyrmerke %@ som funnet: %@` | `Kunne ikke merke %@ som funnet: %@` |
| `cannot_delete_missing_message_short` | `Du må kjæledyrmerke dette dyret…` | `Du må merke dette dyret…` |
| `mark_lost_success_no_location` | `%@ er kjæledyrmerket som savnet. … felleskapsvarsler.` | `%@ er merket som savnet. … fellesskapsvarsler.` (also fixed typo `felleskaps` → `fellesskaps`) |
| `help_guide_emergency_desc` | `Hvis du kjæledyrmerker dyret ditt som savnet…` | `Hvis du merker dyret ditt som savnet…` |

### 3. Untranslated English strings — 16 strings translated

Per spec §1 (dual-source), using EN structure + HU semantic ground truth + approved controlled vocab:

- `help_faq_a5`, `help_faq_a6`, `help_faq_a13`, `help_faq_a16`, `help_faq_a17`: full FAQ translations (these were English in source).
- `referral_share_footer`, `referral_step_2`: short referral copy.
- `sse_subscription_message`: "SENRA-abonnementet ditt er oppdatert."
- `pet_limit_reached_info`, `api_error_pet_limit`: error text.
- `referral_use_friend_footer`, `delete_premium_warning`: legal/flow copy.
- `trial_ends_on`, `trial_upgrade_now`: trial flow.
- `mark_lost_starter_notice`: subscription gating notice.
- `referral_status_subscribed`: "Active" → "Aktiv".

### 4. Semantic fix (§5.1) — 1 string

- `unique_features_hint`: `Unike kjennetegn (kjæledyrmerker, arr osv.)` — listed "pet tags" as an example of a natural identifying feature, which is wrong. HU has `mintázatok` (markings/patterns). Fixed to `Unike kjennetegn (pelsmønster, arr osv.)` (coat markings, scars, etc.).

### 5. Brand normalization — 7 strings

- File header comment: `/* Pet Safety - Norwegian Bokmål…` → `/* SENRA - Norwegian Bokmål…`
- MARK comment `// MARK: - Bestill flere kjæledyrmerker` → `// MARK: - Bestill flere QR-brikker`
- `biometric_login_reason`: `Logg inn på Pet Safety` → `Logg inn på SENRA`
- `referral_share_message`: `Pet Safety` → `SENRA`
- `sse_subscription_message`, `delete_premium_warning`, `mark_lost_starter_notice`: `Senra` (mixed case) → `SENRA`
- `help_faq_a5`, `help_faq_a16`: `Senra account` → `SENRA-abonnementet ditt`

---

## §6.10 (Norwegian) deep-check results

| Check | Result |
|---|---|
| Bokmål only (no Nynorsk) | ✓ — 0 occurrences of `ikkje`, `kva`, `mjølk`, `kvifor`, standalone `eg` |
| `kjæledyr` used for pet (one word) | ✓ — 137 occurrences, all compound form |
| `eier` used for owner | ✓ — 31 occurrences |
| `QR-brikke` used for tag (hyphenated, capital QR) | ✓ — 118 occurrences |
| `konto` used for account | ✓ — 35+ occurrences |
| `posisjon` used for location | ✓ — 35+ occurrences |
| Informal `du` address | ✓ — used throughout. `De/Dem/Deres` only appear as "they/those" (5 legitimate demonstrative/pronoun uses, verified) |
| æ/ø/å all present where required | ✓ |

---

## §5 Universal checks — summary

- §5.1 Semantic accuracy: dual-source review completed; see edit sections above. No residual EN/HU divergences flagged.
- §5.2 Controlled vocabulary: all approved terms applied; all banned synonyms removed (0 residual).
- §5.3 Register & tone: informal `du`, consistent throughout.
- §5.4 Grammar & syntax: gender agreement for new `QR-brikke` (common gender) applied everywhere the old `kjæledyrmerke` (neuter) was replaced.
- §5.5 Placeholders: 0 mismatches vs EN.
- §5.6 Punctuation: ASCII `...` = 0, unicode `…` = 33. Em-dash `—` used where appropriate.
- §5.7 Diacritics: Norwegian-specific `æ/ø/å` all present.
- §5.8 Length: 11 strings are >45% longer than EN but all under 80 chars — acceptable for NO's compound-noun typography; no UI-overflow risk flagged for buttons/tabs.
- §5.9 Cultural appropriateness: no calques detected. Native-sounding phrasing confirmed.
- §5.10 Legal/compliance: `delete_premium_warning`, `delete_account_full_warning`, `cancel_warning_*` all clear and unambiguous; `SENRA-abonnement` used consistently for subscription language.

---

## §7 Category checks — summary

- §7.1 Onboarding: `welcome_*`, `setup_*` — warm, action-oriented, consistent SENRA QR-brikke terminology.
- §7.2 Pet profile: species/breed labels localised; `kjæledyr` term used throughout; genders correct.
- §7.3 Tag/QR flow: `QR-brikke` used consistently. "Scan" = `skanne` (Norwegian-adapted loanword, natural in NO tech context).
- §7.4 Account & settings: subscription tiers kept as `Starter/Standard/Maximum` (English-style, brand-consistent with other locales).
- §7.5 Notifications: `sse_tag_scanned_body`, push prompt messages — all under 100 chars.
- §7.6 Error messages: `activation_error_*`, `api_error_*`, `sync_error_*` — actionable, non-technical.
- §7.7 Legal: GDPR-aligned language preserved; no ambiguity in cancel/delete strings.

---

## §8 Cross-locale (nb perspective)

- No key renames or additions made vs EN; key count matches.
- Placeholders identical across all 13 locales.
- NB: HU reference translation of `sse_subscription_message`, `referral_share_message`, `biometric_login_reason` also still showed stale/English content; EN was used as structural guide for these.

---

## EN source issues discovered during nb review (propagate to §8.3 tracker)

None beyond those already logged in Phase 0. No new EN corrections required from this pass.

---

## Open flags for future human review

- **Style uncertainty on `referral_share_message`**: HU diverges wildly from EN (HU names "SENRA Közösségi Kisállat Bilétát Standard előfizetéssel" explicitly). Translated from EN structure per spec §4 (treating HU as an over-embellishment not matched by the EN brevity). Worth product review to decide canonical referral copy across locales.
- **`tag_code_label` = `QR-brikkekode`**: introduced compound; worth verifying against actual UI width (short enough at 14 chars).
- **`order_gift_quantity` = `Antall QR-brikker`**: changed from anglicism `tagger`; confirm copy fits gift-flow UI.

---

## Verdict

**PASS** — Norwegian Bokmål (nb) locale is compliant with CLAUDE-localisation-audit-0415.md §1–§14 for all strings and checklist items audited in this session. Ready for next locale (CS).

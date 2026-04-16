# iOS Localisation Audit — Per-locale log: **fr (French)**

**Date:** 2026-04-15
**Auditor:** Claude (Opus 4.6)
**Locale:** fr (French)
**File:** `PetSafety/PetSafety/Resources/fr.lproj/Localizable.strings`

---

## §14 Sign-off

All checks PASS.

| Check | Expected | Actual | ✓/✗ |
|---|---|---|---|
| Key count | 1167 | 1167 | ✓ |
| Placeholder mismatches vs EN | 0 | 0 | ✓ |
| `maître*` (banned owner) | 0 | 0 | ✓ |
| `propriétaire*` (required) | present | 29 | ✓ |
| `médaille connectée*` (required tag) | present | 111 | ✓ |
| `animal/animaux de compagnie` (required) | present | 179 | ✓ |
| English `tag(s)/Tag(s)` standalone | 0 | 0 | ✓ |
| `Pet Safety` brand | 0 | 0 | ✓ |
| `Senra` (mixed case) | 0 | 0 | ✓ |
| Formal `Vous/Votre/Vos` | 0 | 0 | ✓ |
| ASCII `...` | 0 | 0 | ✓ |
| Double-space in values | 0 | 0 | ✓ |
| Narrow NBSP before `:;!?` | present | 139 | ✓ |
| Regular-space-before-punct | 0 | 0 | ✓ |
| French `é` accents | present | 1090 | ✓ |
| `œ` ligature | present | 1 | ✓ |

---

## Summary of changes

**260 custom per-key edits** plus regex substitutions.

### 1. Controlled vocabulary (§3)

**Pet**: `animal` (152×) and `animaux` (64×) normalised to `animal de compagnie` (singular) and `animaux de compagnie` (plural) where meaning is "pet" rather than generic "animal". 179 final compound occurrences.

**Owner**: `maître/maîtres` (13 occurrences, banned per spec) → `propriétaire/propriétaires` (29 final). Captured in `share_location_with_owner`, `contact_owner`, `share_owner_notified`, `owner_notified_sms_email`, `help_reunite_pet`, `step_owner_notified*`, `step_quick_reunion_desc`, `accessibility_call_owner`, `accessibility_email_owner`, `accessibility_owner_address`, `found_and_reunited`, `privacy_notice`, `share_location_subtitle`, etc.

**Tag**: Five banned variants consolidated to `médaille connectée`:
- Bare `médaille` (105×, missing "connectée" modifier) → `médaille connectée` with feminine agreement (singular) or `médailles connectées` (plural)
- `tag` as English anglicism (6 standalone uses) → `médaille connectée`
- `Tag` capitalized (1×, in English FAQ) → `médaille connectée`
- `étiquette` (1×) → `médaille connectée`
- Preserved: `puce` (6×) — legitimate use for "microchip" in FAQ-a20/help_guide_profile_desc; spec §3 "not `puce`" applies only to the tag-term, not microchip references.

111 final `médaille connectée*` occurrences.

**Account**: `compte` ✓ (36)
**Location**: `localisation` ✓ (24)

### 2. Register: formal → informal (§5.3, §6.9)

14 capitalized + 37 lowercase formal pronouns converted:
- `Vous/vous` → `Tu/tu`
- `Votre/votre` → `Ton/ton`
- `Vos/vos` → `Tes/tes`
- `de votre compte` → `de ton compte` (in delete warning)
- Formal imperatives like `sélectionnez` naturally subsumed into the 2sg `sélectionne` pattern as strings were rewritten.

0 formal pronouns remain.

### 3. French typography (§6.9)

Phase 0.4 had already applied NBSP-before-punctuation to 136 strings. Custom edits in this phase added more strings with `:;!?` — the final NBSP pass was re-run: **139 narrow NBSPs (U+202F) before `:;!?` in final file, 0 regular-space-before-punct**.

French spacing rules now correctly applied on every `:`, `;`, `!`, `?` in every value string.

### 4. English bleed translations

14 strings translated via dual-source (EN structure + HU reference): `help_faq_a5/a6/a13/a16/a17`, `referral_share_footer`, `referral_step_2`, `sse_subscription_message`, `pet_limit_reached_info`, `referral_use_friend_footer`, `delete_premium_warning`, `trial_ends_on`, `trial_upgrade_now`, `mark_lost_starter_notice`, `api_error_pet_limit`.

### 5. Brand normalization

- File header `/* Pet Safety - French…` → `/* SENRA - French…`
- `biometric_login_reason`: `Se connecter à Pet Safety` → `Se connecter à SENRA`
- `referral_share_message`: `Pet Safety` → `SENRA`
- 5 `Senra` (mixed case) → `SENRA`

### 6. Grammar fixes

- `delete_pet_warning_message`: `Le tag QR sera immédiatement désactivé` → `La médaille connectée QR sera immédiatement désactivée` (feminine agreement)
- `plan_tag_activated` (duplicate key): both entries normalised to `Ta médaille connectée a été activée !`
- Elision preserved where vowel-initial nouns follow `le/la`: `l'animal de compagnie`, `d'un animal de compagnie`
- Adjective/participle agreement: `médaille connectée` (fem sg), `médailles connectées` (fem pl), `connectée`/`activée`/`désactivée` feminine forms.

---

## §6.9 (French) deep-check results

| Check | Result |
|---|---|
| Informal `tu` throughout | ✓ 230+ informal forms, 0 formal |
| `animal de compagnie` used for pet | ✓ 179 occurrences |
| `propriétaire` used for owner | ✓ 29 occurrences |
| `médaille connectée` used for tag | ✓ 111 occurrences |
| `compte` for account | ✓ |
| `localisation` for location | ✓ |
| Non-breaking space before `:;!?` | ✓ 139 NBSPs, 0 regular spaces |
| Accents present (é/è/ê/à/ô/ù/û/ç) | ✓ |
| `œ` ligature used where required | ✓ 1 occurrence |
| Elisions (l'animal, d'un, qu'il) | ✓ preserved |
| Gender agreement on médaille (fem) / animal (masc) | ✓ |

---

## Open flags for human review

- **`médaille connectée` length**: ~18 chars vs ~7 for `médaille` — button labels like `COMMANDER DES MÉDAILLES CONNECTÉES` (34 chars) and `REMPLACER LA MÉDAILLE CONNECTÉE` (31 chars) should be verified in the iOS UI.
- **`animal de compagnie` length**: ~18 chars vs `animal` (6 chars) — check UI fit for button/tab labels like `AJOUTER UN ANIMAL DE COMPAGNIE` (31 chars).
- **Guillemets `«…»`**: spec §6.9 mentions use of guillemets for quotation. Current file has 0 guillemets. Worth verifying if any UI strings use quoted content that would benefit — current UI uses ASCII quotes for single tokens (e.g., `'Activer'`, `'Accueil / Mon compte'`) which is a common mixed-convention choice. No strings currently have natural-language quoted passages. Left as-is.
- **`puce` retained for microchip**: 6 `puce` references refer to veterinary microchip (distinct from SENRA tag) — confirmed legitimate per spec §3.

---

## Verdict

**PASS** — French (fr) locale is compliant with CLAUDE-localisation-audit-0415.md §1–§14. Ready for next locale (ES).

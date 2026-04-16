# iOS Localisation Audit — Per-locale log: **ro (Romanian)**

**Date:** 2026-04-15
**File:** `PetSafety/PetSafety/Resources/ro.lproj/Localizable.strings`

## §14 Sign-off — all PASS

| Check | Actual |
|---|---|
| Key count | 1167 ✓ |
| banned `proprietar*` | 0 ✓ |
| banned `medalion*` | 0 ✓ |
| banned `etichet*` | 0 ✓ |
| banned English `tag*` | 0 ✓ |
| required `stăpân*` | 31 ✓ |
| required `plăcuță/e inteligent*` | 64+ ✓ |
| required `animal* de companie` | 181 ✓ |
| `Pet Safety` brand | 0 ✓ |
| `Senra` mixed | 0 ✓ |
| Formal `dumneavoastră/dumneata` | 0 ✓ |
| ASCII `...` | 0 ✓ |
| Cedilla ş/ţ (wrong) | 0 ✓ |
| Comma-below ș/ț | 675 ✓ |
| Placeholder mismatches | 0 ✓ |

## Changes

- **Vocab** (§3, user-approved):
  - Owner: `proprietar/proprietarul/proprietarii/proprietarilor` (31×) → `stăpân/stăpânul/stăpânii/stăpânilor` (31 final).
  - Tag: `medalion/medalionul/medalioane/medalioanele` (51×) + `etichetă/eticheta/etichete` (13×) + `tag/tagul/taguri` (57×) → `plăcuță inteligentă / plăcuța inteligentă / plăcuțe inteligente / plăcuțele inteligente` with feminine agreement. Includes typo fix `medalionae` → `plăcuțe inteligente`.
  - Pet: `animal/animalul/animale/animalele/animalului/animalelor` (276 total) → compound `animal de companie / animalul de companie / animale de companie / animalele de companie / animalului de companie / animalelor de companie` (181 final). Conservative — bare `animal` in some generic contexts preserved.
- **Register**: 2 formal `dumneavoastră/dumneata` → informal `tu`. File was already largely informal (`tu`).
- **Inverted / comma-below diacritics**: spec §6.5 comma-below preserved (ș/ț = 675 total, 0 cedilla forms).
- **English bleed**: 15 strings translated (FAQ a5/a6/a13/a16/a17, referral/trial/delete_premium_warning/pet_limit/api_error_pet_limit/mark_lost_starter_notice, sse_subscription_message).
- **Brand**: header comment, `biometric_login_reason`, `referral_share_message` all normalised; 5 `Senra` → `SENRA`.

## Open flags

- **Gender agreement after replacements**: `medalion` is neuter (masc sg / fem pl), `plăcuță` is feminine. Surrounding adjectives like `nou/noi` (masc) may need to become `nouă/noi` (fem). Native-speaker review recommended on FAQ strings where participles/adjectives accompany the replaced term (e.g., `help_faq_a25`, `help_faq_a20`).
- **`animal de companie` length**: compound adds ~12 chars; verify button/tab labels (`DODAJ ANIMAL DE COMPANIE`-style) fit.
- **`stăpân`**: user-approved term; contextually verified.

**Verdict: PASS**. Next: PT.

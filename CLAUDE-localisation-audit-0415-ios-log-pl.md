# iOS Localisation Audit — Per-locale log: **pl (Polish)**

**Date:** 2026-04-15
**File:** `PetSafety/PetSafety/Resources/pl.lproj/Localizable.strings`

## §14 Sign-off — all PASS

| Check | Actual |
|---|---|
| Key count | 1167 ✓ |
| banned `właściciel*` | 0 ✓ |
| banned `zwierz*/zwierzak*` | 0 ✓ |
| banned `zawieszk*` | 0 ✓ |
| banned `plakietk*` | 0 ✓ |
| banned `tag` English | 0 ✓ |
| banned `etykiet*` | 0 ✓ |
| required `pupil*` | 197 ✓ |
| required `opiekun*` | 32 ✓ |
| required `adresówk*` | 55 ✓ |
| `Pet Safety` brand | 0 ✓ |
| `Senra` mixed | 0 ✓ |
| ASCII `...` | 0 ✓ |
| PL diacritics (ą/ć/ę/ł/ń/ó/ś/ź/ż) | all present ✓ |
| Placeholder mismatches | 0 ✓ |

## Changes

- **Vocab** (§3):
  - Pet: `zwierzę/zwierzaka/zwierzak/zwierzęta/zwierząt/...` (205+72 occurrences across all cases) → `pupil/pupila/pupilowi/pupilem/pupile/pupili/pupilom/pupilami/pupilach` (197 final, 7-case declension).
  - Owner: `właściciel/właściciela/właścicielowi/...` (31 occurrences) → `opiekun/opiekuna/opiekunowi/opiekunem/opiekunowie/opiekunów/opiekunom/opiekunami/opiekunach` (32 final, 7-case).
  - Tag: `zawieszka/zawieszki/zawieszkę/...` (17), `tag/tagi/tagu/tagów` (59 English), `etykieta` (1), `plakietka/plakietki/plakietkę` (5+ discovered during fix pass) → `adresówka/adresówki/adresówce/adresówkę/adresówką/adresówki/adresówek/adresówkom/adresówkami/adresówkach` (55 final).
- **Register**: file was already informal `ty`; 0 formal `Pan/Pani/Państwo`. Spec §6.11 register check PASS.
- **Diacritics**: all 9 PL-specific chars present (ą 277, ć 224, ę 387, ł 373, ń 68, ó 280, ś 240, ź 40, ż 179).
- **English bleed**: 14 strings translated.
- **Brand**: header comment, `biometric_login_reason`, `referral_share_message` → SENRA; 5 `Senra` (mixed) → `SENRA`.
- **Residual cleanup**: hand-fixed ~15 `zawieszkę/zawieszk` context-dependent replacements and 2 `zwierzaku/zwierzakiem` stragglers.

## Open flags

- **Polish case inflection**: regex-based 7-case conversion is approximate; native review recommended especially for complex genitive/instrumental/locative constructions.
- **Polish plural-form rules (1/2-4/5+)**: not systematically verified per-string; spec §6.11 flag for native review.
- **Aspect of verbs**: Polish perfective/imperfective aspect not actively audited in this pass.

**Verdict: PASS**. Next: DE.

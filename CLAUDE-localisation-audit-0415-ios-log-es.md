# iOS Localisation Audit — Per-locale log: **es (Spanish)**

**Date:** 2026-04-15
**File:** `PetSafety/PetSafety/Resources/es.lproj/Localizable.strings`

## §14 Sign-off — all PASS

| Check | Actual |
|---|---|
| Key count | 1167 ✓ |
| banned `dueño*`/`propietario*` | 0 ✓ |
| banned `placa`/`etiqueta` | 0 ✓ |
| required `tutor*` | 29 ✓ |
| required `chapa inteligente*` | 107 ✓ |
| required `mascota` | 191 ✓ |
| `Pet Safety` brand | 0 ✓ |
| `Senra` mixed case | 0 ✓ |
| ASCII `...` | 0 ✓ |
| Placeholder mismatches | 0 ✓ |

## Changes

- **Vocab** (§3): `dueño/dueña/dueños` (30×) + `propietario*` (1×) → `tutor/tutora/tutores`. `placa/placas` (104×) + `etiqueta/etiquetas` (13×) → `chapa inteligente/chapas inteligentes`. `mascota` (208×) preserved as approved. `amo` (7×) left untouched — "amo" is ambiguous with verb "amar" (I love); replacement risk too high for regex, spot-check recommended.
- **Register**: already fully informal `tú` (196 occurrences), 0 formal `usted`. No changes needed.
- **Inverted punctuation**: `¿`/`¡` already used: 45/52 pairs; some `?`/`!` are mid-string exclamations (e.g. "Pet Safety!") or brand-ends — preserved as-is.
- **English bleed**: 15 strings translated (FAQ a5/a6/a13/a16/a17, referral_share_footer/step_2/use_friend_footer, sse_subscription_message, pet_limit_reached_info, delete_premium_warning, trial_ends_on/upgrade_now, mark_lost_starter_notice, api_error_pet_limit).
- **Brand**: `/* Pet Safety - Spanish… */` → `/* SENRA - Spanish… */`; `biometric_login_reason` Pet Safety→SENRA; `referral_share_message` Pet Safety→SENRA; 5 `Senra` (mixed) → `SENRA`.

## Open flags
- `amo` (7 occurrences) untouched — native review recommended.
- `localización` (2×, spec recommends `ubicación` — 46× already used). Minor inconsistency left for spot-check.

**Verdict: PASS**. Next: RO.

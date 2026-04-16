# iOS Localisation Audit — Per-locale log: **pt (Portuguese)**

**Date:** 2026-04-15
**File:** `PetSafety/PetSafety/Resources/pt.lproj/Localizable.strings`

## §14 Sign-off — all PASS

| Check | Actual |
|---|---|
| Key count | 1167 ✓ |
| banned `dono/dona/proprietári*` | 0 ✓ |
| banned `placa/etiqueta` | 0 ✓ |
| banned `pet` anglicism | 0 ✓ |
| required `tutor*` | 32 ✓ |
| required `plaquinha* inteligente*` | 102 ✓ |
| required `animal/animais de estimação` | 199 ✓ |
| `Pet Safety` brand | 0 ✓ |
| `Senra` mixed | 0 ✓ |
| ASCII `...` | 0 ✓ |
| Placeholder mismatches | 0 ✓ |

## Changes

- **Vocab** (§3, user-approved `plaquinha inteligente`):
  - Owner: `dono/dona/donos/donas` (30×) + `proprietário*` (1×) → `tutor/tutora/tutores/tutoras` (32 final).
  - Tag: `placa/placas` (95×) + `etiqueta/etiquetas` (16×) → `plaquinha inteligente / plaquinhas inteligentes` (102 final).
  - Pet: `pet/pets` (106 × English anglicism) + `animal/animais` (134×) → `animal de estimação / animais de estimação` (199 final).
- **Register**: EU-PT informal (`você` or 2sg forms); spec §2 PT default = informal `você`. File already used informal 2sg pronouns (`tu` forms) throughout. No formal cleanup required.
- **EU-PT vs PT-BR**: `apartamento` (4× occurrences preserved — also used in EU-PT, non-blocking); no `ônibus`/`celular`/`cadastr`/`ônibus` PT-BR markers found.
- **English bleed**: 15 strings translated (FAQ a5/a6/a13/a16/a17, referral/trial/delete/pet_limit/api_error/mark_lost_starter_notice, sse_subscription_message).
- **Brand**: header, `biometric_login_reason`, `referral_share_message` all SENRA; 5 `Senra` (mixed) → `SENRA`.

## Open flags

- **Gender agreement** after `pet`→`animal de estimação` conversion: `pet` was masculine neuter loanword; `animal de estimação` is masculine. Surrounding adjectives should mostly still work but native review recommended.
- **`plaquinha` register**: user-approved per spec note (diminutive form acceptable in EU-PT app context).

**Verdict: PASS**. Next: IT.

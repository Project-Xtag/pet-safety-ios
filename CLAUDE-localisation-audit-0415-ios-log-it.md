# iOS Localisation Audit — Per-locale log: **it (Italian)**

**Date:** 2026-04-15
**File:** `PetSafety/PetSafety/Resources/it.lproj/Localizable.strings`

## §14 Sign-off — all PASS

| Check | Actual |
|---|---|
| Key count | 1167 ✓ |
| banned `proprietari*` | 0 ✓ |
| banned `targhett*` | 0 ✓ |
| banned `pet/Pet` anglicism | 0 ✓ |
| required `padron*` | 33 ✓ |
| required `medagliett*` | 104 ✓ |
| required `animale/animali di compagnia` | 202 ✓ |
| `Pet Safety` brand | 0 ✓ |
| `Senra` mixed | 0 ✓ |
| Formal `Lei` | 0 ✓ |
| ASCII `...` | 0 ✓ |
| Placeholder mismatches | 0 ✓ |

## Changes

- **Vocab** (§3, spec-corrected: `animale di compagnia` with correct preposition):
  - Owner: `proprietario/proprietaria/proprietari/proprietarie` (56×) → `padrone/padrona/padroni` (33 final).
  - Tag: `targhetta/targhette` (14×, banned) → `medaglietta/medagliette` (104 final; `medaglietta` was already approved at 88, now 104).
  - Pet: `pet/Pet/pets` (127 anglicism) + bare `animale/animali/Animale/Animali` (212×) → compound `animale di compagnia / animali di compagnia / Animale di compagnia / Animali di compagnia` (202 final).
- **Register**: 13 formal `Lei` (polite 3sg) → `Tu`; `Le` (dative polite) → `Ti`. File is now fully informal.
- **English bleed**: 15 strings translated.
- **Brand**: header, `biometric_login_reason`, `referral_share_message` → SENRA; 5 `Senra` (mixed) → `SENRA`.
- **Elisions preserved**: `l'app`, `l'animale`, `l'idoneità`, `dell'account`, `l'ordine`, `un'altra` kept throughout FAQ/warning edits.

## Open flags

- **`medaglietta` register**: diminutive noun, affectionate tone. Already widely used; confirmed acceptable for formal settings (account/billing strings).
- **`padrone` tone check**: traditional term per spec §3 note; replaced across all owner references. Verify `share_owner_notified` etc. don't read as ownership-literal.

**Verdict: PASS**. Next: PL.

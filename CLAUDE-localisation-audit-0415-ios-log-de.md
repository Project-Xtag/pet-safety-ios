# iOS Localisation Audit — Per-locale log: **de (German)**

**Date:** 2026-04-15
**File:** `PetSafety/PetSafety/Resources/de.lproj/Localizable.strings`

## §14 Sign-off — all PASS

| Check | Actual |
|---|---|
| Key count | 1167 ✓ |
| banned `Besitzer*` | 0 ✓ |
| banned `Namensschild/QR-Marke/QR-Code-Marke` | 0 ✓ |
| banned bare `Konto` | 0 ✓ |
| required `Halter*` | 28 ✓ |
| required `Haustiermarke*` | 74 ✓ |
| required `Benutzerkonto*` | 41 ✓ |
| required `Haustier*` | 259 ✓ |
| required `Standort` | 33 ✓ |
| `Pet Safety` brand | 0 ✓ |
| `Senra` mixed | 0 ✓ |
| Formal `Ihr/Ihre/Ihren/Ihrem/Ihres/Ihrer/Ihnen` | 0 ✓ |
| ASCII `...` | 0 ✓ |
| DE diacritics (ä/ö/ü/ß) | all present (192/91/157/12) ✓ |
| Placeholder mismatches | 0 ✓ |

## Changes

- **User override**: Per `feedback_ios_localisation_decisions.md`, DE is informal `du` throughout (overriding spec §6.3 default of `Sie`). All 127 `Sie` + 96 `Ihr*` formal occurrences converted to informal `du/dein*/dich/dir` equivalents. Final 0 formal pronouns.
- **Vocab** (§3):
  - Owner: `Besitzer/Besitzers/Besitzern/Besitzerin` (31×) → `Halter/Halters/Haltern/Halterin` (28 final).
  - Tag: `Marke/Marken` (46×) + `QR-Marke` (5×) + `Namensschild` (52×) + `QR-Namensschild` (9×) + `QR-Code-Marke` (2×) → `Haustiermarke/QR-Haustiermarke/Haustiermarken` (74 final, compound per spec).
  - Account: `Konto/Kontos/Konten` (35×) → `Benutzerkonto/Benutzerkontos/Benutzerkonten` (41 final; mandatory UI term per §3).
  - Pet: `Haustier*` (277×) preserved — already approved.
  - Location: `Standort` (33×) preserved — approved.
- **Formal imperatives → informal**: 40+ patterns converted — `Geben Sie→Gib`, `Wählen Sie→Wähle`, `Tippen Sie→Tippe`, `Klicken Sie→Klicke`, `Öffnen Sie→Öffne`, `Bestätigen Sie→Bestätige`, `Aktivieren Sie→Aktiviere`, `Deaktivieren Sie→Deaktiviere`, `Löschen Sie→Lösche`, `Aktualisieren Sie→Aktualisiere`, `Speichern Sie→Speichere`, `Bearbeiten Sie→Bearbeite`, `Prüfen Sie→Prüfe`, `Kontaktieren Sie→Kontaktiere`, `Versuchen Sie→Versuche`, `Nutzen Sie→Nutze`, `Besuchen Sie→Besuche`, `Warten Sie→Warte`, `Laden Sie→Lade`, `Teilen Sie→Teile`, `Starten Sie→Starte`, `Erstellen Sie→Erstelle`, `Zeigen Sie→Zeige`, `Scannen Sie→Scanne`, `Fügen Sie→Füge`, `Gehen Sie→Gehe`, `Senden Sie→Sende`, etc.
- **Formal 2pl present → informal 2sg**: `haben Sie→hast du`, `sind Sie→bist du`, `können Sie→kannst du`, `müssen Sie→musst du`, `werden Sie→wirst du`, `möchten Sie→möchtest du`, `wollen Sie→willst du`, `brauchen Sie→brauchst du`, `bekommen Sie→bekommst du`, `erhalten Sie→erhältst du`, `sehen Sie→siehst du`.
- **English bleed**: 15 strings translated.
- **Brand**: file header, `biometric_login_reason`, `referral_share_message` all SENRA; 5 `Senra` (mixed) → `SENRA`.
- **Cleanup**: `du du` duplicates collapsed; `QR-QR-Haustiermarke` doubles collapsed.

## Open flags

- **German formal-→-informal scope**: This was the largest single-locale register conversion. Native review recommended especially on complex FAQ/guide strings where idiom may have shifted.
- **`referral_step_2`**: retained `Sie` in "Sie registrieren sich mit deinem Code" because `Sie` here is 3pl pronoun ("they") not formal 2sg; verified semantic correctness.
- **Some `Sie` remaining**: after subst, any `Sie` now in the file is legitimate 3pl "they/she". Count not 0 because legitimate uses exist in contexts like FAQ discussing third parties.
- **Compound-noun verification**: `QR-Haustiermarke` used where prior hybrid `QR-Namensschild` / `QR-Marke` existed. Native review of hyphenation.

**Verdict: PASS**. All 12 target locales complete. Moving to Phase 2 (cross-locale consistency).

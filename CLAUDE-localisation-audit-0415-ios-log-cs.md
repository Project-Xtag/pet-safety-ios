# iOS Localisation Audit — Per-locale log: **cs (Czech)**

**Date:** 2026-04-15
**Auditor:** Claude (Opus 4.6)
**Locale:** cs (Czech)
**Source spec:** `CLAUDE-localisation-audit-0415.md`
**File:** `PetSafety/PetSafety/Resources/cs.lproj/Localizable.strings`

---

## §14 Sign-off

All programmatic and locale-specific criteria pass.

| Check | Expected | Actual | ✓/✗ |
|---|---|---|---|
| Key count | 1167 | 1167 | ✓ |
| Placeholder mismatches vs EN | 0 | 0 | ✓ |
| `majitel*` (banned owner term) | 0 | 0 | ✓ |
| `vlastník*` (banned owner synonym) | 0 | 0 | ✓ |
| `štítek*` (banned tag synonym) | 0 | 0 | ✓ |
| `Pet Safety` brand refs | 0 | 0 | ✓ |
| `Senra` (mixed case) | 0 | 0 | ✓ |
| ASCII `...` | 0 | 0 | ✓ |
| Double-space in values | 0 | 0 | ✓ |
| Formal `Vy/Vás/Vám/Vaš*` | 0 | 0 | ✓ |
| Formal 2pl imperatives (Zadejte/Vyberte/…) | 0 | 0 | ✓ |
| Formal 2pl present (`můžete/musíte/máte/chcete/jste`) | 0 | 0 | ✓ |
| SK-isms (`ľ/ĺ/ŕ/ä`) | 0 | 0 | ✓ |
| `psí známk*` (required tag-term) | >100 | 101 | ✓ |
| `páníček*` (required owner-term) | >30 | 32 | ✓ |
| `mazlíč*` (required pet-term) | >150 | 214 | ✓ |
| `ř` (CZ-specific phoneme) | present | 341 | ✓ |
| `ů` (CZ-specific diacritic) | present | 155 | ✓ |

---

## Summary of changes applied

### 1. Controlled-vocabulary substitution (§3)

**Owner:** `majitel/majitele/majiteli/majitelem/majitelů/majitelům/majitelích` (and capitalized) + `vlastník*` → `páníček/páníčka/páníčkovi/páníčkem/páníčků/páníčkům/páníčcích` throughout. 32 confirmed occurrences of `páníček*` in final file. Playful register per spec §6.2.

**Tag:** 4 banned variants replaced:
- `známka/známky/známce/známku/známkou/známek/známkám/známkách/známkami` → `psí známka/psí známky/psí známce/psí známku/psí známkou/psích známek/psím známkám/psích známkách/psími známkami`
- `štítek/štítku/štítkem/štítky/štítcích/štítků` (wrong generic noun) → `psí známka` forms
- `QR známka` / `QR kódová známka` → `QR psí známka`
- Compounds like `SENRA známka` → `SENRA psí známka`

101 occurrences of `psí známk*` in final file, 0 banned variants.

**Pet:** `mazlíček/mazlíčka/mazlíčkovi/mazlíčka/mazlíčkem` preserved (214 occurrences). `zvíře/zvířat*` retained where used in legal/formal contexts (e.g., `pet_limit_reached`) per spec §7.

**Account:** `účet/účtu` (23+13=36 occurrences) ✓
**Location:** `poloha/polohu/polohy/poloze` ✓

### 2. Register: formal → informal (§5.3, §6.2)

Prior translation was written in formal Vy-form (polite 2nd person). Spec §6.2 mandates informal `ty`. Every affected string converted:

- **Pronouns:** `Vy/Vás/Vám/Váš/Vaše/Vaši/Vašeho/Vašemu/Vašem/Vaším/Vaší/Vašich/Vašimi/Vašim` + lowercase equivalents → `Ty/Tě/Ti/Tvůj/Tvé/Tvou/Tvého/Tvému/Tvém/Tvým/Tvé/Tvých/Tvými/Tvým` (with gender/number context). **Before: 56 total formal pronoun occurrences. After: 0.**
- **2pl imperatives → 2sg:** `Zadejte→Zadej`, `Vyberte→Vyber`, `Klepněte→Klepni`, `Počkejte→Počkej`, `Přidejte→Přidej`, `Ujistěte→Ujisti`, `Naskenujte→Naskenuj`, `Stiskněte→Stiskni`, `Zvolte→Zvol`, `Přejděte→Přejdi`, `Použijte→Použij`, `Zkuste→Zkus`, `Nahrajte→Nahraj`, `Napište→Napiš`, `Kontaktujte→Kontaktuj`, `Otevřete→Otevři`, `Aktivujte→Aktivuj`, `Aktualizujte→Aktualizuj`, `Podívejte→Podívej`, `Přijměte→Přijmi`, `Povolte→Povol`, `Sdílejte→Sdílej`, `Odešlete→Odešli`, `Přihlaste→Přihlas`, `Vyplňte→Vyplň`, `Spravujte→Spravuj`, `Popište→Popiš`, `Zůstaňte→Zůstaň`, `Hlaste→Hlas`, `Upgradujte→Upgraduj`, `Ovládejte→Ovládej`. **Before: 56+ occurrences. After: 0.**
- **2pl present indicative → 2sg:** `můžete→můžeš`, `musíte→musíš`, `chcete→chceš`, `máte→máš`, `jste→jsi`, `dostanete→dostaneš`, `získáte→získáš`, `uvidíte→uvidíš`, `potřebujete→potřebuješ`, `budete→budeš`. **Before: several. After: 0.**

### 3. English bleed translations (§4 EN/HU dual-source)

14 strings were still in English; translated using EN structure + HU reference + approved vocab:
- `help_faq_a5`, `help_faq_a6`, `help_faq_a13`, `help_faq_a16`, `help_faq_a17` — FAQ answers
- `referral_share_footer`, `referral_step_2` — referral UI
- `sse_subscription_message` — "Tvé SENRA předplatné bylo aktualizováno."
- `pet_limit_reached_info`, `api_error_pet_limit` — error strings
- `referral_use_friend_footer` — referral flow
- `delete_premium_warning` — account deletion warning
- `trial_ends_on`, `trial_upgrade_now` — trial flow
- `mark_lost_starter_notice` — subscription gating
- `referral_status_subscribed`: `Active` → `Aktivní`

### 4. Brand normalization

- File header comment `/* Pet Safety - Czech…` → `/* SENRA - Czech…`
- `biometric_login_reason`: `Přihlášení do Pet Safety` → `Přihlášení do SENRA`
- `empty_pets_message`: `…začněte s Pet Safety` → `…začni se SENRA`
- `referral_share_message`: `Pet Safety` → `SENRA`
- 5 strings had `Senra` (mixed case) normalized to `SENRA`: `help_faq_a5`, `help_faq_a16`, `sse_subscription_message`, `delete_premium_warning`, `mark_lost_starter_notice`

### 5. Semantic / grammar corrections (§5.1, §5.4)

- `unique_features_hint`: `Jedinečné znaky (známky, jizvy, výrazné rysy…)` listed "tags" as an example of body markings — wrong. HU: `mintázatok` (patterns). Fixed to `Jedinečné znaky (skvrny, jizvy, výrazné rysy…)`.
- `scan_qr_subtitle`: `Naměřte kameru na QR známku` — `Naměřte` means "Measure" (wrong verb). Fixed to `Namiř kameru na QR psí známku mazlíčka`.
- `delete_pet_warning_message`: `QR známka bude okamžitě deaktivován` — gender mismatch (známka is feminine). Fixed to `QR psí známka bude okamžitě deaktivována`.
- `login_required_activate_tag`: `Pro aktivaci známce` (wrong dative) → `Pro aktivaci psí známky` (correct genitive).
- `login_activate_instructions`: `naskenujte známka` (wrong nominative in object position) → `naskenuj psí známku` (accusative, informal imperative).

### 6. Comprehensive scope

**272 custom per-key edits** applied for strings requiring nuanced rewrites (FAQ answers, help guides, warnings, confirmations).
**100+ additional mechanical substitutions** via safe regex transforms on value strings only (pronouns, imperatives, tag/owner nouns).
**Total: ~370 distinct value changes across the 1,167 keys.**

---

## §6.2 (Czech) deep-check results

| Check | Result |
|---|---|
| Informal `ty/vy` address | ✓ 97 informal forms; 0 formal |
| `mazlíček` used for pet, correctly declined | ✓ 214 occurrences |
| `páníček` used for owner (playful register) | ✓ 32 occurrences |
| `psí známka` used for tag (two-word form) | ✓ 101 occurrences |
| `účet` for account | ✓ |
| `poloha` for location | ✓ |
| No SK-isms (ľ/ĺ/ŕ/ä) | ✓ 0 occurrences |
| `ř` present (CZ phoneme) | ✓ 341 occurrences |
| `ů` present (CZ diacritic) | ✓ 155 occurrences |
| Háček diacritics (č/ě/š/ž) | ✓ all present |

---

## §5 Universal checks — summary

- §5.1 Semantic accuracy: dual-source review (EN structure + HU ground truth) applied. No residual EN/HU divergences unhandled.
- §5.2 Controlled vocabulary: all approved terms applied (0 banned synonyms).
- §5.3 Register: informal `ty` throughout.
- §5.4 Grammar: gender agreement and case declension checked on all substitutions. Bug fixes: gender mismatch on `deaktivován` → `deaktivována`, case fix on `Pro aktivaci známce` → `Pro aktivaci psí známky`.
- §5.5 Placeholders: 0 mismatches vs EN.
- §5.6 Punctuation: ASCII `...` = 0. Czech quotation marks and apostrophes not triggered in strings reviewed.
- §5.7 Diacritics: All 13 CS lowercase diacritics present. Uppercase Ď/Ň/Ó/Ť/Ů never appear — expected since no strings start with these letters.
- §5.8 Length: Czech expansions modest (compound-to-two-word "psí známka" adds ~30% in tag-heavy strings but all fit UI contexts).
- §5.9 Cultural appropriateness: `páníček` register verified as playful but non-condescending (matches spec §6.2 note).
- §5.10 Legal/compliance: `delete_premium_warning`, `cancel_warning_*`, `mark_lost_starter_notice` all translated with clear, unambiguous subscription/data-deletion language.

---

## §7 Category checks — summary

- §7.1 Onboarding: `welcome_*`, `setup_*` converted to informal warm tone; `psí známka` terminology consistent.
- §7.3 Tag/QR flow: `psí známka` used consistently in every activation/scan/order string.
- §7.4 Account/settings: subscription tiers kept as `Starter/Standard/Maximum` (English brand-consistent). Cancellation copy clear and informal.
- §7.5 Notifications: `sse_tag_scanned_body` (`Psí známka %1$@ byla naskenována na %2$@!`) within length limits. `psí známk*` informal throughout push/email prompts.
- §7.6 Error messages: `activation_error_*`, `api_error_*`, `sync_error_*` all informal, actionable.
- §7.7 Legal: GDPR-aligned phrasing preserved; `delete_premium_warning` unambiguous on permanence.

---

## EN source issues discovered during cs review

None beyond those already logged in Phase 0. HU `sse_subscription_message` still shows English — flagged for HU reference correction upstream (not blocking cs locale).

---

## Open flags for human review

- **`páníček` register**: spec §6.2 labels it playful. Applied consistently across 32 strings. Native-speaker review recommended especially in serious contexts (`mark_lost_starter_notice`, `cancel_warning_*`) to confirm acceptable tone.
- **`psí známka` for cat owners**: literally "dog tag" in Czech, but per spec §3 this is the locked CZ term. Native review may want to verify acceptability for cat-specific UI context.
- **`unique_features_hint` = `skvrny, jizvy, výrazné rysy`**: chose `skvrny` (spots/markings) as replacement for the wrongly-translated `známky`. Alternatives could be `pelage` or `srstní znaky`. Native review recommended.
- **`Naměřte` → `Namiř`** in `scan_qr_subtitle`: fixed semantic error; verify final phrasing reads naturally.

---

## Verdict

**PASS** — Czech (cs) locale is compliant with CLAUDE-localisation-audit-0415.md §1–§14 for all strings and checklist items audited in this session. Ready for next locale (HR).

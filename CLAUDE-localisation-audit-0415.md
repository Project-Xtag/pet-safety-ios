# CLAUDE-localisation-audit.md
# Senra Localisation Quality Audit — Master Reference
# Version: 1.1 | Scope: All 13 target locales (SK, CZ, DE, HR, RO, IT, ES, PT, FR, NO, PL + EN base + HU reference)

---

## ⚠️ ANTI-SLOPPINESS HEADER — READ BEFORE EVERY AUDIT SESSION

**These rules are non-negotiable. Every single one applies to every single string.**

- DO NOT skim. Every string gets full dual-source evaluation.
- DO NOT assume. If a string looks fine, verify it explicitly.
- DO NOT skip edge cases. Short strings, button labels, error messages — all require the same scrutiny.
- DO NOT conflate "close enough" with "correct". A near-miss translation that uses the wrong register or wrong term is a FAIL.
- DO NOT finish early. An audit is complete only when every checklist item is ticked for every string.
- DO NOT accept an output just because it sounds fluent. Fluency ≠ accuracy.
- STOP and flag every anomaly, even if you think it may be intentional.
- When in doubt → **follow HU, not EN**.

---

## 1. DUAL-SOURCE TRANSLATION PRINCIPLE (MANDATORY — CORE QUALITY MECHANISM)

**Never translate from a single source.**

Every translation must use **both** EN and HU simultaneously, as defined below:

| Source | Role |
|--------|------|
| **English (EN)** | Structural guide: sentence shape, word order, grammatical scaffolding, overall meaning skeleton |
| **Hungarian (HU)** | Semantic ground truth: intended tone, exact meaning, formality level, nuance |

### Rule: When EN and HU differ → **always follow Hungarian.**

This is not a preference. It is the foundational quality rule.

**Why this exists:** The EN source files contain approximately 5% imperfect strings — subtle errors in tone, meaning, register, or phrasing. If any target locale translates purely from EN, these errors propagate undetected into that market. HU is the author's intended meaning, always.

### Translation Signal Map

```
ENGLISH SOURCE:      → sentence structure, vocabulary range
HUNGARIAN REFERENCE: → semantic truth, tone, intended meaning, formality
WEB REFERENCES:      → natural phrasing examples from real local pet owner sites
                       (forums, vet clinic sites, adoption platforms, pet shop copy)
→ Produce translation for [target language]
```

### Practical Dual-Source Workflow (per string)

1. Read EN string → extract sentence structure, length, grammatical form
2. Read HU string → extract intended meaning, register (formal/informal), emotional tone
3. Check EN vs HU for divergence → if they differ in meaning or tone, document the divergence and follow HU
4. Search 1–3 web references in the target language for how native speakers phrase this concept in a pet context
5. Synthesise translation using EN structure + HU meaning + native-web naturalness
6. Apply mandatory terminology from the Controlled Vocabulary (Section 3)
7. Run all string-level and locale-level checks (Sections 5–8)
8. Record result in audit log (Section 10)

---

## 2. LOCALE INVENTORY

| Code | Language | Script | Formality Default | EN→Locale Notes |
|------|----------|--------|-------------------|-----------------|
| SK | Slovak | Latin | Informal (ty) | Close to CZ — do NOT copy CZ strings verbatim |
| CZ | Czech | Latin | Informal (ty) | Close to SK — do NOT copy SK strings verbatim |
| DE | German | Latin | Formal (Sie) unless explicitly casual context | Compound nouns must be checked |
| HR | Croatian | Latin | Informal (ti) | Diacritics mandatory |
| RO | Romanian | Latin | Informal (tu) | Diacritics mandatory (ș ț ă â î) |
| IT | Italian | Latin | Informal (tu) | Gendered agreement must be checked |
| ES | Spanish | Latin | Informal (tú) | Gendered agreement must be checked; not LATAM |
| PT | Portuguese | Latin | Informal (você) | European PT, not Brazilian |
| FR | French | Latin | Informal (tu) for app; formal (vous) if context requires | Accents and ligatures mandatory |
| NO | Norwegian | Latin | Informal (du) | Bokmål — not Nynorsk |
| PL | Polish | Latin | Informal (ty) | Grammatical cases must be checked |

### Critical Locale Distinctions

- **PT must be European Portuguese**, not Brazilian. "Você" is acceptable in EU-PT for app context. "Plaquinha" is correct EU-PT for tag (not "placa"). Verify all strings that would differ between PT-BR and PT-PT.
- **ES must be European Spanish** (Castilian). No LATAM-specific vocabulary or voseo.
- **NO must be Bokmål**. Any Nynorsk form is a FAIL.
- **DE must default to Sie** (formal) unless the string is explicitly in an informal/community context (e.g. user-generated content labels). Document all de-formalisation decisions.
- **SK ≠ CZ**. They are mutually intelligible but distinct. Never copy-paste between them. Flag any string that looks like a CZ→SK or SK→CZ copy.

---

## 3. CONTROLLED VOCABULARY (MANDATORY TERM USAGE)

All terms below are **locked**. No synonyms, no alternatives, no "close enough" substitutions. Every deviation is a FAIL requiring correction.

If a string requires a term to be inflected (case, gender, number), inflect the **root term** as specified — do not substitute a different root.

| Concept | EN | HU | SK | CZ | DE | HR | RO | IT | ES | PT | FR | NO | PL |
|---------|----|----|----|----|----|----|----|----|----|----|----|----|-----|
| Pet | pet | kedvenc | domáci miláčik | mazlíček | Haustier | kućni ljubimac | animal de companie | animale di compagnia | mascota | animal de estimação | animal de compagnie | kjæledyr | pupil |
| Owner | owner | gazdi | páníček | páníček | Halter | vlasnik | stăpân | padrone | tutor | tutor | propriétaire | eier | opiekun |
| Tag | tag | biléta | známka | psí známka | Haustiermarke | privjesak | plăcuță inteligentă | medaglietta | chapa inteligente | plaquinha inteligente | médaille connectée | QR-brikke | adresówka |
| Account | account | fiók | účet | účet | Benutzerkonto | račun | cont | account | cuenta | conta | compte | konto | konto |
| Location | location | helyszín | poloha | poloha | Standort | lokacija | locație | posizione | ubicación | localização | localisation | posisjon | lokalizacja |

### Term Usage Rules

**Pet:**
- IT: "animale di compagnia" — note the controlled vocab table above corrects the source input ("animale decompagnia" is a typo in the brief; correct form is "animale di compagnia" with space and correct preposition). Flag this correction in every IT audit entry.
- PL: "pupil" is the approved term. Do not use "zwierzę domowe" or "piesek" etc. unless in a specific inflected context where "pupil" must be declined (e.g. "pupilem", "pupila").
- NO: "kjæledyr" — single compound word, no space, no hyphen.

**Owner:**
- DE: "Halter" (not "Besitzer", not "Eigentümer") — "Halter" is the correct legal/veterinary term for animal keeper in German-speaking markets.
- IT: "padrone" — acknowledged as traditional; do not substitute "proprietario" or "tutore" unless a specific string requires a legal context.
- ES/PT: "tutor" — reflects the modern, welfare-appropriate term. Do not revert to "dueño" (ES) or "dono" (PT).
- HR: "vlasnik" — do not use "gazda" (Bosnian/Serbian register) or "skrbnik".
- RO: "stăpân" — traditional term; verify it does not read as pejorative in context. If any string makes "stăpân" feel awkward, flag for review rather than substituting silently.
- SK/CZ: "páníček" — same root, but declension differs. Never assume SK and CZ inflections are identical.

**Tag:**
- DE: "Haustiermarke" — compound noun, one word, no hyphen. Not "Haustier-Marke".
- HR: "privjesak" — pendant/charm. Do not use "oznaka" (generic label).
- RO: "plăcuță inteligentă" — two words, diacritics mandatory (ă, ț).
- IT: "medaglietta" — diminutive, affectionate. Do not use "targhetta" or "medaglia".
- ES: "chapa inteligente" — two words. Do not use "placa" or "medalla".
- PT: "plaquinha inteligente" — European PT diminutive. Not "placa" or "plaqueta".
- FR: "médaille connectée" — two words. Not "médaille intelligente", not "puce".
- NO: "QR-brikke" — hyphenated compound, capital QR. Not "brikke" alone, not "QR-kode".
- PL: "adresówka" — colloquial but established pet-tag term. Not "znaczek" or "tag".

**Account:**
- DE: "Benutzerkonto" — full compound, one word. Not "Account", not "Konto" alone in UI context.
- All others: as specified. Note IT and ES/PT/PL/NO/HR all use shorter forms ("account", "cuenta", "conta", "konto", "račun") — verify each locale uses its correct form.

**Location:**
- DE: "Standort" — not "Ort", not "Position", not "Lage".
- IT: "posizione" — not "luogo", not "posizione GPS" (unless GPS is specifically relevant).
- FR: "localisation" — not "emplacement", not "position".
- NO: "posisjon" — not "sted", not "lokasjon".

### Inflection Tracking

When a controlled term appears in an inflected form, the audit must:
1. Identify the root term
2. Confirm the root matches the controlled vocabulary
3. Confirm the inflection is grammatically correct for the target language
4. Record both root and inflected form in the audit log

---

## 4. SOURCE DIVERGENCE PROTOCOL

When EN and HU strings differ (in meaning, tone, register, or completeness):

### Step 1: Classify the divergence

| Type | Description | Action |
|------|-------------|--------|
| **Tone shift** | EN is more formal/informal than HU | Follow HU register |
| **Meaning gap** | EN says X, HU says Y (different content) | Follow HU meaning, flag EN for correction |
| **Missing nuance** | HU has emotional/contextual content absent in EN | Include HU nuance in translation |
| **EN expansion** | EN has content HU lacks | Treat as potential EN addition; cross-check intent; if in doubt, follow HU brevity |
| **EN error** | EN is grammatically or semantically wrong | Ignore EN error, translate from HU, log the EN error |
| **Formatting divergence** | EN uses different punctuation/capitalisation/placeholder format | Preserve placeholder format from source; follow HU content |

### Step 2: Document every divergence

For every EN/HU divergence found, log:
- String key
- EN value (verbatim)
- HU value (verbatim)
- Divergence type (from table above)
- Translation decision
- EN correction recommendation (if EN is wrong)

### Step 3: Propagate corrections upstream

If a pattern of EN errors is found across multiple strings (e.g. consistently wrong formality, consistently incorrect term), flag it as a **systematic EN source issue** in the audit summary. Do not silently absorb systematic errors.

---

## 5. UNIVERSAL STRING-LEVEL CHECKLIST

Run every item below on **every string** in every locale. No exceptions.

### 5.1 Semantic Accuracy

- [ ] Does the translation convey the exact meaning of the HU source?
- [ ] Are there any additions, omissions, or distortions vs HU?
- [ ] Does it make sense to a native speaker in this exact product context?
- [ ] If EN and HU differ, was HU followed?
- [ ] Have web references been consulted to verify natural phrasing?

### 5.2 Controlled Vocabulary Compliance

- [ ] Every controlled term (pet, owner, tag, account, location) uses the exact approved form for this locale
- [ ] Where terms are inflected, the root is correct and the inflection is grammatically sound
- [ ] No unapproved synonyms appear anywhere in the string
- [ ] DE: "animale di compagnia" (IT term) has been corrected from source typo where applicable

### 5.3 Register and Tone

- [ ] Formality level matches the locale default (Section 2) and string context
- [ ] DE: "Sie" used unless context explicitly requires "du"; document all exceptions
- [ ] NO: Bokmål register throughout; no Nynorsk forms
- [ ] Emotional tone (warmth, urgency, reassurance, playfulness) matches HU source tone
- [ ] Not overly formal where HU is warm; not casual where HU is instructional

### 5.4 Grammar and Syntax

- [ ] Grammatically correct in the target language
- [ ] Word order is natural (not a calque of EN structure)
- [ ] For inflected languages (SK, CZ, HR, RO, PL): all cases are correct
- [ ] For gendered languages (DE, HR, RO, IT, ES, PT, FR, PL): all gender agreements are correct
- [ ] Plural forms are correct (especially for PL which has complex plural rules; and for RO)
- [ ] Verb conjugations are correct for the grammatical person used

### 5.5 Placeholders and Variables

- [ ] All placeholders present in EN source are present in translation (e.g. `{petName}`, `{ownerName}`, `%s`, `%d`, `{{variable}}`)
- [ ] No placeholders added that were not in the source
- [ ] Placeholder format is character-for-character identical to source (case, brackets, underscore)
- [ ] Surrounding text handles the placeholder grammatically (in inflected languages, the noun class of the placeholder's expected value must be handled correctly)
- [ ] No spaces introduced inside placeholder delimiters

### 5.6 Punctuation and Formatting

- [ ] Sentence-final punctuation matches source intent (if source has full stop, translation should too — unless target language conventions differ)
- [ ] Ellipsis: use `…` (single character U+2026) not `...` (three periods) — check locale convention
- [ ] Quotation marks: use locale-appropriate quotation marks (DE: „…", FR: «…», others: verify)
- [ ] Apostrophes: locale-appropriate form
- [ ] No trailing whitespace
- [ ] No double spaces
- [ ] Capitalisation follows target language conventions (not EN Title Case applied blindly)

### 5.7 Diacritics (Mandatory for Affected Locales)

- [ ] **HR**: All Croatian diacritics present — č, ć, š, ž, đ. Zero tolerance for missing diacritics.
- [ ] **RO**: All Romanian diacritics present — ș (comma below), ț (comma below), ă, â, î. Specifically: ș and ț must use COMMA BELOW (U+0219, U+021B), NOT cedilla (U+015F, U+0163). This is a known copy-paste error source.
- [ ] **CZ**: All Czech diacritics present — á, č, ď, é, ě, í, ň, ó, ř, š, ť, ú, ů, ý, ž
- [ ] **SK**: All Slovak diacritics present — á, ä, č, ď, dz, dž, é, í, ľ, ĺ, ň, ó, ô, ŕ, š, ť, ú, ý, ž
- [ ] **PL**: All Polish diacritics present — ą, ć, ę, ł, ń, ó, ś, ź, ż
- [ ] **FR**: All French accents and ligatures present — é, è, ê, ë, à, â, î, ï, ô, ù, û, ü, ç, œ, æ
- [ ] **DE**: All German umlauts and ß present — ä, ö, ü, Ä, Ö, Ü, ß (verify ß vs ss per new orthography rules)
- [ ] **NO**: Norwegian-specific characters — æ, ø, å

### 5.8 String Length

- [ ] Is the string within acceptable length limits for its UI context?
- [ ] If the string is for a button, label, or tab: flag if >40% longer than EN (risk of UI overflow)
- [ ] If the string is for a notification or SMS: flag if exceeds 160 characters (SMS segment boundary)
- [ ] If the string is for a push notification title: flag if >50 characters
- [ ] If the string is for a push notification body: flag if >100 characters
- [ ] DE tends to produce the longest strings (compound nouns + formal Sie constructions) — apply extra length scrutiny
- [ ] PL, HR, RO also tend to expand — check UI contexts carefully

### 5.9 Cultural Appropriateness

- [ ] Does the string feel natural to a native speaker in a pet app context?
- [ ] No calques or literal translations that would sound unnatural
- [ ] Local idioms used where appropriate (verified via web references)
- [ ] No expressions that have unintended connotations in the target culture
- [ ] Names, examples, and hypotheticals (e.g. "Max the dog") are culturally plausible in the target market

### 5.10 Legal and Compliance Strings

- [ ] Privacy policy references translate the legal concepts accurately (not just literally)
- [ ] GDPR terminology follows official EU translations in the target language (e.g. FR: "données à caractère personnel", DE: "personenbezogene Daten")
- [ ] Consent language is unambiguous and legally appropriate
- [ ] Subscription/billing strings use correct local currency conventions if currency appears
- [ ] "Cancel subscription", "Free trial", "Automatic renewal" strings are crystal clear — ambiguity in these is a compliance risk

---

## 6. LOCALE-SPECIFIC DEEP CHECKS

In addition to the universal checklist, apply every item below for each locale.

### 6.1 Slovak (SK)

- [ ] Consistently uses "ty/vy" address; not mixing SK and CZ pronoun forms
- [ ] "domáci miláčik" used for pet; correctly declined in all cases (nom: domáci miláčik; gen: domáceho miláčika; dat: domácemu miláčikovi; acc: domáceho miláčika; loc: domácom miláčikovi; ins: domácim miláčikom)
- [ ] "páníček" used for owner (verify this is not felt as condescending in context — it is the owner being addressed as "master" from the pet's perspective, which is an intentional playful register)
- [ ] "známka" used for tag; confirmed as natural in Slovak pet context (not just a translation of "mark" or "stamp")
- [ ] "účet" for account; "poloha" for location
- [ ] No CZ-isms crept in (common cross-contamination points: ř → only in CZ; specific vocabulary divergences)
- [ ] Verify: "ž" diacritic (SK has ž, CZ has ž — same letter, but verify rendering)
- [ ] Soft consonants (ľ, ĺ, ŕ) are rendered correctly, not replaced with l or r

### 6.2 Czech (CZ)

- [ ] Consistently uses "ty/vy" address
- [ ] "mazlíček" used for pet; correctly declined in all cases
- [ ] "páníček" used for owner (same playful register as SK — verify fits context)
- [ ] "psí známka" used for tag (two words, with "psí" = dog's; verify this term works for cat tags too — if there is a cat-specific context, flag for review)
- [ ] "účet" for account; "poloha" for location
- [ ] No SK-isms (watch for ä → CZ does not use ä; ľ → CZ does not use ľ)
- [ ] ř is present where required (one of the most dialect-identifying CZ phonemes — its absence signals a non-native translator)
- [ ] Háček (ˇ) and čárka (´) diacritics correctly rendered throughout

### 6.3 German (DE)

- [ ] Default formality: **Sie** (with capital S) throughout, unless string is explicitly in an informal user context
- [ ] All instances of "Sie" are capitalised (lowercase "sie" = she/they — completely different meaning)
- [ ] Compound nouns written as single words: "Haustiermarke" (not "Haustier-Marke" or "Haustier Marke"), "Benutzerkonto" (not "Benutzer Konto"), "Standort" (not "Stand Ort")
- [ ] "Halter" used for owner (not "Besitzer" — "Besitzer" implies ownership of a thing; "Halter" is the correct term for an animal keeper in DE/AT/CH legal/veterinary register)
- [ ] Genitive constructions are correct (German genitive with "des/der" or -s suffix)
- [ ] Adjective declension is correct (strong/weak/mixed depending on article presence)
- [ ] Modal particle use sounds natural (German has particles like "doch", "mal", "schon" that native speakers expect — their absence can make text feel translated)
- [ ] No anglicisms where German equivalents exist (except "Account" is borderline acceptable but "Benutzerkonto" is specified)
- [ ] ß vs ss: post-1996 orthography rules (ß after long vowels and diphthongs; ss after short vowels). Common errors: "daß" → "dass"; "muß" → "muss"
- [ ] Date/time format: DD.MM.YYYY (not MM/DD/YYYY)
- [ ] Quotation marks: „text" (lower-99 open, upper-66 close) — not "text" or «text»

### 6.4 Croatian (HR)

- [ ] All diacritics present: č, ć, š, ž, đ — zero tolerance for missing
- [ ] "kućni ljubimac" used for pet (two words, both must be present and correctly inflected together)
- [ ] "vlasnik" used for owner (not "gazda" or "skrbnik")
- [ ] "privjesak" used for tag
- [ ] "račun" for account; "lokacija" for location
- [ ] Grammatical case agreement: adjective-noun pairs must agree in case, gender, number
- [ ] Verbs are correctly conjugated for the grammatical person
- [ ] No Bosnian or Serbian vocabulary used (similar languages; HR has specific standardised forms)
- [ ] Latin script used throughout (HR official script — no Cyrillic)

### 6.5 Romanian (RO)

- [ ] **Critical diacritic check**: ș (U+0219 LATIN SMALL LETTER S WITH COMMA BELOW) and ț (U+021B LATIN SMALL LETTER T WITH COMMA BELOW) — must use COMMA BELOW variants, NOT cedilla variants (ş U+015F, ţ U+0163). This is the single most common Romanian localisation error. Check programmatically if possible.
- [ ] Also verify: ă (U+0103), â (U+00E2), î (U+00EE)
- [ ] "animal de companie" used for pet (three words)
- [ ] "stăpân" used for owner — diacritic on ă mandatory
- [ ] "plăcuță inteligentă" used for tag — both diacritics present (ă in plăcuță, ă in inteligentă)
- [ ] "cont" for account; "locație" for location (with ț comma-below)
- [ ] Definite article in Romanian is postpositional (attached to end of noun) — verify articles are correct: "câinele" (the dog), "pisica" (the cat, fem.), etc.
- [ ] Grammatical gender agreement: Romanian has 3 genders (masculine, feminine, neuter) — neuter behaves as masculine in singular, feminine in plural
- [ ] Plural rules are complex — verify irregular plurals

### 6.6 Italian (IT)

- [ ] **Source typo correction**: The brief contains "animale decompagnia" — this is a typo. Correct form is "animale di compagnia" (space + correct preposition "di"). Flag and correct in every occurrence.
- [ ] "padrone" used for owner; verify it does not read negatively in any specific string context
- [ ] "medaglietta" used for tag (affectionate diminutive — verify this tone is appropriate for all contexts, including formal ones like account settings)
- [ ] "account" for account (loanword, acceptable); "posizione" for location
- [ ] Grammatical gender: all adjective-noun agreements are correct (masculine/feminine)
- [ ] Articles: definite (il/lo/la/i/gli/le) and indefinite (un/uno/una) are correct
- [ ] Elision: "l'animale" (not "lo animale" or "la animale") — verify all article + vowel-initial noun combinations
- [ ] Apostrophe usage: "dell'animale", "all'animale" etc.
- [ ] Accents on final vowels: città, perché, però, già — verify all accented finals
- [ ] Informal "tu" address used; no "Lei" (formal) unless a specific string requires it

### 6.7 Spanish (ES)

- [ ] **European Spanish only** — no LATAM vocabulary, no voseo (vos + verb form), no LATAM-specific idioms
- [ ] "mascota" used for pet; "tutor" used for owner
- [ ] "chapa inteligente" used for tag (two words); "cuenta" for account; "ubicación" for location
- [ ] Informal "tú" address used throughout (not "usted" unless formal legal context)
- [ ] Grammatical gender agreement: all adjective-noun pairs must agree (masculine/feminine, singular/plural)
- [ ] Inverted punctuation: ¿…? for questions, ¡…! for exclamations — check all interrogative and exclamatory strings
- [ ] Accents: á, é, í, ó, ú, ü, ñ — all present where required
- [ ] Diaeresis on ü: "vergüenza", "pingüino" — verify where applicable
- [ ] No anglicisms where Spanish equivalents are specified (e.g. must not say "tag" instead of "chapa inteligente")
- [ ] Date format: DD/MM/YYYY (European convention)

### 6.8 Portuguese (PT)

- [ ] **European Portuguese only** — not Brazilian Portuguese
- [ ] Key EU-PT vs PT-BR divergences to check:
  - "você" is standard in EU-PT app context (not "tu" as primary)
  - "plaquinha inteligente" is the approved tag term — verify this reads naturally in EU-PT (note: diminutive "-inha" is more common in PT-BR; in EU-PT it can sound slightly informal but is acceptable for this product context)
  - EU-PT vocabulary: "autocarro" not "ônibus"; "casa de banho" not "banheiro"; "telemóvel" not "celular" — verify any infrastructure or device references
  - EU-PT spelling conventions post-2009 Orthographic Agreement: some spellings changed, some didn't — verify current standard
- [ ] "animal de estimação" used for pet; "tutor" for owner; "conta" for account; "localização" for location
- [ ] Grammatical gender agreement: all adjective-noun agreements correct (masculine/feminine)
- [ ] Definite articles: o/a/os/as — correct usage throughout
- [ ] Accents: á, â, ã, à, é, ê, í, ó, ô, õ, ú, ü, ç — all present where required
- [ ] Nasal vowels (ã, ão, em, en) correctly rendered

### 6.9 French (FR)

- [ ] Informal "tu" for app UI; "vous" only if a specific string is formally addressed (e.g. legal/privacy copy)
- [ ] "animal de compagnie" used for pet; "propriétaire" for owner; "médaille connectée" for tag; "compte" for account; "localisation" for location
- [ ] **French spacing rules**: In French, certain punctuation requires a non-breaking space before it:
  - Before : (colon) — "Mon compte :"
  - Before ; (semicolon) — space before
  - Before ! (exclamation mark) — non-breaking space before
  - Before ? (question mark) — non-breaking space before
  - Inside « » (guillemets) — thin space inside: « texte »
  - Verify these rules are applied, or at minimum that colons and guillemets are handled
- [ ] Guillemets for quotation marks: «…» with appropriate spacing — not English "…"
- [ ] Accents: é, è, ê, ë, à, â, î, ï, ô, ù, û, ü, ç, œ, æ — all present where required
- [ ] œ (oe ligature): "cœur", "œuvre" — verify ligature is used, not "oe"
- [ ] Elision: "l'animal" (not "le animal"); "j'ai" (not "je ai") — all elisions before vowels
- [ ] Gender agreement: French nouns have gender; all articles and adjectives must agree
- [ ] Plural -s: regular plurals and irregular plurals (œil → yeux etc.)
- [ ] Capitalisation: French generally does NOT capitalise nouns mid-sentence (unlike DE) — check for anglicisms in capitalisation

### 6.10 Norwegian (NO)

- [ ] **Bokmål only** — not Nynorsk. Verify no Nynorsk forms anywhere.
  - Common Nynorsk indicators: "ikkje" (Nynorsk) vs "ikke" (Bokmål); "eg" vs "jeg"; "kva" vs "hva"
- [ ] "kjæledyr" used for pet (one word, no space or hyphen); "eier" for owner; "QR-brikke" for tag (hyphenated, capital QR); "konto" for account; "posisjon" for location
- [ ] Informal "du" address throughout
- [ ] Norwegian does not use ß, ø and æ and å must be present where required — these are separate letters, not diacritics
- [ ] Word order: Norwegian has V2 rule (verb second in main clauses) — verify complex sentences
- [ ] Compound words: Norwegian frequently forms compounds; verify they are written correctly (one word vs hyphenated vs two words)
- [ ] "QR-brikke" — verify this is the term used in Norwegian pet/tech contexts; confirm via web reference

### 6.11 Polish (PL)

- [ ] "pupil" used for pet; "opiekun" for owner; "adresówka" for tag; "konto" for account; "lokalizacja" for location
- [ ] **Grammatical case system** — Polish has 7 cases. Every noun phrase must be in the correct case:
  - Nominative (mianownik) — subject
  - Genitive (dopełniacz) — possession, negation, quantities
  - Dative (celownik) — indirect object
  - Accusative (biernik) — direct object
  - Instrumental (narzędnik) — with, by means of
  - Locative (miejscownik) — location, always with preposition
  - Vocative (wołacz) — direct address
- [ ] "pupil" declined correctly: pupil (nom), pupila (gen), pupilowi (dat), pupila (acc), pupilem (ins), pupilu (loc), pupilu (voc)
- [ ] "opiekun" declined correctly in all contexts
- [ ] **Polish plural rules** are highly irregular. Three categories:
  - 1: singular (1 pupil)
  - 2–4, 22–24, 32–34…: genitive singular (2 pupile)
  - 5+, 11–14, 21…: genitive plural (5 pupili)
  - Verify all plural strings use the correct form for the number they represent
- [ ] All Polish diacritics present: ą, ć, ę, ł, ń, ó, ś, ź, ż
- [ ] ł vs l: these are different letters with completely different pronunciation and meaning — verify no ł→l substitution
- [ ] Informal "ty" address; no "Pan/Pani" (formal) unless specifically required
- [ ] Aspect (perfective/imperfective verbs): Polish verbs have two aspects; the correct one must be used for each context (completed action vs ongoing/habitual)

---

## 7. CATEGORY-SPECIFIC AUDIT RULES

Apply the relevant category rules in addition to all universal checks.

### 7.1 Onboarding and Setup Strings

- [ ] Welcoming and warm tone — matches HU emotional register
- [ ] Clear calls to action — imperative verb form is natural, not robot-like
- [ ] Product name "Senra" is not translated, adapted, or gendered (always "Senra")
- [ ] First-time experience strings do not assume prior knowledge of the product
- [ ] Progressive disclosure: early strings should not reference features not yet introduced

### 7.2 Pet Profile Strings (Name, Breed, Species, DOB, etc.)

- [ ] "pet" term correctly used and declined in context
- [ ] "owner" term correctly used and declined in context
- [ ] Breed names: if localised, must match official recognised breed name in target language; if not localised, use English with no change
- [ ] Species labels (dog, cat, etc.): natural common name in target language, not Latin
- [ ] Age/DOB: date format follows locale convention
- [ ] Gender labels: must use grammatically correct forms in gendered languages

### 7.3 Tag and QR Code Strings

- [ ] "tag" term used consistently — the controlled vocabulary term for every locale
- [ ] Instructions for physical tag setup are crystal clear — a pet owner who has never used a QR product must understand these
- [ ] Scanning instructions: "scan" verb must be natural in target language (DE: "scannen" is acceptable as a loanword; verify naturalness per locale)
- [ ] Recovery flow strings: urgency tone matches HU source — this is a stressful moment for a pet owner finding a lost pet
- [ ] "Found pet" and "Lost pet" labels are emotionally appropriate and immediately understandable
- [ ] QR-specific strings in NO: "QR-brikke" used; scanning instructions reference QR clearly

### 7.4 Account and Settings Strings

- [ ] "account" term consistently applied from controlled vocabulary
- [ ] Subscription tier names (Free / Standard / Maximum): check if these are translated or kept in English — if translated, confirm the translations are consistent across all locales and all strings that reference them
- [ ] "Cancel subscription" strings: must be unambiguous and legally clear
- [ ] Privacy settings strings: GDPR-aligned language; "data", "consent", "delete account" must be unambiguous
- [ ] Email/notification preference strings: clear opt-in/opt-out language

### 7.5 Notification Strings (Push, Email, SMS)

- [ ] Length within platform limits (push title ≤50 chars, body ≤100 chars, SMS ≤160 chars)
- [ ] Urgency/alert notifications: tone is immediate and clear — no ambiguity about what action is needed
- [ ] "location" term from controlled vocabulary used consistently
- [ ] Personalisation tokens ({petName}, {ownerName}) correctly placed and grammatically handled
- [ ] SMS: character count includes any diacritics — diacritics may force GSM-7 → UCS-2 encoding, halving the per-segment character limit (70 chars per segment in UCS-2 vs 160 in GSM-7). Flag any SMS string with diacritics that exceeds 70 characters.

### 7.6 Error Messages and Validation Strings

- [ ] Friendly but clear — not robotic, not alarming
- [ ] Actionable: tells the user what to do, not just what went wrong
- [ ] Technical jargon is absent or explained
- [ ] Error codes (if present) are accompanied by human-readable description
- [ ] Validation messages ("This field is required", "Invalid email") are naturally phrased in target language

### 7.7 Legal and Privacy Strings (Privacy Policy, Terms)

- [ ] Legal terms use official translations from EU/national regulatory bodies where applicable
- [ ] GDPR key terms must use the official EU terminology in target language:
  - "data controller" — DE: "Verantwortlicher"; FR: "responsable du traitement"; ES: "responsable del tratamiento"; IT: "titolare del trattamento"; PL: "administrator danych"; RO: "operator"; HR: "voditelj obrade"; SK: "prevádzkovateľ"; CZ: "správce"
  - "data subject" — DE: "betroffene Person"; FR: "personne concernée"; ES: "interesado"; IT: "interessato"; PL: "osoba, której dane dotyczą"
  - "personal data" — DE: "personenbezogene Daten"; FR: "données à caractère personnel"; ES: "datos personales"; IT: "dati personali"; PL: "dane osobowe"
- [ ] "Delete account" and "Delete all data" strings are unambiguous and clearly irreversible
- [ ] Consent strings do not include double negatives or ambiguous phrasing

---

## 8. CROSS-LOCALE CONSISTENCY CHECKS

These checks must be run across all locales simultaneously after individual locale checks are complete.

### 8.1 Term Consistency Across Same-Language Variants

- [ ] All controlled vocabulary terms are applied identically across all strings within each locale (no string uses "psí visačka" in one place and "psí známka" in another within CZ)
- [ ] Tone consistency within a locale: if a locale uses informal register, it is informal throughout — no formal/informal mixing

### 8.2 Cross-Locale Format Parity

- [ ] All locales have the same set of string keys — no keys present in one locale but missing in another
- [ ] All locales handle the same placeholders in each string
- [ ] Date/time format conventions are applied per-locale (not copied from EN)

### 8.3 EN String Integrity (Ongoing Monitoring)

- [ ] Log any EN string errors discovered during dual-source review
- [ ] Maintain running count of EN errors found per audit session
- [ ] Produce EN correction recommendations list at end of each audit session
- [ ] Confirm EN errors are not being silently propagated to any locale

### 8.4 Locale Pair Contamination Check

Specifically check the following high-risk locale pairs for cross-contamination:

| Pair | Contamination Risk |
|------|--------------------|
| SK ↔ CZ | Most similar languages; vocabulary and grammar can be confused |
| ES ↔ PT | Similar Romance roots; PT-BR vs PT-PT confusion; "mascota" in PT would be wrong |
| HR ↔ SR (Serbian) | HR strings must not use Serbian vocabulary or orthography |
| NO (Bokmål) ↔ NO (Nynorsk) | Must be Bokmål only |
| FR (EU) ↔ FR (Canadian) | Must be EU French |

---

## 9. WEB REFERENCE VERIFICATION PROTOCOL

For every locale, when a string's phrasing is uncertain, the following web reference check must be performed:

### 9.1 Reference Source Types (in priority order)

1. **National veterinary association websites** — e.g. BVA (UK), BSAVA, national equivalents in each market — use correct technical language
2. **National animal shelters and rescue organisations** — use warm, accessible language that matches the product's emotional register
3. **Pet product retailers in target market** — Fressnapf (DE), Maxi Zoo (EU), Zooplus (EU) — show how pet products are marketed to consumers
4. **National pet owner forums or Facebook groups** — show how real pet owners communicate about these topics
5. **National pet insurance companies** — show formal/legal register for insurance/policy terms

### 9.2 What to Verify via Web References

- Natural phrasing of the specific concept in context
- Whether the controlled vocabulary term is actually used on real local sites
- Whether an alternative term is more prevalent (flag but do not change without approval)
- Register (formal/informal) used by native speakers for this concept
- Any regional variation concerns (e.g. Austrian DE vs German DE)

### 9.3 Documenting Web References

For every string where a web reference was consulted, log:
- URL of reference
- Target locale
- String key
- What the reference confirmed or challenged

---

## 10. AUDIT LOG FORMAT

Every audit session must produce a structured log. Use the format below for every string reviewed.

### 10.1 Per-String Entry

```
STRING KEY:        [e.g. pet_profile.name_label]
EN SOURCE:         [verbatim EN string]
HU REFERENCE:      [verbatim HU string]
EN/HU DIVERGENCE:  [None | Type: ___ | Description: ___]
TARGET LOCALE:     [e.g. DE]
CURRENT VALUE:     [existing translation if re-auditing; "NEW" if fresh]
PROPOSED VALUE:    [translation or correction]
TERM COMPLIANCE:   [PASS | FAIL — list any failures]
GRAMMAR CHECK:     [PASS | FAIL — describe any issues]
DIACRITICS CHECK:  [PASS | FAIL | N/A]
REGISTER CHECK:    [PASS | FAIL — note expected vs found]
PLACEHOLDER CHECK: [PASS | FAIL | N/A]
LENGTH CHECK:      [PASS | WARN | FAIL — note context and char count if relevant]
WEB REFERENCE:     [URL if consulted; "Not required" if not]
VERDICT:           [PASS | NEEDS CORRECTION | REJECT]
NOTES:             [Any additional observations]
```

### 10.2 Session Summary

At the end of each audit session, produce:

```
AUDIT SESSION SUMMARY
=====================
Date: 
Auditor: Claude
Locales covered: 
Strings reviewed: 
Strings passed: 
Strings needing correction: 
Strings rejected: 

EN SOURCE ERRORS FOUND:
- [List of EN string keys with errors and recommended corrections]

SYSTEMATIC ISSUES IDENTIFIED:
- [Any patterns of errors across multiple strings or locales]

TERM COMPLIANCE FAILURES:
- [Locale | String key | Wrong term used | Correct term]

DIACRITIC FAILURES:
- [Locale | String key | Character at issue]

OPEN QUESTIONS / REVIEW FLAGS:
- [Any strings requiring human review due to ambiguity or cultural sensitivity]
```

---

## 11. ESCALATION CRITERIA

The following situations require escalation to a human reviewer rather than autonomous resolution:

- Any string where the correct translation is genuinely ambiguous after dual-source review
- Any controlled vocabulary term that appears to be wrong or unnatural in context for a specific locale (do not silently substitute; flag for vocabulary owner review)
- Any EN source error that changes meaning significantly enough that a product decision may be needed
- Any string with legal implications (consent, data deletion, subscription terms) where the translation may not carry the same legal weight as the source
- Any cultural appropriateness concern that could affect brand perception
- Any divergence in a core product concept (what "Senra" does, how the tag works, what the recovery flow means) between locales
- Any string where the controlled vocabulary term appears genuinely unused on real local websites (raise for vocabulary review, do not override)

---

## 12. QUICK REFERENCE — MOST COMMON ERRORS

Based on known localisation failure patterns for these locale types:

| Error Type | Locales at Risk | What to Check |
|------------|----------------|---------------|
| ș/ț cedilla vs comma-below | RO | U+0219 vs U+015F; U+021B vs U+0163 |
| Single-source translation (EN only) | All | Was HU consulted? Is HU meaning present? |
| Wrong formality | DE | "Sie" throughout (capitalised) |
| Nynorsk forms | NO | "ikkje", "eg", "kva" — all are Nynorsk |
| SK/CZ cross-contamination | SK, CZ | Vocabulary and case endings drift |
| Missing diacritics | HR, RO, CZ, SK, PL, FR, DE, NO | Run diacritic check programmatically |
| Wrong "owner" term | DE, IT, ES, PT | Halter / padrone / tutor / tutor |
| IT source typo propagated | IT | "animale decompagnia" → "animale di compagnia" |
| PL plural form wrong | PL | 1/2-4/5+ rule; genitive singular/plural |
| FR spacing rules ignored | FR | Non-breaking space before :, ;, !, ?, and inside « » |
| Placeholder not carried over | All | Grep for all `{`, `%`, `{{` in source |
| PT-BR vs PT-PT | PT | Vocabulary, spelling, register |
| ES LATAM vs ES-ES | ES | Vocabulary (voseo, LATAM terms) |
| Length overflow (DE) | DE | Compound nouns + Sie constructions are long |
| SMS encoding (diacritics) | All | UCS-2 encoding halves character limit |

---

## 13. GREP / PROGRAMMATIC CHECKS

Run the following checks programmatically where possible before manual audit:

```bash
# Check for RO cedilla (wrong form) — should return 0 results
grep -rn $'\u015F\|\u0163' locales/ro/

# Check for missing placeholders (example: find strings where EN has {petName} but target does not)
# (implement in senra_gap_check.py or equivalent)

# Check for double spaces in all locale files
grep -rn '  ' locales/

# Check for trailing whitespace
grep -rn ' $' locales/

# Check for three-dot ellipsis (should use … U+2026)
grep -rn '\.\.\.' locales/

# Check for SK strings that contain CZ-only characters (ř is CZ only, not used in SK)
grep -rn 'ř' locales/sk/

# Check for NO strings that contain Nynorsk-indicator words
grep -rn 'ikkje\|^eg \| eg \|kva ' locales/no/

# Check for DE strings with lowercase "sie" that may be incorrect "Sie"
# (complex — context-dependent, but useful for manual review candidates)
grep -n ' sie ' locales/de/
```

---

## 14. FINAL SIGN-OFF CRITERIA

An audit is considered **complete and signeable** only when ALL of the following are true:

- [ ] Every string in every locale has been reviewed against the dual-source principle
- [ ] Every string has passed or been corrected to pass all items in the universal checklist (Section 5)
- [ ] Every string has passed or been corrected to pass all applicable locale-specific checks (Section 6)
- [ ] Every string has passed or been corrected to pass all applicable category checks (Section 7)
- [ ] Cross-locale consistency checks (Section 8) have been run and passed
- [ ] All EN source errors found have been logged and recommendations produced
- [ ] All escalation-worthy items have been escalated
- [ ] Audit log is complete with every string entry
- [ ] Session summary has been produced
- [ ] No open FAIL items remain unresolved

**If any item above is incomplete, the audit is NOT done. Do not summarise or conclude before every item is checked.**

---

*End of CLAUDE-localisation-audit.md*
*Senra / Outeiro Kft | Maintained alongside CLAUDE-flow-audit.md and CLAUDE-prod-audit.md*

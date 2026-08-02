# Web Handoff — API Contract (U1/U2/U3/U4)

**Status: FROZEN 2026-08-01.** §9's four open questions are closed (see §9); the host, the destination
paths, and the redeem shape are all verified against running code rather than assumed. Clients may be
built against this document.

Written 2026-07-30 by the review seat; frozen after the 2026-08-01 verification pass.

**What "frozen" binds** — §8's left column: the endpoint path and method, the request field names and
`destination` values, that the response carries `url`, and fallback-on-any-failure. Everything in §8's
right column stays free to change without a store cycle. **Changing anything in the left column after a
client ships is a store cycle**, which is the entire reason this document exists.

**Corrections made at freeze time, each against running code:**
- §2 — two of four destination paths were wrong (`manage_subscription` is top-level; `orders` has no route)
- §3 — `locale_hint` is language-only, never market
- §4 — `POST /auth/login` named as the wrong precedent; the web user flow is OTP
- §5 — device region banned in both clients' fallbacks; the "Android's host is done" claim corrected
- §§10–11 — session establishment and the auth-boundary asymmetry, both added
- **the prod host itself** — `app.senra.pet` does not exist

## Why this document exists

Mobile clients ship on a store cycle; the server does not. Anything a fielded client hardcodes is stuck until the next review. So the contract's single organising rule is:

> **The client sends intent. The server returns a URL. The client opens whatever comes back.**

Everything else — host, country segment, path, param name, token format — stays server-side and stays changeable.

This dissolves two defects already found by construction:
- the **host cross-wire** (clients built on `https://senra.pet` unconditionally, cross-wiring every staging QA session to prod), and
- the **`/uk/` market bug** (country segment derived from *device region* via `regionToCountry`, defaulting to `uk`, so a Hungarian on an English-region phone lands on the UK site with EUR pricing and no Kedvenc csomag).

Neither can recur once the server builds the URL.

---

## 1. Issue endpoint

```
POST /api/auth/web-handoff
Authorization: Bearer <access token>          # required
Content-Type: application/json

{
  "destination": "choose_plan",               # required, enum — see §2
  "locale_hint": "en-US"                      # optional, advisory only
}
```

**200**
```json
{
  "url": "https://senra.pet/hu/choose-plan?handoff=<opaque>",
  "expires_in": 90
}
```

**Errors** — every one of them means the client falls back (§5), so none needs a distinct client behaviour:

| Status | When |
|---|---|
| `400` | unknown `destination` — **fail loudly, never silently substitute a default** |
| `401` | missing/invalid token |
| `429` | rate limited |
| `5xx` | anything else |

## 2. `destination` enum — frozen from day one

Adding a value later is a server change; a client *sending* a new value is a store cycle. So the enum is defined now even though only the first ships in v1.

**CONFIRMED against `CountryRoutes.tsx` @ tagme-now `a085bf5` (sha256 `3ca143f5e2f1`, 290 lines), 2026-08-01. Two of the four draft paths were WRONG.**

| Value | Path | Route line | Auth | v1? |
|---|---|---|---|---|
| `choose_plan` | `/{cc}/choose-plan` | 194 | **public** | **yes** |
| `manage_subscription` | `/{cc}/manage-subscription` | 195 | **public** | reserved |
| `orders` | *(no route exists)* | — | — | reserved, always `400` |
| `account` | `/{cc}/account` | 205 | **protected** | reserved |

- ~~`/{cc}/account/subscription`~~ → **`/{cc}/manage-subscription`**. It is a **top-level route, not nested under `account`.**
- ~~`/{cc}/account/orders`~~ → **there is no orders route, and no orders page.** The only order-shaped pages are `OrderConfirmation` and `OrderReplacementTag`; neither is an order list. `orders` **stays in the v1 enum** and **always returns `400`** — per the rule below, that is exactly what "reserved" means, and keeping the value reserved now avoids a store cycle if an orders page is ever built.

Reserved values must return `400` until implemented — not a redirect to `choose_plan`. A client landing somewhere it didn't ask for is worse than a client falling back.

## 3. URL construction — server-side, in one place

**Host** — from environment config. **`https://senra.pet` (prod)**, `https://staging-app.senra.pet` (staging). Never hardcoded in a client.

**⚠️ NOTE THE ASYMMETRY — it is not a typo.** Staging carries the `-app` prefix; **prod does not**. An earlier draft of this document specified `https://app.senra.pet` for prod. **That host does not exist**: zero DNS records of any type (A, AAAA, CNAME), and `terraform/frontend.tf:130` declares the distribution's aliases as exactly `["senra.pet", "www.senra.pet"]`. A U1 built to that draft would have returned a URL to a dead host — and because the whole contract rests on "the client opens whatever comes back", the client would have had no way to recover. Verified 2026-08-01: `senra.pet/hu/choose-plan` → 200, `app.senra.pet` → no resolution.

**Country segment — always `hu`.**

The mobile apps are distributed in the **Hungarian store only**, and that is not planned to change. Every mobile user is therefore an HU-market customer by construction: HUF pricing, Kedvenc csomag, the HU catalog. There is no legitimate case where a mobile-originated handoff should land on another market's page.

This deliberately does **not** consult `users.country`. That column holds non-ISO2-clean values in prod (the standing normalisation item), so reading it would add a failure mode to solve a problem that does not exist while mobile is HU-only.

**Never** derive the segment from device region. Store availability fixes the market; device region is a *language* signal. Conflating the two is precisely the `/uk/` bug — a Hungarian customer on an English-region phone is an HU customer, not a UK one.

**If mobile ever expands beyond HU**, this becomes a resolution chain (normalised `users.country` → `hu`). That is a server change requiring no store cycle — which is the entire reason the URL is built here rather than in the client.

**⚠️ `locale_hint` IS LANGUAGE-ONLY. IT MUST NEVER ENTER MARKET RESOLUTION.** An earlier draft of the sentence above put `locale_hint` in the market chain; that is the `/uk/` bug rebuilt on the server, where it would be harder to see. The market is fixed by store availability (`hu`); the language is a separate axis and is the *only* thing `locale_hint` may influence.

The two are genuinely independent, and §9 proved it: `/hu/` **forces** Hungarian copy (`countries.ts:18` gives `hu` the `language: 'hu'`; `CountryContext.tsx:33-37` calls `changeLanguage(country.language)`), so an HU-market customer who reads English is shown a page they cannot read at the moment they are asked to pay. `locale_hint` exists to fix **that**, and nothing else. A server that reads `locale_hint` and changes the `{cc}` segment is reintroducing the defect this document was written to close.

## 4. Token

- **Opaque**, ≥128 bits of entropy, no user data encoded.
- **Single-use.** Redeeming consumes it; a second redeem fails.
- **TTL 90s.** Long enough for a browser cold start on a slow device, short enough that a leaked URL is dead on arrival.
- **Redis-backed** (ElastiCache is already in the stack), keyed `webhandoff:{token}` → `user_id`, TTL as the expiry. Deletion on redeem gives single-use for free.
- **Bound to `user_id` only.** Do not bind to device, IP, or UA — the redeeming client is a *different* client by design.
- **Rate limit the issue endpoint** per user.

### Redeem

```
POST /api/auth/web-handoff/redeem
{ "token": "<opaque>" }
→ 200  { success, user, token, refreshToken }  + BOTH httpOnly cookies — see §10
→ 401  invalid, expired, or already used — indistinguishable by design
```

Redeem is **unauthenticated** (the browser has no session — that is the entire point) and must be rate limited by IP.

**⚠️ `POST /auth/login` IS THE WRONG PRECEDENT. DO NOT COPY IT.** It exists (`auth.routes.ts:162`) and it is tempting because of the name. But **tagme-now's user flow never calls it** — the web client's only `/auth/*` calls are `send-otp` (`api.ts:744`), `verify-otp` (`:762`), `refresh` (`:261`), `logout` (`:803`). Modelling redeem on `login` would produce a response the SPA's session layer does not consume.

**The precedent is `verify-otp` (`auth.routes.ts:539`)** — it is what actually establishes a web user session. §10 has its exact shape and side effects. The same warning applies to `AdminAuthContext.tsx:73`, `PartnerPortalLogin.tsx:64` and `PartnerLogin.tsx:73`: those are the admin/partner/coop portals, token-only, and not the user flow.

*(An earlier draft of this section said "same shape as login". That was wrong twice over — there is no user password login on the web, and the session is not token-only.)*

## 5. Client behaviour — the part that must be right first time

```
1. POST /api/auth/web-handoff  { destination: "choose_plan" }
2. 200 → open response.url in the external browser
3. ANY failure → open the hardcoded fallback URL
```

**Failure means anything that isn't a 200 with a parseable `url`:** non-200, timeout, malformed body, network error.

**Timeout budget: 3s.** Past that, fall back. A user waiting on a spinner is worse than a user logging in again.

**The fallback must never be worse than today's behaviour** — that is what makes shipping the client before the server safe. Until U1 is deployed, every call 404s and every user gets exactly the current flow.

**The fallback URL needs BOTH fixes — environment host AND market pin.**

- **Host.** ⚠ **Corrected 2026-08-01: "Android's is done" is true of the BRANCH and false of the FIELD.** The `WEB_BASE_URL` fix landed in `2635a62` (vc23), which was **never fielded**. The fielded build is `8260097` (vc22, tag `release/2.2.1-vc22`), where `WEB_BASE_URL` does not exist and the CTA hardcodes `https://senra.pet` at `PetSetupWizardScreen.kt:147`. **So BOTH clients are unconditionally prod in the field today.** iOS `4756295` (tag `release/2.2.1-build5`) has no build-type override at all — `WebURLHelper.swift:28`. On both platforms this is a **prerequisite for testing U4 at all**: a staging build's CTA cross-wires to prod and the handoff cannot be exercised in any safe environment. Do not plan U3 as "Android already has the host" — it does not.
- **Market.** The fallback must be `{env-host}/hu/choose-plan`, hardcoded. **BANNED IN BOTH CLIENTS' FALLBACKS: any device-region signal, on either platform, in any form.** Concretely, the fallback must not read `Locale.current.region` (iOS), `Locale.getDefault().country` (Android), or route through `WebURLHelper.countryCode` / `WebUrlHelper.countryCode`, which are exactly those calls wrapped in a helper. The `/hu/` segment is a **literal**, not a lookup.

  **⚠️ THE PERMITTED LANGUAGE CALL, NAMED — because it is one word from the banned one.** Now that
  §9.4 rules v1 **sends** `locale_hint`, U3/U4 must read a *language*, and the only calls allowed for
  that are **`Locale.current.language` (iOS)** and **`Locale.getDefault().language` (Android)**.
  Read them for `locale_hint` and **for nothing else**. The distinction is a single word —
  `.language` is permitted, `.region` / `.country` are banned — so a reviewer scanning for
  `Locale.current.` will see both and must check which member is being read. **`region`/`country`
  anywhere in the URL-building path is the `/uk/` bug; `language` feeding `locale_hint` is the fix.**
  Neither may reach market resolution: the market is the literal `hu`.

  This is not a style preference — it is the whole defect. Today, **both fielded builds derive the market from device region**: iOS `WebURLHelper.swift:21` and Android `WebUrlHelper.kt:27-31` both end `?? "uk"` / `?: "uk"`, and both CTAs route through them. Production is only saved by a CloudFront Function 301-ing `/uk/* → /hu/*` (`terraform/frontend.tf:93-95`, "UK country removed"). **That redirect is infrastructure, not client correctness** — remove it while region-deriving binaries are fielded and the defect reopens instantly, with no client change.

  The fallback is the path that fires whenever the handoff is unavailable — every launch between submission and U1 reaching prod. Putting a region lookup there rebuilds the bug in the one code path shipped specifically to be safe. **HU-region devices resolve correctly today** (`Locale` region `HU` → `hu`, byte-verified `0x48 0x55`, including `en_HU`), which is precisely why the defect is easy to miss in testing: it only appears on a device whose region is not Hungary.

**Fix the helper, not the call site.** On iOS, `WebURLHelper.url(path:)` has one direct consumer (the interstitial CTA — the only money-path surface) plus seven legal links through its `termsURL`/`privacyURL` wrappers. The helper is **pre-existing and untouched since creation**, so its behaviour is already live in the store build and fixing it changes nothing for the worse. Scoping the fix to the call site would leave a known-wrong helper armed for whoever adds the next web link. Android's equivalent gets the same treatment.

*(Separate, pre-existing, not a release blocker: `RegistrationView` presents terms via that helper, so a non-HU-region device currently links to `senra.pet/uk/terms` at the moment a user agrees. Worth establishing what that URL returns — 404, the same terms in English, or a different UK-market document. Own it as its own item.)*

**After U4, the helper is the fallback path only.** The interstitial no longer builds a URL; it calls the endpoint and opens what comes back. That is precisely why the fallback has to be correct rather than merely present.

## 6. Web behaviour (U2)

1. Route reads `?handoff=`.
2. `POST` it to redeem.
3. On success: establish the session, **`history.replaceState` to strip the param immediately**, render the destination.
4. On failure: render the normal login page. No error detail — an expired token and a forged one look the same.
5. Set `Referrer-Policy: no-referrer` on routes that can carry the param.

## 7. Security notes

A token in a URL is a bearer credential and leaks via browser history, referrer headers, and shared links. The defences are **short TTL, single-use, and immediate stripping** — all three, not any one.

Precedent in this codebase: HMAC-signed opt-out links and SES invite links.

Not in scope, deliberately: device binding (breaks by design), long-lived tokens, encoding user data in the token.

## 8. Frozen once a client ships

| Frozen | Free to change |
|---|---|
| Endpoint path + method | Host |
| Request field names, `destination` values | Country-segment resolution |
| That the response carries `url` | Path per destination |
| Fallback-on-any-failure | Token format, TTL, param name |

Everything in the right column is why the URL is server-built. Keep it that way.

## 9. CLOSED 2026-08-01 — all four resolved

**1. Destination paths — CONFIRMED, two were wrong.** See §2. `manage_subscription` is top-level; `orders` has no route.

**2. Redeem response shape — the draft was WRONG.** tagme-now's session is **hybrid, not token-only**. See §10.

**3. Does `/hu/` fix the language? — YES. They are NOT resolved separately.**
`src/config/countries.ts:18` — `hu: { code: 'hu', …, language: 'hu', … }`
`src/contexts/CountryContext.tsx:33-38` —
```ts
useEffect(() => {
  if (i18n.language !== country.language) i18n.changeLanguage(country.language);
}, [countryCode, country.language, i18n]);
```
The country segment **forces** the language. So a handoff to `/hu/choose-plan` renders **Hungarian copy regardless of the user's device language** — which is precisely the failure this question anticipated: an HU-market customer who reads English is shown a Hungarian page at the moment they are asked to pay.

The `LanguageSwitcher` (`:20`) calls `changeLanguage` directly and will hold **until the next remount**, because the effect's deps (`countryCode`, `country.language`, `i18n`) do not change on a language switch. It is not a durable override.

**⇒ `locale_hint` HAS a job.** It is the only way a handoff can express "HU market, English copy".

**4. Does v1 send `locale_hint`? — YES. RULED 2026-08-02, reversing the earlier "NO".**

v1 **sends** `locale_hint`. The market stays pinned to `hu` as a literal; `locale_hint` is a language
signal only and must never enter market resolution (§3, and the ⚠ above).

**The old evidence line was wrong independently of the old answer, and that is why this needs saying
twice.** It read: *"`locale_hint` appears 0 times in iOS `4756295`, Android `8260097`, backend
`33b59a0`; controls hit."* The zeros were real and the controls did hit — but **none of those three
builds calls this endpoint at all**, so the measurement could never have supported either answer. It
measured the absence of a feature that had not been built. Left standing, a later reader re-derives
the old ruling from evidence that still looks sound.

**Reserving the field alone buys nothing**, which is the reason for the reversal: §8 freezes request
field *names*, so a field reserved-but-never-populated cannot be populated later without the store
cycle the reservation was supposed to avoid. v1 populating it now is what makes the reservation
worth having.

**FREEZE IMPACT: NONE. This does not amend the frozen contract.** §8 freezes the field *name*, and
`locale_hint` is already in the schema — see §3's request body. A client populating a
frozen-in optional field moves nothing in §8's left column: no endpoint path, no method, no field
name, no `destination` value, no response shape. The binding surface is unchanged.

Server behaviour is unchanged too: absence still means "no language preference" and still falls back
to the country's language.


---

## 10. Session establishment — what redeem must actually do

**Added 2026-08-01, replacing §4's "…normal session response, same shape as login". That phrase is wrong
twice over: the web user flow has no password login, and the session is not token-only.**

**There is no user password login on the web.** tagme-now's user auth is OTP-based — the only `/auth/*`
calls in `src/lib/api.ts` @ `a085bf5` are `send-otp` (`:744`), `verify-otp` (`:762`), `refresh` (`:261`),
`logout` (`:803`). The backend *does* expose `POST /auth/login` (`auth.routes.ts:162`) but the web client
never calls it. **The precedent redeem must match is `verify-otp`, not `login`.**

**What `verify-otp` does** (`auth.routes.ts:539`):
```
:656  await authService.storeRefreshToken(user.id, refreshToken, deviceInfo);  // DB side-effect
:659  setAuthCookie(res, token);
:660  setRefreshCookie(res, refreshToken);
:662  res.json({ success: true,
                 user: { id, email, role, first_name, last_name, country, preferred_language },
                 token,        // "Still include token for mobile/API clients"
                 refreshToken,
                 isNewUser });
```

**The body token is a fallback, not a co-equal half.** `api.ts:774-777`:
```ts
// Store token for cross-origin scenarios where cookies may be blocked
if (response.data?.token) localStorage.setItem('auth_token', response.data.token);
```
It is conditional and explicitly scoped to blocked-cookie cases. **Cookies are the primary mechanism.**
Redeem should still return the token so the fallback works, but a redeem that returned *only* a token would
be relying on the backstop.

**Cookie attributes** — the call site is `src/utils/cookies.ts` (NOT `auth.routes.ts`, which imports it).
Browsers ignore later clear/overwrite directives that disagree on `secure`/`sameSite`/`path`, so use
`setAuthCookie()` + `setRefreshCookie()` rather than open-coding `res.cookie`:

| Cookie | httpOnly | secure | sameSite | maxAge | path |
|---|---|---|---|---|---|
| `auth_token` | true | `!env.isDevelopment` | `'none'` when secure, else `'lax'` | 1 h | `/` |
| `refresh_token` | true | **hardcoded `true`** | **`'strict'`** | 30 d | **`/api/auth/refresh`** |

*(The 2026-05-26 audit finding was exactly an attribute drift — `auth_token` missing `Secure` on staging.)*

**⇒ Redeem must: store a refresh token in the DB, set both cookies via the helpers, and return
`{ success, user, token, refreshToken }`.** Do not copy `AdminAuthContext.tsx:73`,
`PartnerPortalLogin.tsx:64` or `PartnerLogin.tsx:73` — those are admin/partner/coop portals, token-only,
and not the user flow.

## 11. The auth-boundary asymmetry — examined 2026-08-01, and it is already handled

`choose-plan` (194), `manage-subscription` (195), `billing` (196) and `order-confirmation` (193) sit
**outside** the `RedesignProtectedRoute` block (opens 204). `account` (205) and 19 others sit inside it.

**This is deliberate, not an oversight.** `CountryRoutes.tsx:189-192`:
> *"Post-Stripe / public-checkout landings. Public routes so they survive the full-page Stripe round-trip;
> each page self-guards on the real auth session via RedesignProtectedRoute primitives where needed."*

**And the guards exist.** Verified per page @ `a085bf5`:

| Page | Guard |
|---|---|
| `redesign7/ChoosePlan.tsx` | `:88` `navigate("/login", { state: { returnTo: "/choose-plan" } })` · `:209` `if (!isAuthenticated) return null` |
| `redesign7/ManageSubscription.tsx` | `:83-84` navigate to `/login` with `returnTo` |
| `redesign7/Billing.tsx` | `:44-45` `navigate("/login", { state: { returnTo: "/billing" } })` |
| `redesign7/Account.tsx` | `:156` `if (!user) return null` (also inside the protected block) |

**So an earlier draft of this section was wrong.** It "ruled" that redeem failure must render login rather
than the destination, and described a logged-out user stranded on the destination. That state cannot occur:
every handoff destination already redirects to `/login` carrying a `returnTo`. §6 step 4 is satisfied by the
pages themselves, not by anything U2 must add.

**The rule that IS needed, and is not currently enforced anywhere:**

> **A destination may only enter the enum if its page self-guards.** Confirm the guard by reading the page,
> not by reading the route table — the route table says these pages are public and it is right.

`order-confirmation` is the live counter-example: it **deliberately does not redirect**
(`redesign7/OrderConfirmation.tsx:110` `if (!sessionId) return null`; `:227` offers `/login` as a *button*,
not a redirect), because it is a post-Stripe landing a guest must be able to see. It is correctly **not** in
the destination enum, and adding it would be a mistake.
